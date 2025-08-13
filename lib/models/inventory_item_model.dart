import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final String description; // Changed from 'unit'
  final String? imageUrl;
  final String restaurantId;

  InventoryItem({
    required this.id,
    required this.name,
    required this.description, // Changed from 'unit'
    this.imageUrl,
    required this.restaurantId,
  });

  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '', // Changed from 'unit'
      imageUrl: data['imageUrl'],
      restaurantId: data['restaurantId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description, // Changed from 'unit'
      'imageUrl': imageUrl,
      'restaurantId': restaurantId,
    };
  }
}
