import 'dart:ui';

class ProductModel {
  final String id;
  final String name;
  final String category;
  final String? supplier;
  final int initialStock;
  final int lowStockThreshold;
  int currentStock;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    this.supplier,
    this.initialStock = 0,
    this.lowStockThreshold = 10,
    this.currentStock = 0,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int extractStock() {
      final cs = json['current_stock'];
      if (cs is Map) {
        return (cs['current_stock'] as num?)?.toInt() ?? 0;
      } else if (cs is num) {
        return cs.toInt();
      }
      return 0;
    }

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sans nom',
      category: json['category']?.toString() ?? 'Autre',
      supplier: json['supplier']?.toString(),
      initialStock: (json['initial_stock'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 10,
      currentStock: extractStock(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'supplier': supplier,
    'initial_stock': initialStock,
    'low_stock_threshold': lowStockThreshold,
    'current_stock': currentStock,
    'created_at': createdAt.toIso8601String(),
  };

  ProductModel copyWith({
    String? id,
    String? name,
    String? category,
    String? supplier,
    int? initialStock,
    int? lowStockThreshold,
    int? currentStock,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      supplier: supplier ?? this.supplier,
      initialStock: initialStock ?? this.initialStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      currentStock: currentStock ?? this.currentStock,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Extensions utilitaires
extension ProductModelX on ProductModel {
  bool get isLowStock => currentStock <= lowStockThreshold && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  bool get isOkStock => currentStock > lowStockThreshold;

  String get stockStatus {
    if (isOutOfStock) return 'Rupture';
    if (isLowStock) return 'Stock Bas';
    return 'OK';
  }

  Color get stockColor {
    if (isOutOfStock) return const Color(0xFFE53935); // Rouge
    if (isLowStock) return const Color(0xFFFB8C00); // Orange
    return const Color(0xFF43A047); // Vert
  }
}
