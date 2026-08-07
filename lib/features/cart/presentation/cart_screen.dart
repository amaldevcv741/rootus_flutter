import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../../orders/bloc/order_bloc.dart';
import '../../orders/bloc/order_event.dart';
import '../../orders/bloc/order_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/logout_button.dart';
import '../../../core/presentation/widgets/app_dialogs.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderPlaceLoading) {
          showDialog(
            context: context, 
            barrierDismissible: false, 
            builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary))
          );
        } else if (state is OrderPlaceSuccess) {
          Navigator.pop(context); // close loading
          context.read<CartBloc>().add(ClearCart());
          AppDialogs.showSuccessToast(context, 'Order placed successfully!');
        } else if (state is OrderError) {
          Navigator.pop(context); // close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to place order: ${state.message}'), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.9),
        elevation: 0,
        actions: const [
          LogoutButton(),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: const Color(0xFF94A3B8).withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 18)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final product = item.product;
                    
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product.imageUrls.isNotEmpty
                                ? Image.network(
                                    product.imageUrls.first,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                                  )
                                : _buildImagePlaceholder(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${product.price.toStringAsFixed(2)} / ${product.unit}',
                                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  context.read<CartBloc>().add(UpdateQuantity(productId: product.id, quantity: item.quantity - 1));
                                },
                              ),
                              Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                onPressed: item.quantity >= product.stockCount
                                    ? null
                                    : () {
                                        context.read<CartBloc>().add(UpdateQuantity(productId: product.id, quantity: item.quantity + 1));
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Items:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
                          Text('${state.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Price:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
                          Text('₹${state.totalPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.secondary, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            _showCheckoutBottomSheet(context, state);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Proceed to Checkout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ));
  }

  void _showCheckoutBottomSheet(BuildContext context, CartState cartState) {
    String selectedDay = 'Tomorrow';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Delivery Day', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildRadioOption('Tomorrow', selectedDay, (val) => setModalState(() => selectedDay = val!)),
                  _buildRadioOption('Day after tomorrow', selectedDay, (val) => setModalState(() => selectedDay = val!)),
                  _buildRadioOption('Both', selectedDay, (val) => setModalState(() => selectedDay = val!)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your order will be confirmed if the seller accepts.',
                            style: TextStyle(color: AppColors.primary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _placeOrder(context, cartState, selectedDay);
                      },
                      child: const Text('Confirm Order', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption(String title, String groupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: title,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _placeOrder(BuildContext context, CartState cartState, String deliveryDay) {
    final authState = context.read<AuthBloc>().state;
    String userId = 'guest_user';
    String address = 'N/A';

    if (authState is Authenticated) {
      userId = authState.user.id;
      address = authState.user.address ?? 'N/A';
    }

    final items = cartState.items.map((cartItem) {
      return {
        'productId': cartItem.product.id,
        'name': cartItem.product.name,
        'price': cartItem.product.price,
        'quantity': cartItem.quantity,
        'unit': cartItem.product.unit,
      };
    }).toList();

    context.read<OrderBloc>().add(PlaceOrderRequested(
      userId: userId,
      items: items,
      totalAmount: cartState.totalPrice,
      deliveryAddress: address,
      deliveryDay: deliveryDay,
    ));
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: const Color(0xFF0F172A),
      child: const Center(child: Text('🍄', style: TextStyle(fontSize: 30))),
    );
  }
}
