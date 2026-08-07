import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../data/order_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/app_dialogs.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    Color statusColor = const Color(0xFFF59E0B);
    if (order.status == 'Completed' || order.status == 'Accepted' || order.status == 'Partially Accepted' || order.status == 'Delivered') statusColor = const Color(0xFF21AC7A);
    if (order.status == 'Rejected' || order.status == 'Canceled') statusColor = const Color(0xFFEF4444);

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderCancelSuccess) {
          AppDialogs.showSuccessToast(context, 'Order canceled successfully.');
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              Navigator.of(context).pop(); // Go back to orders list
            }
          });
        } else if (state is OrderError) {
          AppDialogs.showErrorToast(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Details', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.9),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(statusColor),
              const SizedBox(height: 24),
              const Text(
                'Items Ordered',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...order.items.map((item) => _buildItemCard(item)),
            ],
          ),
        ),
        bottomNavigationBar: order.status == 'Pending Confirmation'
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _showCancelDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            : null,
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for cancellation (mandatory):', style: TextStyle(color: Color(0xFF94A3B8))),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Reason...',
                hintStyle: const TextStyle(color: Color(0xFF475569)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                AppDialogs.showErrorToast(ctx, 'Reason is mandatory');
                return;
              }
              Navigator.pop(ctx);
              context.read<OrderBloc>().add(CancelOrderRequested(
                orderId: order.id,
                userId: order.userId,
                reason: reasonController.text.trim(),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Date', DateFormat('dd MMM yyyy').format(order.orderDate)),
          const SizedBox(height: 12),
          _buildInfoRow('Delivery Day', order.deliveryDay),
          const SizedBox(height: 12),
          _buildInfoRow('Total Amount', '₹${order.totalAmount.toStringAsFixed(2)}', valueColor: AppColors.secondary),
          const SizedBox(height: 12),
          _buildInfoRow('Delivery Address', order.deliveryAddress),
          if (order.status == 'Canceled' && order.cancellationReason != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Cancel Reason', order.cancellationReason!, valueColor: const Color(0xFFEF4444)),
          ],
          if (order.status == 'Canceled' && order.cancellationDate != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Cancel Date', DateFormat('dd MMM yyyy - hh:mm a').format(order.cancellationDate!)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: valueColor ?? Colors.white, fontSize: 14, fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(OrderItem item) {
    Color itemStatusColor = const Color(0xFFF59E0B); // Pending
    if (item.itemStatus == 'Accepted') itemStatusColor = const Color(0xFF21AC7A); // Success
    if (item.itemStatus == 'Rejected') itemStatusColor = const Color(0xFFEF4444); // Danger

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: itemStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.itemStatus,
                  style: TextStyle(color: itemStatusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${item.quantity} x ₹${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${(item.quantity * item.price).toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (item.itemStatus == 'Rejected' && item.rejectionReason != null && item.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rejection Reason: ${item.rejectionReason}',
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
