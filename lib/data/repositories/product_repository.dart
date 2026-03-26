import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductRepository {
  final SupabaseClient _client;

  ProductRepository(this._client);

  Future<List<ProductModel>> getProducts() async {
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
    // ... identique ...
  }

  // ✅ AJOUTER : Créer un produit
  Future<ProductModel> createProduct({
    required String name,
    required String category,
    String? supplier,
    int initialStock = 0,
    int lowStockThreshold = 10,
  }) async {
    final data = await _client
        .from('products')
        .insert({
          'name': name,
          'category': category,
          'supplier': supplier,
          'initial_stock': initialStock,
          'low_stock_threshold': lowStockThreshold,
        })
        .select()
        .single();

    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  // ✅ AJOUTER : Modifier un produit
  Future<void> updateProduct({
    required String id,
    String? name,
    String? category,
    String? supplier,
    int? initialStock,
    int? lowStockThreshold,
    int? currentStock, // AJOUTER
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (category != null) updates['category'] = category;
    if (supplier != null) updates['supplier'] = supplier;
    if (initialStock != null) updates['initial_stock'] = initialStock;
    if (lowStockThreshold != null) {
      updates['low_stock_threshold'] = lowStockThreshold;
    }
    if (currentStock != null) {
      updates['current_stock'] = currentStock; // AJOUTER
    }

    await _client.from('products').update(updates).eq('id', id);
  }

  // ✅ AJOUTER : Supprimer un produit
  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  // ✅ AJOUTER : Mettre à jour le stock (pour l'écran Stock)
  Future<void> updateStock(String productId, int newStock) async {
    await _client.rpc(
      'update_product_stock',
      params: {'p_product_id': productId, 'p_new_stock': newStock},
    );
  }
}
