import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/cash_models.dart';

final cashProvider = StateNotifierProvider<CashNotifier, AsyncValue<CashState>>(
  (ref) => CashNotifier(),
);

class CashState {
  final CashSummary summary;
  final List<DebtInfo> customerDebts;
  final List<DebtInfo> supplierDebts;
  final String selectedPeriod;
  final DateTime selectedDate;

  CashState({
    required this.summary,
    this.customerDebts = const [],
    this.supplierDebts = const [],
    this.selectedPeriod = 'Jour',
    required this.selectedDate,
  });

  CashState copyWith({
    CashSummary? summary,
    List<DebtInfo>? customerDebts,
    List<DebtInfo>? supplierDebts,
    String? selectedPeriod,
    DateTime? selectedDate,
  }) {
    return CashState(
      summary: summary ?? this.summary,
      customerDebts: customerDebts ?? this.customerDebts,
      supplierDebts: supplierDebts ?? this.supplierDebts,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class CashNotifier extends StateNotifier<AsyncValue<CashState>> {
  final supabase = Supabase.instance.client;

  CashNotifier() : super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData() async {
    try {
      final current = CashState(
        summary: const CashSummary(
          cashSales: 0,
          creditSales: 0,
          cashPurchases: 0,
          creditPurchases: 0,
          expenses: 0,
          bankDeposits: 0,
          withdrawals: 0,
          ownerTransfers: 0,
        ),
        selectedDate: DateTime.now(),
      );

      final (start, end) = _getDateRange(
        current.selectedPeriod,
        current.selectedDate,
      );

      final purchases = await _loadPurchases(start, end);
      final sales = await _loadSales(start, end);
      final expenses = await _loadExpenses(start, end);
      final cashTrans = await _loadCashTransactions(start, end);
      final custDebts = await _loadCustomerDebts();
      final suppDebts = await _loadSupplierDebts();

      final summary = CashSummary(
        cashPurchases: purchases['cash']!,
        creditPurchases: purchases['credit']!,
        cashSales: sales['cash']!,
        creditSales: sales['credit']!,
        expenses: expenses,
        bankDeposits: cashTrans['deposit']!,
        withdrawals: cashTrans['withdrawal']!,
        ownerTransfers: cashTrans['transfer']!,
      );

      state = AsyncValue.data(
        current.copyWith(
          summary: summary,
          customerDebts: custDebts,
          supplierDebts: suppDebts,
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  (DateTime, DateTime) _getDateRange(String period, DateTime date) {
    switch (period) {
      case 'Jour':
        final start = DateTime(date.year, date.month, date.day);
        return (start, start.add(const Duration(days: 1)));
      case 'Semaine':
        final start = date.subtract(Duration(days: date.weekday - 1));
        return (start, start.add(const Duration(days: 7)));
      case 'Mois':
        final start = DateTime(date.year, date.month, 1);
        return (start, DateTime(date.year, date.month + 1, 1));
      case 'Année':
        return (DateTime(date.year, 1, 1), DateTime(date.year + 1, 1, 1));
      default:
        final start = DateTime(date.year, date.month, date.day);
        return (start, start.add(const Duration(days: 1)));
    }
  }

  Future<Map<String, double>> _loadPurchases(
    DateTime start,
    DateTime end,
  ) async {
    final data = await supabase
        .from('purchases')
        .select('*, suppliers(name, phone)')
        .gte('purchase_date', start.toIso8601String())
        .lt('purchase_date', end.toIso8601String());

    double cash = 0, credit = 0;
    for (final p in data) {
      final amount = (p['amount'] as num).toDouble();
      if (p['paid'] == true)
        cash += amount;
      else
        credit += amount;
    }
    return {'cash': cash, 'credit': credit};
  }

  Future<Map<String, double>> _loadSales(DateTime start, DateTime end) async {
    final data = await supabase
        .from('sales')
        .select('*, clients(name, phone)')
        .gte('sale_date', start.toIso8601String())
        .lt('sale_date', end.toIso8601String());

    double cash = 0, credit = 0;
    for (final s in data) {
      final amount = (s['amount'] as num).toDouble();
      if (s['paid'] == true)
        cash += amount;
      else
        credit += amount;
    }
    return {'cash': cash, 'credit': credit};
  }

  Future<double> _loadExpenses(DateTime start, DateTime end) async {
    final data = await supabase
        .from('expenses')
        .select()
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());

    return data.fold<double>(
      0,
      (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0),
    );
  }

  Future<Map<String, double>> _loadCashTransactions(
    DateTime start,
    DateTime end,
  ) async {
    final data = await supabase
        .from('cash_transactions')
        .select()
        .gte('transaction_date', start.toIso8601String())
        .lt('transaction_date', end.toIso8601String());

    double deposit = 0, withdrawal = 0, transfer = 0;
    for (final t in data) {
      final amount = (t['amount'] as num).toDouble();
      switch (t['type']) {
        case 'bank_deposit':
          deposit += amount;
          break;
        case 'withdrawal':
          withdrawal += amount;
          break;
        case 'owner_transfer':
          transfer += amount;
          break;
      }
    }
    return {'deposit': deposit, 'withdrawal': withdrawal, 'transfer': transfer};
  }

  Future<List<DebtInfo>> _loadCustomerDebts() async {
    final data = await supabase
        .from('sales')
        .select('*, clients(name, phone, payment_delay_days)')
        .eq('paid', false)
        .order('sale_date', ascending: false);

    final now = DateTime.now();

    return data.map((s) {
      final saleDate = DateTime.parse(s['sale_date']);
      final clientData = s['clients'] ?? {};
      final delayDays = clientData['payment_delay_days'] ?? 30;
      final dueDate = saleDate.add(Duration(days: delayDays));
      final daysOverdue = now.difference(dueDate).inDays;

      return DebtInfo(
        name: clientData['name'] ?? 'Client inconnu',
        amount: (s['amount'] as num).toDouble(),
        date: saleDate,
        type: 'customer',
        phone: clientData['phone'],
        description: s['description'],
        dueDate: dueDate,
        paymentDelayDays: daysOverdue > 0 ? daysOverdue : 0,
      );
    }).toList();
  }

  Future<List<DebtInfo>> _loadSupplierDebts() async {
    final data = await supabase
        .from('purchases')
        .select('*, suppliers(name, phone, payment_delay_days)')
        .eq('paid', false)
        .order('purchase_date', ascending: false);

    final now = DateTime.now();

    return data.map((p) {
      final purchaseDate = DateTime.parse(p['purchase_date']);
      final supplierData = p['suppliers'] ?? {};
      final delayDays = supplierData['payment_delay_days'] ?? 30;
      final dueDate = purchaseDate.add(Duration(days: delayDays));
      final daysOverdue = now.difference(dueDate).inDays;

      return DebtInfo(
        name: supplierData['name'] ?? 'Fournisseur inconnu',
        amount: (p['amount'] as num).toDouble(),
        date: purchaseDate,
        type: 'supplier',
        phone: supplierData['phone'],
        description: p['description'],
        dueDate: dueDate,
        paymentDelayDays: daysOverdue > 0 ? daysOverdue : 0,
      );
    }).toList();
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    await supabase.from('cash_transactions').insert({
      'type': type,
      'amount': amount,
      'description': description,
      'transaction_date': (date ?? DateTime.now()).toIso8601String(),
    });
    await loadData();
  }

  void setPeriod(String period) {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(selectedPeriod: period));
      loadData();
    }
  }

  void setDate(DateTime date) {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(selectedDate: date));
      loadData();
    }
  }
}
