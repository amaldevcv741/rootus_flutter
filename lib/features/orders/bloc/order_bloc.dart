import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_event.dart';
import 'order_state.dart';
import '../data/order_repository.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repository;

  OrderBloc(this._repository) : super(OrderInitial()) {
    on<PlaceOrderRequested>(_onPlaceOrderRequested);
    on<FetchOrdersRequested>(_onFetchOrdersRequested);
    on<CancelOrderRequested>(_onCancelOrderRequested);
  }

  Future<void> _onPlaceOrderRequested(
      PlaceOrderRequested event, Emitter<OrderState> emit) async {
    emit(OrderPlaceLoading());
    try {
      await _repository.placeOrder(
        userId: event.userId,
        items: event.items,
        totalAmount: event.totalAmount,
        deliveryAddress: event.deliveryAddress,
        deliveryDay: event.deliveryDay,
      );
      emit(OrderPlaceSuccess());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onFetchOrdersRequested(
      FetchOrdersRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final orders = await _repository.fetchUserOrders(event.userId);
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onCancelOrderRequested(
      CancelOrderRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      await _repository.cancelOrder(
        orderId: event.orderId,
        userId: event.userId,
        cancellationReason: event.reason,
      );
      emit(OrderCancelSuccess());
      
      // Auto re-fetch orders after successful cancel
      final orders = await _repository.fetchUserOrders(event.userId);
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}
