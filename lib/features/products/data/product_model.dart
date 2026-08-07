import '../../../../core/network/api_client.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? quantity;
  final String unit;
  final List<String> imageUrls;
  final bool isActive;
  final int stockCount;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.quantity,
    required this.unit,
    required this.imageUrls,
    required this.isActive,
    required this.stockCount,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      quantity: json['quantity'] != null ? double.tryParse(json['quantity'].toString()) : null,
      unit: json['unit'] ?? '',
      imageUrls: _parseImageUrls(json),
      isActive: json['isActive'] ?? true,
      stockCount: int.tryParse(json['stockCount']?.toString() ?? '0') ?? 0,
    );
  }

  static List<String> _parseImageUrls(Map<String, dynamic> json) {
    List<String> rawUrls = [];
    if (json['imageUrls'] != null) {
      rawUrls = List<String>.from(json['imageUrls']);
    } else if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      rawUrls = [json['imageUrl']];
    }
    
    return rawUrls.map((url) {
      if (url.startsWith('/')) {
        return '${ApiClient.baseUrl}$url';
      }
      return url;
    }).toList();
  }
}
