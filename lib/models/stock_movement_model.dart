class StockMovement {
  final String id;
  final String productId;
  final String warehouseId;
  final String type; // IN, OUT, ADJUST
  final double quantity;
  final String? reason;
  final String? refDocument;
  final DateTime createdAt;
  final String? productName;
  final String? warehouseName;

  StockMovement({
    required this.id,
    required this.productId,
    required this.warehouseId,
    required this.type,
    required this.quantity,
    this.reason,
    this.refDocument,
    required this.createdAt,
    this.productName,
    this.warehouseName,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      productId: json['productId'] as String,
      warehouseId: json['warehouseId'] as String,
      type: json['type'] as String,
      quantity: double.parse(json['quantity'].toString()),
      reason: json['reason'] as String?,
      refDocument: json['refDocument'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      productName: json['product']?['name'] as String?,
      warehouseName: json['warehouse']?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'warehouseId': warehouseId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'refDocument': refDocument,
      'createdAt': createdAt.toIso8601String(),
      'productName': productName,
      'warehouseName': warehouseName,
    };
  }

  bool get isIn => type.toUpperCase() == 'IN';
  bool get isOut => type.toUpperCase() == 'OUT';
  bool get isAdjust => type.toUpperCase() == 'ADJUST';
}
