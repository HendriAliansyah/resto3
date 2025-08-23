import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/table_model.dart';
import 'package:resto2/providers/table_filter_provider.dart';
import 'package:resto2/providers/table_provider.dart';
import 'package:resto2/providers/table_type_provider.dart';
import 'package:resto2/views/table/widgets/table_dialog.dart';
import 'package:resto2/views/widgets/app_drawer.dart';
import 'package:resto2/views/widgets/filter_expansion_tile.dart';
import 'package:resto2/views/widgets/sort_order_toggle.dart'; // Import this

class TableManagementPage extends ConsumerWidget {
  const TableManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesStreamProvider);
    final tableTypesAsync = ref.watch(tableTypesStreamProvider);
    final sortedTables = ref.watch(
      sortedTablesProvider,
    ); // Watch the new provider
    final filterState = ref.watch(tableFilterProvider);

    void showTableDialog({TableModel? table}) {
      showDialog(context: context, builder: (_) => TableDialog(table: table));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Table Master')),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            tableTypesAsync.when(
              data:
                  (tableTypes) => FilterExpansionTile(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search by Name',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged:
                            (value) => ref
                                .read(tableFilterProvider.notifier)
                                .setSearchQuery(value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: filterState.tableTypeId,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...tableTypes.map(
                            (type) => DropdownMenuItem(
                              value: type.id,
                              child: Text(type.name),
                            ),
                          ),
                        ],
                        onChanged:
                            (typeId) => ref
                                .read(tableFilterProvider.notifier)
                                .setTableTypeFilter(typeId),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dropdown for sorting criteria
                          DropdownButton<TableSortOption>(
                            value: filterState.sortOption,
                            items: const [
                              DropdownMenuItem(
                                value: TableSortOption.byName,
                                child: Text('Sort by Name'),
                              ),
                              DropdownMenuItem(
                                value: TableSortOption.byCapacity,
                                child: Text('Sort by Capacity'),
                              ),
                            ],
                            onChanged: (option) {
                              if (option != null) {
                                ref
                                    .read(tableFilterProvider.notifier)
                                    .setSortOption(option);
                              }
                            },
                          ),
                          // Use the new reusable widget
                          SortOrderToggle(
                            currentOrder: filterState.sortOrder,
                            onOrderChanged: (order) {
                              ref
                                  .read(tableFilterProvider.notifier)
                                  .setSortOrder(order);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            Expanded(
              // THE FIX IS HERE: Nest the .when clauses to handle both streams safely.
              child: tableTypesAsync.when(
                data: (tableTypes) {
                  // Now that we know tableTypes has loaded, we can build the typeMap.
                  final typeMap = {
                    for (var type in tableTypes) type.id: type.name,
                  };

                  // Now we can safely check the tables stream.
                  return tablesAsync.when(
                    data: (_) {
                      // We don't need the direct data, we use sortedTables
                      if (sortedTables.isEmpty) {
                        return const Center(child: Text('No tables found.'));
                      }
                      return ListView.builder(
                        itemCount: sortedTables.length,
                        itemBuilder: (_, index) {
                          final table = sortedTables[index];
                          final typeName =
                              typeMap[table.tableTypeId] ?? 'Unknown Type';
                          return ListTile(
                            title: Text(table.name),
                            subtitle: Text(
                              'Type: $typeName, Capacity: ${table.capacity}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed:
                                      () => showTableDialog(table: table),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed:
                                      () => ref
                                          .read(
                                            tableControllerProvider.notifier,
                                          )
                                          .deleteTable(table.id),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text(e.toString())),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text(e.toString())),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTableDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
