import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // --- SECTION PRODUITS & STOCK ---
  Future<List<Map<String, dynamic>>> getProducts() async {
    final data = await _client.from('products').select().order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    await _client
        .from('products')
        .update({'stock': newStock})
        .eq('id', productId);
  }

  // --- SECTION VENTES ---
  Future<List<Map<String, dynamic>>> getSales() async {
    // On récupère la vente ET le nom du produit associé (Jointure)
    final data = await _client
        .from('sales')
        .select('*, products(name)')
        .order('sale_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> insertSale(Map<String, dynamic> saleData) async {
    await _client.from('sales').insert(saleData);
  }

  // --- SECTION DÉPENSES (Axe manuel + automatique) ---
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final data = await _client
        .from('expenses')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<double> getTotalExpensesByPeriod(DateTime start, DateTime end) async {
    final response = await _client
        .from('expenses')
        .select('amount')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());

    final List<dynamic> data = response;
    return data.fold(0.0, (prev, element) => prev + (element['amount'] ?? 0));
  }

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
}
