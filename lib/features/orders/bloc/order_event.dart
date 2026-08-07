import 'package:equatable/equatable.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class PlaceOrderRequested extends OrderEvent {
  final String userId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String deliveryAddress;
  final String deliveryDay;

  const PlaceOrderRequested({
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.deliveryDay,
  });

  @override
  List<Object?> get props => [userId, items, totalAmount, deliveryAddress, deliveryDay];
}

class FetchOrdersRequested extends OrderEvent {
  final String userId;
  const FetchOrdersRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CancelOrderRequested extends OrderEvent {
  final String orderId;
  final String userId;
  final String reason;

  const CancelOrderRequested({
    required this.orderId,
    required this.userId,
    required this.reason,
  });

  @override
  List<Object?> get props => [orderId, userId, reason];
}
