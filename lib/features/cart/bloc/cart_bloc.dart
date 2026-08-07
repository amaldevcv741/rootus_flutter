import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../data/cart_item.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final index = updatedItems.indexWhere((item) => item.product.id == event.product.id);

    if (index >= 0) {
      // Item exists, increase quantity up to stockCount
      final currentItem = updatedItems[index];
      final newQuantity = currentItem.quantity + event.quantity;
      if (newQuantity <= currentItem.product.stockCount) {
        updatedItems[index] = CartItem(
          product: currentItem.product,
          quantity: newQuantity,
        );
      } else {
        // Just max it out
        updatedItems[index] = CartItem(
          product: currentItem.product,
          quantity: currentItem.product.stockCount,
        );
      }
    } else {
      // New item
      final qty = event.quantity <= event.product.stockCount ? event.quantity : event.product.stockCount;
      updatedItems.add(CartItem(product: event.product, quantity: qty));
    }

    emit(state.copyWith(items: updatedItems));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = state.items.where((item) => item.product.id != event.productId).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final index = updatedItems.indexWhere((item) => item.product.id == event.productId);

    if (index >= 0) {
      final currentItem = updatedItems[index];
      if (event.quantity > 0) {
        final qty = event.quantity <= currentItem.product.stockCount ? event.quantity : currentItem.product.stockCount;
        updatedItems[index] = CartItem(
          product: currentItem.product,
          quantity: qty,
        );
      } else {
        updatedItems.removeAt(index);
      }
      emit(state.copyWith(items: updatedItems));
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }
}
