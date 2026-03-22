// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String,
  supplier: json['supplier'] as String?,
  initialStock: (json['initialStock'] as num?)?.toInt() ?? 0,
  lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 10,
  currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'supplier': instance.supplier,
      'initialStock': instance.initialStock,
      'lowStockThreshold': instance.lowStockThreshold,
      'currentStock': instance.currentStock,
      'createdAt': instance.createdAt.toIso8601String(),
    };
