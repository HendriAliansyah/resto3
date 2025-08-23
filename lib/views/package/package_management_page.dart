// lib/views/package/package_management_page.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/package_model.dart';
import 'package:resto2/providers/package_provider.dart';
import 'package:resto2/views/package/widgets/package_bottom_sheet.dart';
import 'package:resto2/views/widgets/app_drawer.dart';

class PackageManagementPage extends ConsumerWidget {
  const PackageManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesStreamProvider);

    void showPackageSheet({PackageModel? package}) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true, // This is the fix
        builder: (_) => PackageBottomSheet(package: package),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Package Master')),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: packagesAsync.when(
          data: (packages) {
            if (packages.isEmpty) {
              return const Center(child: Text('No packages found.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: packages.length,
              itemBuilder: (_, index) {
                final package = packages[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: ListTile(
                    onTap: () => showPackageSheet(package: package),
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child:
                            package.imageUrl != null
                                ? Image.network(
                                  package.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.inventory),
                                ),
                      ),
                    ),
                    title: Text(
                      package.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      package.description,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '\$${package.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text(e.toString())),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showPackageSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
