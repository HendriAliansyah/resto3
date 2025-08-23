// lib/providers/package_provider.dart

import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/package_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/storage_provider.dart';
import 'package:resto2/services/package_service.dart';

enum PackageActionStatus { initial, loading, success, error }

class PackageState {
  final PackageActionStatus status;
  final String? errorMessage;
  PackageState({this.status = PackageActionStatus.initial, this.errorMessage});
}

final packageServiceProvider = Provider((ref) => PackageService());

final packagesStreamProvider = StreamProvider.autoDispose<List<PackageModel>>((
  ref,
) {
  final restaurantId =
      ref.watch(currentUserProvider).asData?.value?.restaurantId;
  if (restaurantId != null) {
    return ref.watch(packageServiceProvider).getPackagesStream(restaurantId);
  }
  return Stream.value([]);
});

final packageControllerProvider =
    StateNotifierProvider.autoDispose<PackageController, PackageState>((ref) {
      return PackageController(ref);
    });

class PackageController extends StateNotifier<PackageState> {
  final Ref _ref;
  PackageController(this._ref) : super(PackageState());

  Future<void> addPackage({
    required String name,
    required String description,
    required double price,
    required String courseId,
    required String orderTypeId,
    required List<String> menuItems,
    required List<String> inventoryItems,
    File? imageFile,
  }) async {
    state = PackageState(status: PackageActionStatus.loading);
    final restaurantId =
        _ref.read(currentUserProvider).asData?.value?.restaurantId;
    if (restaurantId == null) {
      state = PackageState(
        status: PackageActionStatus.error,
        errorMessage: 'User not in a restaurant.',
      );
      return;
    }
    try {
      final newItem = PackageModel(
        id: '',
        name: name,
        description: description,
        price: price,
        restaurantId: restaurantId,
        courseId: courseId,
        orderTypeId: orderTypeId,
        menuItems: menuItems,
        inventoryItems: inventoryItems,
      );

      final docRef = await _ref
          .read(packageServiceProvider)
          .addPackage(newItem.toJson());

      if (imageFile != null) {
        final imageUrl = await _ref
            .read(storageServiceProvider)
            .uploadImage('packages/${docRef.id}/image.jpg', imageFile);
        await _ref.read(packageServiceProvider).updatePackage(docRef.id, {
          'imageUrl': imageUrl,
        });
      }
      state = PackageState(status: PackageActionStatus.success);
    } catch (e) {
      state = PackageState(
        status: PackageActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updatePackage({
    required String id,
    required String name,
    required String description,
    required double price,
    required String courseId,
    required String orderTypeId,
    required List<String> menuItems,
    required List<String> inventoryItems,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    state = PackageState(status: PackageActionStatus.loading);
    try {
      String? finalImageUrl = existingImageUrl;
      if (imageFile != null) {
        finalImageUrl = await _ref
            .read(storageServiceProvider)
            .uploadImage('packages/$id/image.jpg', imageFile);
      }
      final updatedData = {
        'name': name,
        'description': description,
        'price': price,
        'courseId': courseId,
        'orderTypeId': orderTypeId,
        'imageUrl': finalImageUrl,
        'menuItems': menuItems,
        'inventoryItems': inventoryItems,
      };

      await _ref.read(packageServiceProvider).updatePackage(id, updatedData);
      state = PackageState(status: PackageActionStatus.success);
    } catch (e) {
      state = PackageState(
        status: PackageActionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deletePackage(String id) async {
    try {
      await _ref.read(packageServiceProvider).deletePackage(id);
      await _ref
          .read(storageServiceProvider)
          .deleteImage('packages/$id/image.jpg');
    } catch (e) {
      // Errors can be handled more granularly if needed
    }
  }
}
