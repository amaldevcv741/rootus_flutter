import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import 'product_model.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<ProductModel>> getProducts({int page = 1, int limit = 10}) async {
    debugPrint('🍄 [PRODUCT REPO] Fetching products from GET /api/products?page=$page&limit=$limit...');
    try {
      final response = await _apiClient.dio.get('/api/products?page=$page&limit=$limit');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> productsJson =
            data is List ? data : (data['data'] ?? []);
        final products =
            productsJson.map((json) => ProductModel.fromJson(json)).toList();
        debugPrint(
            '✅ [PRODUCT REPO] Successfully fetched ${products.length} products.');
        return products;
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      debugPrint('❌ [PRODUCT REPO] Error fetching products: $e');
      throw Exception('Error fetching products: $e');
    }
  }
}
