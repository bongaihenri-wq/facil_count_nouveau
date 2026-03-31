// lib/presentation/providers/product_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/utils/business_helper.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final client = Supabase.instance.client;
  final businessHelper = ref.watch(businessHelperProvider);
  return ProductRepository(client, businessHelper);
});

// ... reste du fichier inchangé

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProducts();
});

class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repo;

  ProductNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> createProduct({
    required String name,
    required String category,
    String? supplier,
    int initialStock = 0,
    int lowStockThreshold = 10,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createProduct(
        name: name,
        category: category,
        supplier: supplier,
        initialStock: initialStock,
        lowStockThreshold: lowStockThreshold,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String category,
    String? supplier,
    int? initialStock,
    int? lowStockThreshold,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateProduct(
        id: id,
        name: name,
        category: category,
        supplier: supplier,
        initialStock: initialStock,
        lowStockThreshold: lowStockThreshold,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteProduct(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
      return ProductNotifier(ref.watch(productRepositoryProvider));
    });

final productSearchProvider = StateProvider<String>((ref) => '');

final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final searchQuery = ref.watch(productSearchProvider).toLowerCase();

  return productsAsync.when(
    data: (products) {
      if (searchQuery.isEmpty) return products;

      return products.where((p) {
        return p.name.toLowerCase().contains(searchQuery) ||
            p.category.toLowerCase().contains(searchQuery) ||
            (p.supplier?.toLowerCase().contains(searchQuery) ?? false) ||
            p.currentStock.toString().contains(searchQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ✅ RECRÉÉ pour compatibilité stock_screen.dart
final productActionsProvider = Provider<ProductActions>((ref) {
  return ProductActions(ref);
});

class ProductActions {
  final Ref _ref;

  ProductActions(this._ref);

  Future<void> addProduct(ProductModel product) async {
    final notifier = _ref.read(productNotifierProvider.notifier);
    await notifier.createProduct(
      name: product.name,
      category: product.category,
      supplier: product.supplier,
      initialStock: product.initialStock,
      lowStockThreshold: product.lowStockThreshold,
    );
    _ref.invalidate(productsProvider);
  }

  Future<void> updateProduct(ProductModel product) async {
    final notifier = _ref.read(productNotifierProvider.notifier);
    await notifier.updateProduct(
      id: product.id,
      name: product.name,
      category: product.category,
      supplier: product.supplier,
      initialStock: product.initialStock,
      lowStockThreshold: product.lowStockThreshold,
    );
    _ref.invalidate(productsProvider);
  }

  Future<void> deleteProduct(String id) async {
    final notifier = _ref.read(productNotifierProvider.notifier);
    await notifier.deleteProduct(id);
    _ref.invalidate(productsProvider);
  }

  Future<void> updateStock(String productId, int newStock) async {
    _ref.invalidate(productsProvider);
  }
}
