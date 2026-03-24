import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/purchase_model.dart';

class PurchaseRepository {
  final SupabaseClient _client;

  PurchaseRepository(this._client);

  Future<List<PurchaseModel>> getPurchases() async {
    final data = await _client
        .from('purchases')
        .select('*, products(name)')
        .order('purchase_date', ascending: false);

    return (data as List<dynamic>)
        .map((json) => PurchaseModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PurchaseModel> createPurchase({
    required String productId,
    required int quantity,
    required double amount,
    String? supplier,
    required DateTime purchaseDate,
    bool paid = true,
  }) async {
    final data = await _client
        .from('purchases')
        .insert({
          'product_id': productId,
          'quantity': quantity,
          'amount': amount,
          'supplier': supplier,
          'purchase_date': purchaseDate.toIso8601String(),
          'paid': paid,
        })
        .select('*, products(name)')
        .single();

    return PurchaseModel.fromJson(data as Map<String, dynamic>);
  }

  Future<PurchaseModel> updatePurchase({
    required String id,
    required String productId,
    required int quantity,
    required double amount,
    String? supplier,
    required DateTime purchaseDate,
    required bool paid,
    required bool locked,
  }) async {
    final data = await _client
        .from('purchases')
        .update({
          'product_id': productId,
          'quantity': quantity,
          'amount': amount,
          'supplier': supplier,
          'purchase_date': purchaseDate.toIso8601String(),
          'paid': paid,
          'locked': locked,
        })
        .eq('id', id)
        .select('*, products(name)')
        .single();

    return PurchaseModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deletePurchase(String id) async {
    await _client.from('purchases').delete().eq('id', id);
  }
}
