import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductRepository {
  final SupabaseClient _client;

  ProductRepository(this._client);

  Future<List<ProductModel>> getProducts() async {
    // CORRECTION: Ne pas sélectionner 'stock' qui n'existe pas
    final data = await _client
        .from('products')
        .select('''
          id,
          name,
          category,
          supplier,
          initial_stock,
          low_stock_threshold,
          created_at,
          current_stock:product_current_stock(current_stock)
        ''')
        .order('name');

    return (data as List<dynamic>).map((json) {
      final productJson = json as Map<String, dynamic>;
      // Récupérer le stock de la jointure ou mettre 0
      final currentStock = productJson['current_stock']?['current_stock'] ?? 0;

      return ProductModel.fromJson({
        'id': productJson['id'],
        'name': productJson['name'],
        'category': productJson['category'],
        'supplier': productJson['supplier'],
        'initial_stock': productJson['initial_stock'] ?? 0,
        'low_stock_threshold': productJson['low_stock_threshold'] ?? 10,
        'current_stock': currentStock,
        'created_at': productJson['created_at'],
      });
    }).toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final data = await _client
        .from('products')
        .select('''
          id,
          name,
          category,
          supplier,
          initial_stock,
          low_stock_threshold,
          created_at,
          current_stock:product_current_stock(current_stock)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;

    final productJson = data as Map<String, dynamic>;
    final currentStock = productJson['current_stock']?['current_stock'] ?? 0;

    return ProductModel.fromJson({
      'id': productJson['id'],
      'name': productJson['name'],
      'category': productJson['category'],
      'supplier': productJson['supplier'],
      'initial_stock': productJson['initial_stock'] ?? 0,
      'low_stock_threshold': productJson['low_stock_threshold'] ?? 10,
      'current_stock': currentStock,
      'created_at': productJson['created_at'],
    });
  }

  Future<void> updateStock(String productId, int newStock) async {
    await _client.rpc(
      'update_product_stock',
      params: {'p_product_id': productId, 'p_new_stock': newStock},
    );
  }
}
