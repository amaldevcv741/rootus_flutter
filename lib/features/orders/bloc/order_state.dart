import 'package:equatable/equatable.dart';
import '../data/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderPlaceLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<OrderModel> orders;
  final bool hasReachedMax;
  final int currentPage;

  const OrderLoaded({
    required this.orders,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  OrderLoaded copyWith({
    List<OrderModel>? orders,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return OrderLoaded(
      orders: orders ?? this.orders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [orders, hasReachedMax, currentPage];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderPlaceSuccess extends OrderState {}

class OrderCancelSuccess extends OrderState {}
