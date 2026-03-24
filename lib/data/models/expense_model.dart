import 'package:json_annotation/json_annotation.dart';
import 'package:facil_count_nouveau/core/utils/formatters.dart';

@JsonSerializable()
class ExpenseModel {
  final String id;
  final String name;
  final double amount;
  final String? recipient;
  final String? invoiceNumber;
  final DateTime expensesDate;
  final bool paid;
  final bool locked;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.name,
    required this.amount,
    this.recipient,
    this.invoiceNumber,
    required this.expensesDate,
    this.paid = false,
    this.locked = false,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sans nom',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      recipient: json['recipient']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      expensesDate:
          DateTime.tryParse(json['expenses_date']?.toString() ?? '') ??
          DateTime.now(),
      paid: json['paid'] as bool? ?? false,
      locked: json['locked'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'recipient': recipient,
    'invoice_number': invoiceNumber,
    'expenses_date': expensesDate.toIso8601String(),
    'paid': paid,
    'locked': locked,
    'created_at': createdAt.toIso8601String(),
  };
}

// ✅ EXTENSION AJOUTÉE ICI
extension ExpenseModelX on ExpenseModel {
  // ✅ SÉPARATEUR DE MILLIERS
  String get formattedAmount => Formatters.formatCurrency(amount);
  String get formattedDate =>
      '${expensesDate.day}/${expensesDate.month}/${expensesDate.year}';
}
