import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/purchase_model.dart';
import '../../core/utils/business_helper.dart';

class PurchaseRepository {
  final SupabaseClient _client;
  final BusinessHelper _businessHelper;

  PurchaseRepository(this._client, this._businessHelper);

  Future<List<PurchaseModel>> getPurchases() async {
    final businessId = await _businessHelper.getBusinessId();
    final data = await _client
        .from('purchases')
        .select('*, products(name), business_id')
        .eq('business_id', businessId)
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
    final businessId = await _businessHelper.getBusinessId();
    print('🔍 PurchaseRepository - BusinessId: $businessId');

    final data = await _client
        .from('purchases')
        .insert({
          'id': Uuid().v4(),
          'product_id': productId,
          'quantity': quantity,
          'amount': amount,
          'supplier': supplier,
          'purchase_date': purchaseDate.toIso8601String(),
          'paid': paid,
          'business_id': businessId,
        })
        .select('*, products(name)')
        .single();

    // 🛑 SUPPRESSION DU DOUBLON : Le trigger Supabase s'en charge maintenant automatiquement
    // await _updateProductStock(productId, quantity, businessId);

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
    final businessId = await _businessHelper.getBusinessId();

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

    // 🛑 SUPPRESSION DU DOUBLON : Supabase gère déjà la différence de stock lors d'un update
    /*
    final oldPurchase = await _client
        .from('purchases')
        .select('quantity')
        .eq('id', id)
        .single();
    final oldQuantity = (oldPurchase['quantity'] as num).toInt();
    final quantityDiff = quantity - oldQuantity;
    if (quantityDiff != 0) {
      await _updateProductStock(productId, quantityDiff, businessId);
    }
    */

    return PurchaseModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deletePurchase(String id, String productId, int quantity) async {
    final businessId = await _businessHelper.getBusinessId();

    await _client.from('purchases').delete().eq('id', id);

    // 🛑 SUPPRESSION DU DOUBLON : Le trigger Supabase s'en charge aussi à la suppression
    // await _updateProductStock(productId, -quantity, businessId);
  }

  /// 🔄 Méthode conservée au cas où elle serve pour d'autres fonctionnalités, 
  /// mais elle n'est plus appelée pour les achats.
  Future<void> _updateProductStock(String productId, int quantityDelta, String businessId) async {
    final product = await _client
        .from('products')
        .select('initial_stock')
        .eq('id', productId)
        .eq('business_id', businessId)
        .single();

    final currentStock = (product['initial_stock'] as num).toInt();
    final newStock = currentStock + quantityDelta;

    await _client
        .from('products')
        .update({'initial_stock': newStock})
        .eq('id', productId)
        .eq('business_id', businessId);
  }
}