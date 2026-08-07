import 'package:equatable/equatable.dart';
import '../data/cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;

  const CartState({this.items = const []});

  double get totalPrice {
    return items.fold(0.0, (total, item) => total + (item.product.price * item.quantity));
  }

  int get totalItems {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  CartState copyWith({
    List<CartItem>? items,
  }) {
    return CartState(
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        items.map((e) => '${e.product.id}-${e.quantity}').toList(),
      ];
}
