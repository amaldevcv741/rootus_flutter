class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String unit;
  final String itemStatus; // Pending, Accepted, Rejected
  final String? rejectionReason;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.itemStatus,
    this.rejectionReason,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      unit: json['unit'] ?? '',
      itemStatus: json['itemStatus'] ?? 'Pending',
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'itemStatus': itemStatus,
      'rejectionReason': rejectionReason,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String deliveryAddress;
  final String deliveryDay;
  final String status; // Pending Confirmation, Processing, Completed, Rejected, Canceled
  final DateTime orderDate;
  final String? cancellationReason;
  final DateTime? cancellationDate;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.deliveryDay,
    required this.status,
    required this.orderDate,
    this.cancellationReason,
    this.cancellationDate,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: json['deliveryAddress'] ?? '',
      deliveryDay: json['deliveryDay'] ?? '',
      status: json['status'] ?? 'Pending',
      orderDate: json['orderDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['orderDate']['_seconds'] * 1000)
        : DateTime.now(),
      cancellationReason: json['cancellationReason'],
      cancellationDate: json['cancellationDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['cancellationDate']['_seconds'] * 1000)
        : null,
    );
  }
}
