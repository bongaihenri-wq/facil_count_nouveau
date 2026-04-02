import 'package:facil_count_nouveau/core/utils/formatters.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

@JsonSerializable()
class SaleModel {
  final String id;
  final String businessId;
  final String userId;
  final String productId;
  final String? productName;
  final int quantity;
  final double amount;
  final String? customer;
  final String? clientId;
  final DateTime saleDate;
  final bool paid;
  final bool locked;
  final String? photo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SaleModel({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.amount,
    this.customer,
    this.clientId,
    required this.saleDate,
    this.paid = true,
    this.locked = false,
    this.photo,
    required this.createdAt,
    this.updatedAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      businessId: json['business_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 
                   json['products']?['name']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      customer: json['customer']?.toString(),
      clientId: json['client_id']?.toString(),
      saleDate: DateTime.tryParse(json['sale_date']?.toString() ?? '') ?? 
                DateTime.now(),
      paid: json['paid'] ?? true,
      locked: json['locked'] ?? false,
      photo: json['photo']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? 
                 DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'user_id': userId,
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'amount': amount,
    'customer': customer,
    'client_id': clientId,
    'sale_date': saleDate.toIso8601String(),
    'paid': paid,
    'locked': locked,
    'photo': photo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  SaleModel copyWith({
    String? id,
    String? businessId,
    String? userId,
    String? productId,
    String? productName,
    int? quantity,
    double? amount,
    String? customer,
    String? clientId,
    DateTime? saleDate,
    bool? paid,
    bool? locked,
    String? photo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SaleModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      customer: customer ?? this.customer,
      clientId: clientId ?? this.clientId,
      saleDate: saleDate ?? this.saleDate,
      paid: paid ?? this.paid,
      locked: locked ?? this.locked,
      photo: photo ?? this.photo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension SaleModelX on SaleModel {
  double get unitPrice => quantity > 0 ? amount / quantity : 0;
  String get formattedDate => '${saleDate.day}/${saleDate.month}/${saleDate.year}';
  String get formattedAmount => Formatters.formatCurrency(amount);
  String get formattedQuantity => Formatters.formatNumber(quantity);
}
