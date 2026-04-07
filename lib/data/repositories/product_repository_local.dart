// lib/presentation/providers/product_repository_local.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/product_model.dart';
import '../../core/utils/business_helper.dart';

class ProductRepositoryLocal {
  final SupabaseClient _client;
  final BusinessHelper _businessHelper;

  ProductRepositoryLocal(this._client, this._businessHelper);

  Future<List<ProductModel>> getProducts() async {
    final businessId = await _businessHelper.getBusinessId();
    final productsData = await _client
        .from('products')
        .select('id, name, category, supplier, initial_stock, low_stock_threshold, created_at, business_id')
        .eq('business_id', businessId)
        .order('name');

    if (productsData.isEmpty) return [];

    final productIds = productsData.map((p) => p['id'] as String).toList();

    final allPurchases = await _client
        .from('purchases')
        .select('product_id, quantity')
        .inFilter('product_id', productIds);

    final allSales = await _client
        .from('sales')
        .select('product_id, quantity')
        .inFilter('product_id', productIds);

    return productsData.map((productJson) {
      final productId = productJson['id'] as String;
      final initialStock = (productJson['initial_stock'] as num?)?.toInt() ?? 0;

      final productPurchases = allPurchases.where((p) => p['product_id'] == productId);
      final totalPurchases = productPurchases.fold<int>(
        0, (sum, p) => sum + ((p['quantity'] as num?)?.toInt() ?? 0),
      );

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
        'current_stock': realStock,
        'created_at': productJson['created_at'],
      });
    }).toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final products = await getProducts();
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) { return null; }
  }

  Future<ProductModel> createProduct({
    required String name,
    required String category,
    String? supplier,
    int initialStock = 0,
    int lowStockThreshold = 10,
  }) async {
    final businessId = await _businessHelper.getBusinessId();
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

  Future<void> updateStockManual(String productId, int newStock) async {
    await _client.from('products').update({'initial_stock': newStock}).eq('id', productId);
  }
  Future<void> updateProductStock(String id, int newStock) async {
  await _client
      .from('products')
      .update({
        'initial_stock': newStock, // On définit le nouveau point de référence
        'current_stock': newStock, // On aligne le stock actuel
      })
      .eq('id', id);
  }
}
