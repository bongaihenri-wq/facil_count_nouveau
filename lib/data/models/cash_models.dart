// lib/data/models/cash_models.dart

import 'package:flutter/material.dart';

enum TransactionType {
  sale,           // Vente au comptant
  purchase,       // Achat au comptant
  expense,        // Dépense diverses
  contribution,   // Apport/Appro
  bankDeposit,    // Versement banque
  withdrawal,     // Retrait
  ownerTransfer,  // Remis gérant
}

enum DebtType {
  customer,   // Créance client
  supplier,   // Dette fournisseur
}

extension TransactionTypeExtension on TransactionType {
  String get label => {
    TransactionType.sale: 'Vente',
    TransactionType.purchase: 'Achat',
    TransactionType.expense: 'Dépense',
    TransactionType.contribution: 'Apport',
    TransactionType.bankDeposit: 'Versement Banque',
    TransactionType.withdrawal: 'Retrait',
    TransactionType.ownerTransfer: 'Remis Gérant',
  }[this]!;

  Color get color => {
    TransactionType.sale: Colors.green,
    TransactionType.purchase: Colors.orange,
    TransactionType.expense: Colors.red,
    TransactionType.contribution: Colors.blue,
    TransactionType.bankDeposit: Colors.indigo,
    TransactionType.withdrawal: Colors.purple,
    TransactionType.ownerTransfer: Colors.teal,
  }[this]!;

  IconData get icon => {
    TransactionType.sale: Icons.point_of_sale,
    TransactionType.purchase: Icons.shopping_cart,
    TransactionType.expense: Icons.receipt_long,
    TransactionType.contribution: Icons.add_circle,
    TransactionType.bankDeposit: Icons.account_balance,
    TransactionType.withdrawal: Icons.payments,
    TransactionType.ownerTransfer: Icons.person,
  }[this]!;
}

class CashTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? description;
  final DateTime createdAt;

  CashTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    required this.createdAt,
  });

  bool get isInflow => [
    TransactionType.sale,
    TransactionType.contribution,
  ].contains(type);

  bool get isOutflow => [
    TransactionType.purchase,
    TransactionType.expense,
    TransactionType.bankDeposit,
    TransactionType.withdrawal,
    TransactionType.ownerTransfer,
  ].contains(type);

  String get label => type.label;
  Color get color => type.color;
  IconData get icon => type.icon;
}

class CashSummary {
  final double totalIn;
  final double totalOut;
  final double netCashFlow;

  CashSummary({
    required this.totalIn,
    required this.totalOut,
    required this.netCashFlow,
  });
}

// ============================================================
// DEBT INFO COMPLET - avec tous les champs nécessaires
// ============================================================

class DebtInfo {
  final String id;
  final String name;
  final double amount;
  final DateTime date;           // Date de la vente/achat
  final DateTime dueDate;        // Date d'échéance
  final DebtType type;           // customer ou supplier
  final String? phone;           // Téléphone
  final String? description;     // Description
  final int? paymentDelayDays;   // Jours de retard

  DebtInfo({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.dueDate,
    required this.type,
    this.phone,
    this.description,
    this.paymentDelayDays,
  });
}

class CashState {
  final CashSummary summary;
  final List<DebtInfo> customerDebts;
  final List<DebtInfo> supplierDebts;
  final DateTime selectedDate;
  final List<CashTransaction> transactions;

  CashState({
    required this.summary,
    this.customerDebts = const [],
    this.supplierDebts = const [],
    required this.selectedDate,
    this.transactions = const [],
  });

  CashState copyWith({
    CashSummary? summary,
    List<DebtInfo>? customerDebts,
    List<DebtInfo>? supplierDebts,
    DateTime? selectedDate,
    List<CashTransaction>? transactions,
  }) {
    return CashState(
      summary: summary ?? this.summary,
      customerDebts: customerDebts ?? this.customerDebts,
      supplierDebts: supplierDebts ?? this.supplierDebts,
      selectedDate: selectedDate ?? this.selectedDate,
      transactions: transactions ?? this.transactions,
    );
  }
}
