class InventoryLevel {
  final String id;
  final String productId;
  final String warehouseId;
  final String? productName;
  final String? warehouseName;
  final double quantity;

  InventoryLevel({
    required this.id,
    required this.productId,
    required this.warehouseId,
    this.productName,
    this.warehouseName,
    required this.quantity,
  });

  factory InventoryLevel.fromJson(Map<String, dynamic> json) {
    return InventoryLevel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      warehouseId: json['warehouseId'] as String,
      productName: json['product']?['name'] as String?,
      warehouseName: json['warehouse']?['name'] as String?,
      quantity: double.parse(json['quantity'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'warehouseId': warehouseId,
      'productName': productName,
      'warehouseName': warehouseName,
      'quantity': quantity,
    };
  }
}
