import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import '../../core/utils/business_helper.dart';

class SaleRepository {
  final SupabaseClient _client;
  final BusinessHelper _businessHelper;

  SaleRepository(this._client, this._businessHelper);

  Future<List<SaleModel>> getSales() async {
    final businessId = await _businessHelper.getBusinessId();
    final data = await _client
        .from('sales')
        .select('*, products(name), clients(name), business_id')
        .eq('business_id', businessId)
        .order('sale_date', ascending: false);

    return (data as List<dynamic>)
        .map((json) => SaleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<SaleModel> createSale({
    required String productId,
    required int quantity,
    required double amount,
    String? clientId,
    required DateTime saleDate,
    bool paid = true,
  }) async {
    final businessId = await _businessHelper.getBusinessId();

    final data = await _client
        .from('sales')
        .insert({
          'product_id': productId,
          'quantity': quantity,
          'amount': amount,
          'client_id': clientId,
          'sale_date': saleDate.toIso8601String(),
          'paid': paid,
          'business_id': businessId,
        })
        .select('*, products(name), clients(name)')
        .single();

    // Diminuer le stock (vente)
    await _updateProductStock(productId, -quantity, businessId);

    return SaleModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SaleModel> updateSale({
    required String id,
    required String productId,
    required int quantity,
    required double amount,
    String? clientId,
    required DateTime saleDate,
    required bool paid,
    required bool locked,
  }) async {
    final businessId = await _businessHelper.getBusinessId();

    final oldSale = await _client
        .from('sales')
        .select('quantity')
        .eq('id', id)
        .single();

    final oldQuantity = (oldSale['quantity'] as num).toInt();
    final quantityDiff = quantity - oldQuantity;

    final data = await _client
        .from('sales')
        .update({
          'product_id': productId,
          'quantity': quantity,
          'amount': amount,
          'client_id': clientId,
          'sale_date': saleDate.toIso8601String(),
          'paid': paid,
          'locked': locked,
        })
        .eq('id', id)
        .select('*, products(name), clients(name)')
        .single();

    if (quantityDiff != 0) {
      await _updateProductStock(productId, -quantityDiff, businessId);
    }

    return SaleModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSale(String id, String productId, int quantity) async {
    final businessId = await _businessHelper.getBusinessId();

    await _client.from('sales').delete().eq('id', id);

    // Réaugmenter le stock (suppression de vente)
    await _updateProductStock(productId, quantity, businessId);
  }

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
