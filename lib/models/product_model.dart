class Product {
  final String id;
  final String sku;
  final String name;
  final String? description;
  final String categoryId;
  final String? categoryName;
  final String unit;
  final double? minStock;
  final String? barcode;
  final double? stockTotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    this.description,
    required this.categoryId,
    this.categoryName,
    required this.unit,
    this.minStock,
    this.barcode,
    this.stockTotal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Calcular stock total desde inventoryLevels si está presente
    double? calculatedStock;
    if (json['inventoryLevels'] != null) {
      final levels = json['inventoryLevels'] as List<dynamic>;
      calculatedStock = levels.fold<double>(
        0,
        (sum, level) => sum + double.parse(level['quantity'].toString()),
      );
    }

    return Product(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String,
      categoryName: json['category']?['name'] as String?,
      unit: json['unit'] as String? ?? 'EA',
      minStock: json['minStock'] != null
          ? double.tryParse(json['minStock'].toString())
          : null,
      barcode: json['barcode'] as String?,
      stockTotal: calculatedStock ??
          (json['stockTotal'] != null
              ? double.tryParse(json['stockTotal'].toString())
              : null),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'unit': unit,
      'minStock': minStock,
      'barcode': barcode,
      'stockTotal': stockTotal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
