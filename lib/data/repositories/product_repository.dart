import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../../core/utils/business_helper.dart';

class ProductRepository {
  final SupabaseClient _client;
  final BusinessHelper _businessHelper;

  ProductRepository(this._client, this._businessHelper);

  Future<List<ProductModel>> getProducts() async {
    final businessId = await _businessHelper.getBusinessId();

    // 1. On récupère les produits ET le stock calculé par SQL (via la jointure)
    final productsData = await _client
        .from('products')
        .select('''
          *,
          product_current_stock(current_stock)
        ''')
        .eq('business_id', businessId)
        .order('name');

    if (productsData.isEmpty) return [];

    return productsData.map((productJson) {
      // 2. On récupère la valeur calculée par le Trigger SQL
      final stockRelation = productJson['product_current_stock'] as List?;
      final sqlCalculatedStock = (stockRelation != null && stockRelation.isNotEmpty)
          ? (stockRelation[0]['current_stock'] as num?)?.toInt() ?? 0
          : (productJson['initial_stock'] as num?)?.toInt() ?? 0;

      return ProductModel.fromJson({
        'id': productJson['id'],
        'name': productJson['name'],
        'category': productJson['category'],
        'supplier': productJson['supplier'],
        'initial_stock': (productJson['initial_stock'] as num?)?.toInt() ?? 0,
        'low_stock_threshold': (productJson['low_stock_threshold'] as num?)?.toInt() ?? 10,
        'current_stock': sqlCalculatedStock, // Utilise la valeur SQL
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
    final businessId = await _businessHelper.getBusinessId();
      
    final existing = await _client
      .from('products')
      .select('id')
      .eq('business_id', businessId)
      .ilike('name', name)
      .maybeSingle();

    if (existing != null) {
      throw Exception('Un produit nommé "$name" existe déjà.');
    }

    final data = await _client.from('products').insert({
      'name': name,
      'category': category,
      'supplier': supplier,
      'initial_stock': initialStock,
      'low_stock_threshold': lowStockThreshold,
      'business_id': businessId,
    }).select().single();

    return ProductModel.fromJson({
      'id': data['id'],
      'name': data['name'],
      'category': data['category'],
      'supplier': data['supplier'],
      'initial_stock': data['initial_stock'],
      'low_stock_threshold': data['low_stock_threshold'],
      'current_stock': initialStock,
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
    if (lowStockThreshold != null) updates['low_stock_threshold'] = lowStockThreshold;

    await _client.from('products').update(updates).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  // --- CORRECTION DU BUG "4 à 7" ---
  
  Future<void> updateStockManual(String productId, int newStock) async {
    // On appelle la méthode unifiée en dessous
    await updateProductStock(productId, newStock);
  }

  Future<void> updateProductStock(String id, int newStock) async {
  // 1. On force la mise à jour ou l'insertion (UPSERT) dans la table de stock
  // Cela garantit que même si le produit n'avait pas de ligne de stock, elle est créée.
  await _client
      .from('product_current_stock')
      .upsert({
        'id': id, // L'ID du produit
        'current_stock': newStock,
        'last_updated': DateTime.now().toIso8601String(),
      });

  // 2. On synchronise l'initial_stock dans la table principale
  await _client.from('products').update({
    'initial_stock': newStock,
  }).eq('id', id);
}
}
