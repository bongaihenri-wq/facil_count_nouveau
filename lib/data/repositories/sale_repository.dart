// lib/data/repositories/sale_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/sale_model.dart';

class SaleRepository {
  final SupabaseClient _client;

  SaleRepository(this._client);

  /// Récupère toutes les ventes avec les infos produits
  Future<List<SaleModel>> getSales() async {
    final data = await _client
        .from('sales')
        .select('''
          *,
          products(name)
        ''')
        .order('sale_date', ascending: false);

    return (data as List<dynamic>)
        .map((json) => SaleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Crée une nouvelle vente
  Future<void> createSale({
    required String productId,
    required int quantity,
    required double amount,
    String? customer,
    required DateTime saleDate,
  }) async {
    await _client.from('sales').insert({
      'product_id': productId,
      'quantity': quantity,
      'amount': amount,
      'customer': customer,
      'sale_date': saleDate.toIso8601String(),
      'paid': true,
      'locked': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// ✅ MET À JOUR une vente existante
  Future<void> updateSale({
    required String id,
    required String productId,
    required int quantity,
    required double amount,
    String? customer,
    required DateTime saleDate,
    required bool paid,
    required bool locked,
  }) async { 
    print('🔥 SaleRepository.updateSale appelé avec ID: $id');
    try {
      final result = await _client.from('sales').update({
        'product_id': productId,
        'quantity': quantity,
        'amount': amount,
        'customer': customer,
        'sale_date': saleDate.toIso8601String(),
        'paid': paid,
        'locked': locked,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
     print('✅ Résultat update: $result');
    } catch (e) {
      print('❌ Erreur Supabase: $e');
      rethrow;
    }
    await _client.from('sales').update({
      'product_id': productId,
      'quantity': quantity,
      'amount': amount,
      'customer': customer,
      'sale_date': saleDate.toIso8601String(),
      'paid': paid,
      'locked': locked,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Supprime une vente et met à jour le stock
  Future<void> deleteSale(String id, String productId, int quantity) async {
    // Supprime la vente
    await _client.from('sales').delete().eq('id', id);
    
    // Le stock sera recalculé automatiquement lors du prochain getProducts()
  }
}
