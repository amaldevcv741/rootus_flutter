import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_event.dart';
import 'order_state.dart';
import '../data/order_repository.dart';
import '../../../../core/network/error_handler.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repository;

  OrderBloc(this._repository) : super(OrderInitial()) {
    on<PlaceOrderRequested>(_onPlaceOrderRequested);
    on<FetchOrdersRequested>(_onFetchOrdersRequested);
    on<FetchMoreOrdersRequested>(_onFetchMoreOrdersRequested);
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
      emit(OrderError(ErrorHandler.clean(e)));
    }
  }

  Future<void> _onFetchOrdersRequested(
      FetchOrdersRequested event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final orders = await _repository.fetchUserOrders(event.userId, page: 1, limit: 10);
      emit(OrderLoaded(
        orders: orders,
        hasReachedMax: orders.length < 10,
        currentPage: 1,
      ));
    } catch (e) {
      emit(OrderError(ErrorHandler.clean(e)));
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
      final orders = await _repository.fetchUserOrders(event.userId, page: 1, limit: 10);
      emit(OrderLoaded(
        orders: orders,
        hasReachedMax: orders.length < 10,
        currentPage: 1,
      ));
    } catch (e) {
      emit(OrderError(ErrorHandler.clean(e)));
    }
  }

  Future<void> _onFetchMoreOrdersRequested(
      FetchMoreOrdersRequested event, Emitter<OrderState> emit) async {
    if (state is OrderLoaded) {
      final currentState = state as OrderLoaded;
      if (currentState.hasReachedMax) return;

      try {
        final nextPage = currentState.currentPage + 1;
        final orders = await _repository.fetchUserOrders(event.userId, page: nextPage, limit: 10);
        
        if (orders.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(currentState.copyWith(
            orders: List.of(currentState.orders)..addAll(orders),
            hasReachedMax: orders.length < 10,
            currentPage: nextPage,
          ));
        }
      } catch (e) {
        emit(OrderError(ErrorHandler.clean(e)));
      }
    }
  }
}
