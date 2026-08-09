import 'package:dio/dio.dart';
import 'order_model.dart';
import '../../../core/network/api_client.dart';

class OrderRepository {
  final Dio _dio = ApiClient().dio;

  Future<void> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryAddress,
    required String deliveryDay,
  }) async {
    try {
      final response = await _dio.post('/api/orders', data: {
        'userId': userId,
        'items': items,
        'totalAmount': totalAmount,
        'deliveryAddress': deliveryAddress,
        'deliveryDay': deliveryDay,
      });

      if (response.statusCode != 201) {
        throw Exception(response.data['error'] ?? 'Failed to place order');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? e.message);
      }
      throw Exception(e.toString());
    }
  }

  Future<List<OrderModel>> fetchUserOrders(String userId, {int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get('/api/orders/user/$userId?page=$page&limit=$limit');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? e.message);
      }
      throw Exception(e.toString());
    }
  }

  Future<void> cancelOrder({
    required String orderId,
    required String userId,
    required String cancellationReason,
  }) async {
    try {
      final response = await _dio.put('/api/orders/$orderId/cancel', data: {
        'userId': userId,
        'cancellationReason': cancellationReason,
      });

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? e.message);
      }
      throw Exception(e.toString());
    }
  }
}
