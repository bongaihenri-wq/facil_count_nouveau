import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // --- RÉCUPÉRATION (GET) ---
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final data = await _client
        .from('expenses')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getSales() async {
    final data = await _client
        .from('sales')
        .select('*, products(name)')
        .order('sale_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getPurchases() async {
    final data = await _client
        .from('purchases')
        .select('*, products(name)')
        .order('purchase_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // --- AJOUT (INSERT) ---
  Future<void> addExpense({
    required String label,
    required double amount,
    required String category,
    required bool isManual,
  }) async {
    await _client.from('expenses').insert({
      'label': label,
      'amount': amount,
      'category': category,
      'type': isManual ? 'manuel' : 'automatique',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addSale({
    required String productId,
    required int quantity,
    required double totalAmount,
    String? customerName,
  }) async {
    await _client.from('sales').insert({
      'product_id': productId,
      'quantity': quantity,
      'total_amount': totalAmount,
      'customer_name': customerName,
      'sale_date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addPurchase({
    required String productId,
    required int quantity,
    required double unitPrice,
  }) async {
    await _client.from('purchases').insert({
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': quantity * unitPrice,
      'purchase_date': DateTime.now().toIso8601String(),
    });
  }

  // --- CALCULS (STATISTIQUES) ---
  Future<double> _calculateTotal(
    String table,
    String dateCol,
    String amtCol,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from(table)
        .select(amtCol)
        .gte(dateCol, start.toIso8601String())
        .lte(dateCol, end.toIso8601String());

    // Calcul du total à partir des données
    return response.fold<double>(
      0.0,
      (sum, row) => sum + ((row[amtCol] as num?)?.toDouble() ?? 0.0),
    );
  }

  Future<double> getTotalExpenses(DateTime start, DateTime end) =>
      _calculateTotal('expenses', 'created_at', 'amount', start, end);

  Future<double> getTotalSales(DateTime start, DateTime end) =>
      _calculateTotal('sales', 'sale_date', 'total_amount', start, end);

  Future<double> getTotalPurchases(DateTime start, DateTime end) =>
      _calculateTotal('purchases', 'purchase_date', 'total_amount', start, end);
}
