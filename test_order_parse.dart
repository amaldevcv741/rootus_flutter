import 'dart:convert';
import 'package:flutter/material.dart';

void main() {
  final jsonStr = '''
  {
    "id": "u7XmuavRwb7CfU5W9Fdx",
    "userId": "3D2oU0Gg98sC3MwemSUU",
    "totalAmount": 160,
    "deliveryAddress": "Kochi, Kerala, India",
    "deliveryDay": "Tomorrow",
    "orderDate": {"_seconds": 1785900650, "_nanoseconds": 592000000},
    "items": [{"productId": "DGslgX4cAjqExM0Rit3K", "name": "Fresh Oyster Mushrooms", "price": 80, "quantity": 2, "unit": "g", "itemStatus": "Accepted", "rejectionReason": null}],
    "status": "Accepted"
  }
  ''';
  
  final json = jsonDecode(jsonStr);
  
  try {
    final date = json['orderDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['orderDate']['_seconds'] * 1000)
        : DateTime.now();
    print("Parsed date: $date");
    
    final cancelDate = json['cancellationDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['cancellationDate']['_seconds'] * 1000)
        : null;
    print("Parsed cancelDate: $cancelDate");
  } catch (e) {
    print("Error parsing: $e");
  }
}
