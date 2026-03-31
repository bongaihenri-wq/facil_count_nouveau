import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/cash_models.dart';
import '../../core/utils/business_helper.dart';

final cashProvider = StateNotifierProvider<CashNotifier, AsyncValue<CashState>>((ref) {
  return CashNotifier(ref);
});

class CashNotifier extends StateNotifier<AsyncValue<CashState>> {
  final SupabaseClient supabase;
  final Ref _ref;

  CashNotifier(this._ref) : supabase = Supabase.instance.client, super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData() async {
    try {
      final selectedDate = DateTime.now();
      
      final transactions = await _loadAllTransactionsUntil(selectedDate);
      final summary = _calculateCumulativeSummary(transactions);
      final custDebts = await _loadCustomerDebts();
      final suppDebts = await _loadSupplierDebts();

      state = AsyncValue.data(CashState(
        summary: summary,
        customerDebts: custDebts,
        supplierDebts: suppDebts,
        selectedDate: selectedDate,
        transactions: transactions,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  CashSummary _calculateCumulativeSummary(List<CashTransaction> transactions) {
    double totalIn = 0;
    double totalOut = 0;

    for (final t in transactions) {
      if (t.isInflow) {
        totalIn += t.amount;
      } else if (t.isOutflow) {
        totalOut += t.amount;
      }
    }

    return CashSummary(
      totalIn: totalIn,
      totalOut: totalOut,
      netCashFlow: totalIn - totalOut,
    );
  }

  Future<List<CashTransaction>> _loadAllTransactionsUntil(DateTime endDate) async {
    final businessId = await _ref.read(businessHelperProvider).getBusinessId(); // ← AJOUTÉ
    
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final List<CashTransaction> transactions = [];

    // Ventes au comptant - AVEC business_id
    final sales = await supabase
        .from('sales')
        .select('id, amount, sale_date, customer, invoice_number')
        .eq('business_id', businessId) // ← AJOUTÉ
        .eq('paid', true)
        .lte('sale_date', end.toIso8601String())
        .order('sale_date', ascending: true);
    
    for (final s in sales) {
      final customer = s['customer'];
      final invoiceNum = s['invoice_number'];
      final desc = customer != null 
          ? 'Vente à $customer' 
          : (invoiceNum != null ? 'Vente #$invoiceNum' : 'Vente au comptant');
      
      transactions.add(CashTransaction(
        id: 'sale_${s['id']}',
        type: TransactionType.sale,
        amount: (s['amount'] as num).toDouble(),
        date: DateTime.parse(s['sale_date']),
        description: desc,
        createdAt: DateTime.parse(s['sale_date']),
      ));
    }

    // Achats au comptant - AVEC business_id
    final purchases = await supabase
        .from('purchases')
        .select('id, amount, purchase_date, supplier, invoice_number')
        .eq('business_id', businessId) // ← AJOUTÉ
        .eq('paid', true)
        .lte('purchase_date', end.toIso8601String())
        .order('purchase_date', ascending: true);
    
    for (final p in purchases) {
      final supplier = p['supplier'];
      final invoiceNum = p['invoice_number'];
      final desc = supplier != null 
          ? 'Achat chez $supplier' 
          : (invoiceNum != null ? 'Achat #$invoiceNum' : 'Achat au comptant');
      
      transactions.add(CashTransaction(
        id: 'purchase_${p['id']}',
        type: TransactionType.purchase,
        amount: (p['amount'] as num).toDouble(),
        date: DateTime.parse(p['purchase_date']),
        description: desc,
        createdAt: DateTime.parse(p['purchase_date']),
      ));
    }

    // Dépenses - AVEC business_id
    final expenses = await supabase
        .from('expenses')
        .select('id, amount, expenses_date, name, recipient, invoice_number')
        .eq('business_id', businessId) // ← AJOUTÉ
        .lte('expenses_date', end.toIso8601String())
        .order('expenses_date', ascending: true);
    
    for (final e in expenses) {
      final name = e['name'] ?? 'Dépense';
      final recipient = e['recipient'];
      final invoiceNum = e['invoice_number'];
      
      String desc = name;
      if (recipient != null) desc += ' à $recipient';
      if (invoiceNum != null) desc += ' (Facture: $invoiceNum)';
      
      transactions.add(CashTransaction(
        id: 'expense_${e['id']}',
        type: TransactionType.expense,
        amount: (e['amount'] as num).toDouble(),
        date: DateTime.parse(e['expenses_date']),
        description: desc,
        createdAt: DateTime.parse(e['expenses_date']),
      ));
    }

    // Transactions caisse - AVEC business_id
    final cashTrans = await supabase
        .from('cash_transactions')
        .select('id, type, amount, transaction_date, description')
        .eq('business_id', businessId) // ← AJOUTÉ
        .lte('transaction_date', end.toIso8601String())
        .order('transaction_date', ascending: true);
    
    for (final t in cashTrans) {
      final type = _parseTransactionType(t['type']);
      final typeLabel = type.label;
      final desc = t['description'] ?? typeLabel;
      
      transactions.add(CashTransaction(
        id: 'cash_${t['id']}',
        type: type,
        amount: (t['amount'] as num).toDouble(),
        date: DateTime.parse(t['transaction_date']),
        description: desc,
        createdAt: DateTime.parse(t['transaction_date']),
      ));
    }

    return transactions;
  }

  TransactionType _parseTransactionType(String? type) {
    switch (type) {
      case 'contribution':
      case 'apport':
        return TransactionType.contribution;
      case 'bank_deposit':
      case 'versement':
        return TransactionType.bankDeposit;
      case 'withdrawal':
      case 'retrait':
        return TransactionType.withdrawal;
      case 'owner_transfer':
      case 'remis_gerant':
        return TransactionType.ownerTransfer;
      default:
        return TransactionType.expense;
    }
  }

  Future<void> setDate(DateTime date) async {
    state = const AsyncValue.loading();
    try {
      final transactions = await _loadAllTransactionsUntil(date);
      final summary = _calculateCumulativeSummary(transactions);
      
      final current = state.value;
      state = AsyncValue.data(CashState(
        summary: summary,
        customerDebts: current?.customerDebts ?? [],
        supplierDebts: current?.supplierDebts ?? [],
        selectedDate: date,
        transactions: transactions,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTransaction({
    required TransactionType type,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    final businessId = await _ref.read(businessHelperProvider).getBusinessId(); // ← AJOUTÉ
    final transactionDate = date ?? DateTime.now();
    
    await supabase.from('cash_transactions').insert({
      'type': type.name,
      'amount': amount,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'business_id': businessId, // ← AJOUTÉ
    });

    await loadData();
  }

  Future<List<DebtInfo>> _loadCustomerDebts() async {
    final businessId = await _ref.read(businessHelperProvider).getBusinessId(); // ← AJOUTÉ
    
    final data = await supabase
        .from('sales')
        .select('*, clients(name, phone, payment_delay_days)')
        .eq('business_id', businessId) // ← AJOUTÉ
        .eq('paid', false)
        .order('sale_date', ascending: false);

    final now = DateTime.now();

    return data.map((s) {
      final saleDate = DateTime.parse(s['sale_date']);
      final clientData = s['clients'] ?? {};
      final delayDays = clientData['payment_delay_days'] ?? 30;
      final dueDate = saleDate.add(Duration(days: delayDays));
      final daysOverdue = now.difference(dueDate).inDays;

      final customer = s['customer'] ?? clientData['name'] ?? 'Client inconnu';
      
      return DebtInfo(
        id: s['id'].toString(),
        name: customer,
        amount: (s['amount'] as num).toDouble(),
        date: saleDate,
        dueDate: dueDate,
        type: DebtType.customer,
        phone: clientData['phone'] ?? s['customer'],
        description: s['invoice_number'] != null ? 'Facture: ${s['invoice_number']}' : null,
        paymentDelayDays: daysOverdue > 0 ? daysOverdue : 0,
      );
    }).toList();
  }

  Future<List<DebtInfo>> _loadSupplierDebts() async {
    final businessId = await _ref.read(businessHelperProvider).getBusinessId(); // ← AJOUTÉ
    
    final data = await supabase
        .from('purchases')
        .select('*, suppliers(name, phone, payment_delay_days)')
        .eq('business_id', businessId) // ← AJOUTÉ
        .eq('paid', false)
        .order('purchase_date', ascending: false);

    final now = DateTime.now();

    return data.map((p) {
      final purchaseDate = DateTime.parse(p['purchase_date']);
      final supplierData = p['suppliers'] ?? {};
      final delayDays = supplierData['payment_delay_days'] ?? 30;
      final dueDate = purchaseDate.add(Duration(days: delayDays));
      final daysOverdue = now.difference(dueDate).inDays;

      final supplier = p['supplier'] ?? supplierData['name'] ?? 'Fournisseur inconnu';
      
      return DebtInfo(
        id: p['id'].toString(),
        name: supplier,
        amount: (p['amount'] as num).toDouble(),
        date: purchaseDate,
        dueDate: dueDate,
        type: DebtType.supplier,
        phone: supplierData['phone'] ?? p['supplier'],
        description: p['invoice_number'] != null ? 'Facture: ${p['invoice_number']}' : null,
        paymentDelayDays: daysOverdue > 0 ? daysOverdue : 0,
      );
    }).toList();
  }
}
