import 'package:json_annotation/json_annotation.dart';

part 'sale_model.g.dart';

@JsonSerializable()
class SaleModel {
  final String id;
  final String productId;
  final String? productName;
  final int quantity;
  final double amount;
  final String? customer;
  final DateTime saleDate;
  final bool paid;
  final bool locked;
  final String? photo;
  final DateTime createdAt;

  SaleModel({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.amount,
    this.customer,
    required this.saleDate,
    this.paid = true,
    this.locked = false,
    this.photo,
    required this.createdAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) =>
      _$SaleModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleModelToJson(this);
}

extension SaleModelX on SaleModel {
  double get unitPrice => quantity > 0 ? amount / quantity : 0;
  String get formattedDate =>
      '${saleDate.day}/${saleDate.month}/${saleDate.year}';
  String get formattedAmount => '${amount.toStringAsFixed(0)} CFA';
}
