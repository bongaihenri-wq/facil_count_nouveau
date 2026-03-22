import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
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

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

extension ProductModelX on ProductModel {
  bool get isLowStock => currentStock <= lowStockThreshold;
  bool get isOutOfStock => currentStock <= 0;
  String get stockStatus =>
      isOutOfStock ? 'Rupture' : (isLowStock ? 'Bas' : 'OK');
}
