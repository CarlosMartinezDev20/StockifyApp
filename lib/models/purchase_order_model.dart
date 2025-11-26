class PurchaseOrderItem {
  final String id;
  final String purchaseOrderId;
  final String productId;
  final String? productName;
  final double qtyOrdered;
  final double qtyReceived;
  final double unitPrice;

  PurchaseOrderItem({
    required this.id,
    required this.purchaseOrderId,
    required this.productId,
    this.productName,
    required this.qtyOrdered,
    required this.qtyReceived,
    required this.unitPrice,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      id: json['id'] as String,
      purchaseOrderId: json['purchaseOrderId'] as String,
      productId: json['productId'] as String,
      productName: json['product']?['name'] as String?,
      qtyOrdered: double.parse(json['qtyOrdered'].toString()),
      qtyReceived: double.parse(json['qtyReceived'].toString()),
      unitPrice: double.parse(json['unitPrice'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchaseOrderId': purchaseOrderId,
      'productId': productId,
      'productName': productName,
      'qtyOrdered': qtyOrdered,
      'qtyReceived': qtyReceived,
      'unitPrice': unitPrice,
    };
  }

  double get total {
    return qtyOrdered * unitPrice;
  }

  bool get isFullyReceived {
    return qtyReceived >= qtyOrdered;
  }
}

class PurchaseOrder {
  final String id;
  final String supplierId;
  final String? supplierName;
  final String status;
  final DateTime? expectedAt;
  final List<PurchaseOrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    this.supplierName,
    required this.status,
    this.expectedAt,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as String,
      supplierId: json['supplierId'] as String,
      supplierName: json['supplier']?['name'] as String?,
      status: json['status'] as String,
      expectedAt: json['expectedAt'] != null
          ? DateTime.parse(json['expectedAt'] as String)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => PurchaseOrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'status': status,
      'expectedAt': expectedAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double get total {
    return items.fold<double>(0, (sum, item) => sum + item.total);
  }
}
