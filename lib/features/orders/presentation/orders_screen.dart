import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import 'order_detail_screen.dart';
import '../data/order_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  DateTime? _selectedDate;
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'Pending Confirmation', 'Processing', 'Partially Accepted', 'Accepted', 'Rejected', 'Canceled'];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isBottom) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context.read<OrderBloc>().add(FetchMoreOrdersRequested(authState.user.id));
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchOrders() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<OrderBloc>().add(FetchOrdersRequested(authState.user.id));
    }
  }

  Future<void> _fetchOrdersAsync() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final bloc = context.read<OrderBloc>();
      bloc.add(FetchOrdersRequested(authState.user.id));
      await Future.any([
        bloc.stream.firstWhere((state) => state is OrderLoaded || state is OrderError),
        Future.delayed(const Duration(seconds: 2)),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.9),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          _buildStatusChips(),
          Expanded(
            child: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrderLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                } else if (state is OrderError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)),
                        TextButton(onPressed: _fetchOrders, child: const Text('Retry')),
                      ],
                    ),
                  );
                } else if (state is OrderLoaded) {
                  List<OrderModel> filteredOrders = state.orders;
                  
                  if (_selectedDate != null) {
                    filteredOrders = state.orders.where((o) {
                      return o.orderDate.year == _selectedDate!.year &&
                             o.orderDate.month == _selectedDate!.month &&
                             o.orderDate.day == _selectedDate!.day;
                    }).toList();
                  }

                  if (_selectedStatus != 'All') {
                    filteredOrders = filteredOrders.where((o) => o.status == _selectedStatus).toList();
                  }

                  if (filteredOrders.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _fetchOrdersAsync,
                      color: AppColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 200),
                          Center(child: Text('No orders found.', style: TextStyle(color: Color(0xFF94A3B8)))),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _fetchOrdersAsync,
                    color: AppColors.primary,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredOrders.length + (state.hasReachedMax ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index >= filteredOrders.length) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                        }
                        final order = filteredOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _fetchOrdersAsync,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('No orders yet', style: TextStyle(color: Color(0xFF94A3B8)))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('All Time', null),
          const SizedBox(width: 8),
          _buildChip('Today', DateTime.now()),
          const SizedBox(width: 8),
          _buildChip('Yesterday', DateTime.now().subtract(const Duration(days: 1))),
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Select Date', style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF334155),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: Color(0xFF1E293B),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          )
        ],
      ),
    );
  }

  Widget _buildChip(String label, DateTime? date) {
    bool isSelected = false;
    if (_selectedDate == null && date == null) {
      isSelected = true;
    } else if (_selectedDate != null && date != null) {
      isSelected = _selectedDate!.year == date.year &&
                   _selectedDate!.month == date.month &&
                   _selectedDate!.day == date.day;
    }

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDate = selected ? date : null;
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : const Color(0xFF334155),
      ),
    );
  }

  Widget _buildStatusChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final isSelected = _selectedStatus == status;
          return ChoiceChip(
            label: Text(status),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedStatus = selected ? status : 'All';
              });
            },
            selectedColor: AppColors.secondary.withValues(alpha: 0.3),
            backgroundColor: const Color(0xFF1E293B),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.secondary : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.secondary : const Color(0xFF334155),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor = const Color(0xFFF59E0B); // Pending
    if (order.status == 'Completed' || order.status == 'Accepted' || order.status == 'Partially Accepted' || order.status == 'Delivered') statusColor = const Color(0xFF21AC7A); // Success
    if (order.status == 'Rejected' || order.status == 'Canceled') statusColor = const Color(0xFFEF4444); // Danger

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(height: 12),
              Text(
                DateFormat('dd MMM yyyy').format(order.orderDate),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} Items',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.secondary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
