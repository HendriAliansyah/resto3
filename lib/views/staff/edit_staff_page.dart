import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/role_permission_model.dart';
import 'package:resto2/models/staff_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/staff_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:resto2/utils/constants.dart';

class EditStaffPage extends HookConsumerWidget {
  final Staff staff;
  const EditStaffPage({super.key, required this.staff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(currentUserProvider).asData?.value;
    final staffController = ref.read(staffControllerProvider);
    final selectedRole = useState(staff.role);
    final isLoading = useState(false);

    final isAdminOwner = adminUser?.role == UserRole.owner;
    final isEditingOwner = staff.role == UserRole.owner;

    // A new condition to check if a non-owner is trying to edit an admin.
    final isManagerEditingAdmin = !isAdminOwner && staff.role == UserRole.admin;

    final List<UserRole> availableRoles;
    if (isEditingOwner) {
      availableRoles = [UserRole.owner];
    } else if (isManagerEditingAdmin) {
      // If a manager is editing an admin, the list must include 'admin' to prevent a crash.
      availableRoles = [UserRole.admin];
    } else {
      availableRoles =
          UserRole.values.where((role) {
            if (role == UserRole.owner) return false;
            if (role == UserRole.admin && !isAdminOwner) return false;
            return true;
          }).toList();
    }

    void handleSaveChanges() async {
      isLoading.value = true;
      try {
        await staffController.updateStaffRole(
          userId: staff.uid,
          newRole: selectedRole.value,
        );
        if (context.mounted) {
          showSnackBar(
            context,
            "${staff.displayName}'s role has been updated.",
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          showSnackBar(context, 'Error: ${e.toString()}', isError: true);
        }
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    void onBlockToggle() {
      final newStatus = !staff.isDisabled;
      final action = newStatus ? 'block' : 'unblock';
      staffController.setUserDisabledStatus(
        userId: staff.uid,
        isDisabled: newStatus,
      );
      showSnackBar(context, '${staff.displayName} has been ${action}ed.');
      context.pop();
    }

    // Determine if the form fields should be disabled.
    final bool isFormDisabled = isEditingOwner || isManagerEditingAdmin;
    String? hintText;
    if (isEditingOwner) {
      hintText = UIStrings.roleUnchanged;
    } else if (isManagerEditingAdmin) {
      hintText = UIStrings.adminRoleUnchanged;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          UIStrings.editStaffTitle.replaceFirst('{name}', staff.displayName),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                UIStrings.name.replaceFirst('{name}', staff.displayName),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                UIStrings.email.replaceFirst('{email}', staff.email),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<UserRole>(
                value: selectedRole.value,
                onChanged:
                    isFormDisabled // Disable the dropdown if conditions are met
                        ? null
                        : (value) {
                          if (value != null) selectedRole.value = value;
                        },
                items:
                    availableRoles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.name),
                          ),
                        )
                        .toList(),
                decoration: InputDecoration(
                  labelText: UIStrings.assignRole,
                  border: const OutlineInputBorder(),
                  disabledBorder:
                      isFormDisabled ? const OutlineInputBorder() : null,
                  filled: isFormDisabled,
                  fillColor: isFormDisabled ? Colors.grey.withAlpha(51) : null,
                ),
              ),
              if (hintText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    hintText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 32),
              if (isLoading.value)
                const LoadingIndicator()
              else
                ElevatedButton(
                  onPressed: isFormDisabled ? null : handleSaveChanges,
                  child: const Text(UIStrings.saveChanges),
                ),
              const Spacer(),
              if (!isEditingOwner) // An owner cannot block themselves
                ElevatedButton(
                  onPressed: onBlockToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        staff.isDisabled ? Colors.green : Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    staff.isDisabled
                        ? UIStrings.unblockUser
                        : UIStrings.blockUser,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
