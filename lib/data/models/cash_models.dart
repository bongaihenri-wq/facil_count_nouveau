// PAS DE part/freezed - juste des classes simples
class CashSummary {
  final double cashSales;
  final double creditSales;
  final double cashPurchases;
  final double creditPurchases;
  final double expenses;
  final double bankDeposits;
  final double withdrawals;
  final double ownerTransfers;

  const CashSummary({
    required this.cashSales,
    required this.creditSales,
    required this.cashPurchases,
    required this.creditPurchases,
    required this.expenses,
    required this.bankDeposits,
    required this.withdrawals,
    required this.ownerTransfers,
  });

  double get netCashFlow =>
      cashSales -
      (cashPurchases + expenses + bankDeposits + withdrawals + ownerTransfers);

  double get totalIn => cashSales;
  double get totalOut =>
      cashPurchases + expenses + bankDeposits + withdrawals + ownerTransfers;
}

class DebtInfo {
  final String name;
  final double amount;
  final DateTime date;
  final String type; // 'customer' ou 'supplier'
  final String? phone;
  final String? description;
  final DateTime? dueDate;
  final int? paymentDelayDays;

  const DebtInfo({
    required this.name,
    required this.amount,
    required this.date,
    required this.type,
    this.phone,
    this.description,
    this.dueDate,
    this.paymentDelayDays,
  });
}

class CashTransaction {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String? description;

  const CashTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
  });
}
