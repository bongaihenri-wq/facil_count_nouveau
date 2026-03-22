// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseModel _$ExpenseModelFromJson(Map<String, dynamic> json) => ExpenseModel(
  id: json['id'] as String,
  name: json['name'] as String,
  amount: (json['amount'] as num).toDouble(),
  recipient: json['recipient'] as String?,
  invoiceNumber: json['invoiceNumber'] as String?,
  expensesDate: DateTime.parse(json['expensesDate'] as String),
  paid: json['paid'] as bool? ?? false,
  locked: json['locked'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ExpenseModelToJson(ExpenseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'amount': instance.amount,
      'recipient': instance.recipient,
      'invoiceNumber': instance.invoiceNumber,
      'expensesDate': instance.expensesDate.toIso8601String(),
      'paid': instance.paid,
      'locked': instance.locked,
      'createdAt': instance.createdAt.toIso8601String(),
    };
