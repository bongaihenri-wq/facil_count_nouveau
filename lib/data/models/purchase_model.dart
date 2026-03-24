import 'package:facil_count_nouveau/core/utils/formatters.dart';

class PurchaseModel {
  final String id;
  final String productId;
  final String? productName;
  final int quantity;
  final double amount;
  final String? supplier;
  final DateTime purchaseDate;
  final bool paid;
  final bool locked;
  final DateTime createdAt;

  PurchaseModel({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.amount,
    this.supplier,
    required this.purchaseDate,
    this.paid = true,
    this.locked = false,
    required this.createdAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['products']?['name']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      supplier: json['supplier']?.toString(),
      purchaseDate:
          DateTime.tryParse(json['purchase_date']?.toString() ?? '') ??
          DateTime.now(),
      paid: json['paid'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'quantity': quantity,
    'amount': amount,
    'supplier': supplier,
    'purchase_date': purchaseDate.toIso8601String(),
    'paid': paid,
    'locked': locked,
    'created_at': createdAt.toIso8601String(),
  };
}

extension PurchaseModelX on PurchaseModel {
  double get unitPrice => quantity > 0 ? amount / quantity : 0;
  String get formattedAmount => Formatters.formatCurrency(amount);
  String get formattedDate =>
      '${purchaseDate.day}/${purchaseDate.month}/${purchaseDate.year}';
}
