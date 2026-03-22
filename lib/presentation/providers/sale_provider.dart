import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/sale_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'expense_provider.dart'; // Pour supabaseClientProvider

final productRepositoryProvider = Provider(
  (ref) => ProductRepository(ref.watch(supabaseClientProvider)),
);

final saleRepositoryProvider = Provider(
  (ref) => SaleRepository(ref.watch(supabaseClientProvider)),
);

// Products list
final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProducts();
});

// Sales list
final salesProvider = FutureProvider<List<SaleModel>>((ref) async {
  final repo = ref.watch(saleRepositoryProvider);
  return repo.getSales();
});

// Sale actions
class SaleNotifier extends StateNotifier<AsyncValue<void>> {
  final SaleRepository _repo;

  SaleNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> createSale({
    required String productId,
    required int quantity,
    required double amount,
    String? customer,
    required DateTime saleDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createSale(
        productId: productId,
        quantity: quantity,
        amount: amount,
        customer: customer,
        saleDate: saleDate,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSale(SaleModel sale) async {
    try {
      await _repo.deleteSale(sale.id, sale.productId, sale.quantity);
    } catch (e) {
      rethrow;
    }
  }
}

final saleNotifierProvider =
    StateNotifierProvider<SaleNotifier, AsyncValue<void>>((ref) {
      return SaleNotifier(ref.watch(saleRepositoryProvider));
    });

// Tab state
final saleTabProvider = StateProvider<int>((ref) => 0);
