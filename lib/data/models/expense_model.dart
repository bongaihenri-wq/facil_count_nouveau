import 'package:json_annotation/json_annotation.dart';

part 'expense_model.g.dart';

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

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);
}
