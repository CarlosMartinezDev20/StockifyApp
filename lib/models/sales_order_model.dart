class SalesOrderItem {
  final String id;
  final String salesOrderId;
  final String productId;
  final String? productName;
  final double qty;
  final double unitPrice;
  final double? discount;

  SalesOrderItem({
    required this.id,
    required this.salesOrderId,
    required this.productId,
    this.productName,
    required this.qty,
    required this.unitPrice,
    this.discount,
  });

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    return SalesOrderItem(
      id: json['id'] as String,
      salesOrderId: json['salesOrderId'] as String,
      productId: json['productId'] as String,
      productName: json['product']?['name'] as String?,
      qty: double.parse(json['qty'].toString()),
      unitPrice: double.parse(json['unitPrice'].toString()),
      discount: json['discount'] != null
          ? double.parse(json['discount'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'salesOrderId': salesOrderId,
      'productId': productId,
      'productName': productName,
      'qty': qty,
      'unitPrice': unitPrice,
      'discount': discount,
    };
  }

  double get total {
    return (qty * unitPrice) - (discount ?? 0);
  }
}

class SalesOrder {
  final String id;
  final String customerId;
  final String? customerName;
  final String status;
  final List<SalesOrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  SalesOrder({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.status,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customer']?['name'] as String?,
      status: json['status'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => SalesOrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double get total {
    return items.fold<double>(0, (sum, item) => sum + item.total);
  }
}
