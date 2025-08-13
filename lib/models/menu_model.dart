import 'package:cloud_firestore/cloud_firestore.dart';

class MenuModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String restaurantId;
  final String courseId;
  final String orderTypeId; // This will link to the OrderType

  MenuModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.restaurantId,
    required this.courseId,
    required this.orderTypeId,
  });

  factory MenuModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      restaurantId: data['restaurantId'] ?? '',
      courseId: data['courseId'] ?? '',
      orderTypeId: data['orderTypeId'] ?? '',
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
    };
  }
}
