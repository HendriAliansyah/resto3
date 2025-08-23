// lib/models/package_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String restaurantId;
  final String courseId;
  final String orderTypeId;
  final List<String> menuItems;
  final List<String> inventoryItems;

  PackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.restaurantId,
    required this.courseId,
    required this.orderTypeId,
    required this.menuItems,
    required this.inventoryItems,
  });

  factory PackageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackageModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      restaurantId: data['restaurantId'] ?? '',
      courseId: data['courseId'] ?? '',
      orderTypeId: data['orderTypeId'] ?? '',
      menuItems: List<String>.from(data['menuItems'] ?? []),
      inventoryItems: List<String>.from(data['inventoryItems'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'restaurantId': restaurantId,
      'courseId': courseId,
      'orderTypeId': orderTypeId,
      'menuItems': menuItems,
      'inventoryItems': inventoryItems,
    };
  }
}
