import 'package:facil_count_nouveau/core/utils/formatters.dart';
import 'package:json_annotation/json_annotation.dart';

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

  // Factory manuel complet
  factory SaleModel.fromJson(Map<String, dynamic> json) => SaleModel(
    id: json['id']?.toString() ?? '',
    productId: json['product_id']?.toString() ?? '',
    productName: json['products']?['name']?.toString(),
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    customer: json['customer']?.toString(),
    saleDate:
        DateTime.tryParse(json['sale_date']?.toString() ?? '') ??
        DateTime.now(),
    paid: json['paid'] ?? true,
    locked: json['locked'] ?? false,
    photo: json['photo']?.toString(),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'amount': amount,
    'customer': customer,
    'sale_date': saleDate.toIso8601String(),
    'paid': paid,
    'locked': locked,
    'photo': photo,
    'created_at': createdAt.toIso8601String(),
  };
}

extension SaleModelX on SaleModel {
  double get unitPrice => quantity > 0 ? amount / quantity : 0;
  String get formattedDate =>
      '${saleDate.day}/${saleDate.month}/${saleDate.year}';
  String get formattedAmount =>
      Formatters.formatCurrency(amount); // Utilise l'utilitaire
  String get formattedQuantity => Formatters.formatNumber(quantity);
}
