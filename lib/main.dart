import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/providers/theme_provider.dart';
import 'package:resto2/utils/app_theme.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Import App Check
import 'utils/app_router.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v-site-key'),
    androidProvider: AndroidProvider.playIntegrity,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Watch both the saved theme and the preview theme
    final savedThemeMode = ref.watch(themeModeProvider);
    final previewThemeMode = ref.watch(previewThemeModeProvider);

    return MaterialApp.router(
      title: UIStrings.appTitle,
      theme: lightTheme,
      darkTheme: darkTheme,
      // THE FIX: Prioritize the preview theme if it exists, otherwise use the saved theme.
      themeMode: previewThemeMode ?? savedThemeMode,
      routerConfig: router,
    );
  }
}
