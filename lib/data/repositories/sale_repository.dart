import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import 'product_repository.dart';

class SaleRepository {
  final SupabaseClient _client;
  final ProductRepository _productRepo;

  SaleRepository(this._client) : _productRepo = ProductRepository(_client);

  Future<List<SaleModel>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
  }) async {
    var query = _client.from('sales').select('''
      id,
      product_id,
      quantity,
      amount,
      customer,
      sale_date,
      paid,
      locked,
      photo,
      created_at,
      products(name)
    ''');

    if (startDate != null) {
      query = query.gte('sale_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('sale_date', endDate.toIso8601String());
    }
    if (productId != null) {
      query = query.eq('product_id', productId);
    }

    final data = await query.order('sale_date', ascending: false);

    return (data as List<dynamic>).map((json) {
      final saleJson = json as Map<String, dynamic>;
      return SaleModel.fromJson(saleJson);
    }).toList();
  }

  // AJOUTER CETTE MÉTHODE
  Future<SaleModel> createSale({
    required String productId,
    required int quantity,
    required double amount,
    String? customer,
    required DateTime saleDate,
    bool paid = true,
  }) async {
    final product = await _productRepo.getProductById(productId);
    if (product == null) throw Exception('Produit non trouvé');
    if ((product.currentStock ?? 0) < quantity) {
      throw Exception(
        'Stock insuffisant. Disponible: ${product.currentStock ?? 0}',
      );
    }

    final saleData = await _client
        .from('sales')
        .insert({
          'product_id': productId,
          'quantity': quantity,
          'amount': amount,
          'customer': customer,
          'sale_date': saleDate.toIso8601String(),
          'paid': paid,
        })
        .select('*, products(name)')
        .single();

    await _client.rpc(
      'create_sale_with_stock_update',
      params: {'p_product_id': productId, 'p_quantity': quantity},
    );

    return SaleModel.fromJson({
      ...saleData as Map<String, dynamic>,
      'product_name': saleData['products']?['name'],
    });
  }

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
    final response = await _client
        .from('sales')
        .update({
          'product_id': productId,
          'quantity': quantity,
          'amount': amount,
          'customer': customer,
          'sale_date': saleDate.toIso8601String(),
          'paid': paid,
          'locked': locked,
        })
        .eq('id', id);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  // AJOUTER CETTE MÉTHODE
  Future<void> deleteSale(String id, String productId, int quantity) async {
    await _client.from('sales').delete().eq('id', id);

    await _client.rpc(
      'update_stock_after_delete',
      params: {'p_product_id': productId, 'p_quantity': quantity},
    );
  }

  Future<Map<String, dynamic>> getMonthlyStats() async {
    final response = await _client.rpc('get_sale_stats');
    return response as Map<String, dynamic>;
  }
}
