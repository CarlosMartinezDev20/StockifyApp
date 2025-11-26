class Warehouse {
  final String id;
  final String name;
  final String? location;
  final DateTime createdAt;

  Warehouse({
    required this.id,
    required this.name,
    this.location,
    required this.createdAt,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
