// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleModel _$SaleModelFromJson(Map<String, dynamic> json) => SaleModel(
  id: json['id'] as String,
  productId: json['productId'] as String,
  productName: json['productName'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  amount: (json['amount'] as num).toDouble(),
  customer: json['customer'] as String?,
  saleDate: DateTime.parse(json['saleDate'] as String),
  paid: json['paid'] as bool? ?? true,
  locked: json['locked'] as bool? ?? false,
  photo: json['photo'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SaleModelToJson(SaleModel instance) => <String, dynamic>{
  'id': instance.id,
  'productId': instance.productId,
  'productName': instance.productName,
  'quantity': instance.quantity,
  'amount': instance.amount,
  'customer': instance.customer,
  'saleDate': instance.saleDate.toIso8601String(),
  'paid': instance.paid,
  'locked': instance.locked,
  'photo': instance.photo,
  'createdAt': instance.createdAt.toIso8601String(),
};
