import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/table_model.dart';
import 'package:resto2/models/table_type_model.dart';
import 'package:resto2/providers/table_provider.dart';
import 'package:resto2/providers/table_type_provider.dart';
import 'package:resto2/utils/snackbar.dart';

class TableDialog extends HookConsumerWidget {
  final TableModel? table;
  const TableDialog({super.key, this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = table != null;
    final nameController = useTextEditingController(text: table?.name);
    final capacityController = useTextEditingController(
      text: table?.capacity.toString(),
    );
    final selectedTypeId = useState<String?>(table?.tableTypeId);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading =
        ref.watch(tableControllerProvider).status == TableActionStatus.loading;
    final tableTypesAsync = ref.watch(tableTypesStreamProvider);

    // THE FIX IS HERE: The listener is now inside the dialog.
    ref.listen<TableState>(tableControllerProvider, (prev, next) {
      if (next.status == TableActionStatus.success) {
        // Pop the dialog itself.
        Navigator.of(context).pop();
        showSnackBar(context, 'Table saved successfully!');
      }
      if (next.status == TableActionStatus.error) {
        showSnackBar(
          context,
          next.errorMessage ?? 'An error occurred',
          isError: true,
        );
      }
    });

    void submit() {
      if (formKey.currentState?.validate() ?? false) {
        if (selectedTypeId.value == null) {
          showSnackBar(context, 'Please select a table type.', isError: true);
          return;
        }
        ref
            .read(tableControllerProvider.notifier)
            .addTable(
              name: nameController.text,
              tableTypeId: selectedTypeId.value!,
              capacity: int.parse(capacityController.text),
            );
      }
    }

    void update() {
      if (formKey.currentState?.validate() ?? false) {
        if (selectedTypeId.value == null) return;
        ref
            .read(tableControllerProvider.notifier)
            .updateTable(
              tableId: table!.id,
              name: nameController.text,
              tableTypeId: selectedTypeId.value!,
              capacity: int.parse(capacityController.text),
            );
      }
    }

    return AlertDialog(
      title: Text(isEditing ? 'Edit Table' : 'Add New Table'),
      content: tableTypesAsync.when(
        data: (tableTypes) {
          if (!isEditing &&
              tableTypes.isNotEmpty &&
              selectedTypeId.value == null) {
            selectedTypeId.value = tableTypes.first.id;
          }

          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Table Name / Number',
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTypeId.value,
                  onChanged: (newValue) {
                    selectedTypeId.value = newValue;
                  },
                  items:
                      tableTypes
                          .map(
                            (TableType type) => DropdownMenuItem<String>(
                              value: type.id,
                              child: Text(type.name),
                            ),
                          )
                          .toList(),
                  decoration: const InputDecoration(labelText: 'Table Type'),
                  validator: (v) => v == null ? 'Please select a type' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: capacityController,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Text('Could not load table types.'),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : (isEditing ? update : submit),
          child:
              isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
        ),
      ],
    );
  }
}
