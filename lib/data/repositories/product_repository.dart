// lib/data/repositories/product_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductRepository {
  final SupabaseClient _client;

  ProductRepository(this._client);

  Future<List<ProductModel>> getProducts() async {
    // Récupère tous les produits
    final productsData = await _client
        .from('products')
        .select('id, name, category, supplier, initial_stock, low_stock_threshold, created_at')
        .order('name');

    if (productsData.isEmpty) return [];

    final productIds = productsData.map((p) => p['id'] as String).toList();

    // Récupère tous les achats en UNE requête
    final allPurchases = await _client
        .from('purchases')
        .select('product_id, quantity')
        .inFilter('product_id', productIds);

    // Récupère toutes les ventes en UNE requête
    final allSales = await _client
        .from('sales')
        .select('product_id, quantity')
        .inFilter('product_id', productIds);

    // Calcule les stocks
    return productsData.map((productJson) {
      final productId = productJson['id'] as String;
      final initialStock = (productJson['initial_stock'] as num?)?.toInt() ?? 0;

      // Somme des achats
      final productPurchases = allPurchases.where((p) => p['product_id'] == productId);
      final totalPurchases = productPurchases.fold<int>(
        0, (sum, p) => sum + ((p['quantity'] as num?)?.toInt() ?? 0),
      );

      // Somme des ventes
      final productSales = allSales.where((s) => s['product_id'] == productId);
      final totalSales = productSales.fold<int>(
        0, (sum, s) => sum + ((s['quantity'] as num?)?.toInt() ?? 0),
      );

      final realStock = initialStock + totalPurchases - totalSales;

      return ProductModel.fromJson({
        'id': productJson['id'],
        'name': productJson['name'],
        'category': productJson['category'],
        'supplier': productJson['supplier'],
        'initial_stock': initialStock,
        'low_stock_threshold': (productJson['low_stock_threshold'] as num?)?.toInt() ?? 10,
        'current_stock': realStock, // ← UNDERSCORE ICI
        'created_at': productJson['created_at'],
      });
    }).toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final products = await getProducts();
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

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

    // ✅ CORRIGÉ : Utilise 'current_stock' avec underscore
    return ProductModel.fromJson({
      'id': data['id'],
      'name': data['name'],
      'category': data['category'],
      'supplier': data['supplier'],
      'initial_stock': data['initial_stock'],
      'low_stock_threshold': data['low_stock_threshold'],
      'current_stock': initialStock, // ← UNDERSCORE !
      'created_at': data['created_at'],
    });
  }

  Future<void> updateProduct({
    required String id,
    String? name,
    String? category,
    String? supplier,
    int? initialStock,
    int? lowStockThreshold,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (category != null) updates['category'] = category;
    if (supplier != null) updates['supplier'] = supplier;
    if (initialStock != null) updates['initial_stock'] = initialStock;
    if (lowStockThreshold != null) {
      updates['low_stock_threshold'] = lowStockThreshold;
    }

    await _client.from('products').update(updates).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }
  // Dans product_repository.dart
Future<void> updateStockManual(String productId, int newStock) async {
  // Met à jour le stock initial pour forcer le calcul
  await _client.from('products').update({
    'initial_stock': newStock,
  }).eq('id', productId);
}
}
