import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/utils/constants.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to both the Firebase Auth state and our custom user profile
    final authState = ref.watch(authStateChangeProvider);
    final appUser = ref.watch(currentUserProvider);

    return authState.when(
      data: (user) {
        // If the user is not logged in via Firebase Auth, go to login
        if (user == null) {
          // We use a post frame callback to ensure the widget tree is built before navigating.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppRoutes.login);
          });
          return const Scaffold(body: LoadingIndicator());
        }

        // If the user IS logged in, now we check our custom user profile
        return appUser.when(
          data: (profile) {
            // If the profile hasn't loaded yet for the logged-in user, keep showing loading.
            if (profile == null) {
              return const Scaffold(body: LoadingIndicator());
            }

            // Once the profile is loaded, make a final, unambiguous decision.
            final hasRole =
                profile.role != null && profile.restaurantId != null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                if (hasRole) {
                  context.go(AppRoutes.home);
                } else {
                  context.go(AppRoutes.onboarding);
                }
              }
            });
            // Show a loading indicator during the brief moment of redirection.
            return const Scaffold(body: LoadingIndicator());
          },
          // While loading the profile, show a loading indicator.
          loading: () => const Scaffold(body: LoadingIndicator()),
          // If there's an error loading the profile, show an error screen.
          error:
              (err, stack) => Scaffold(
                body: Center(child: Text('Error loading profile: $err')),
              ),
        );
      },
      loading: () => const Scaffold(body: LoadingIndicator()),
      error:
          (err, stack) => Scaffold(
            body: Center(child: Text('Error with authentication: $err')),
          ),
    );
  }
}
