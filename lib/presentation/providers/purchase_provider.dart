import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/purchase_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/purchase_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'expense_provider.dart'; // Pour supabaseClientProvider
import 'product_provider.dart'; // Pour productsProvider

final purchaseRepositoryProvider = Provider(
  (ref) => PurchaseRepository(ref.watch(supabaseClientProvider)),
);

// Purchases list
final purchasesProvider = FutureProvider<List<PurchaseModel>>((ref) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.getPurchases();
});

// Actions
class PurchaseNotifier extends StateNotifier<AsyncValue<void>> {
  final PurchaseRepository _repo;

  PurchaseNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> createPurchase({
    required String productId,
    required int quantity,
    required double amount,
    String? supplier,
    required DateTime purchaseDate,
    bool paid = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createPurchase(
        productId: productId,
        quantity: quantity,
        amount: amount,
        supplier: supplier,
        purchaseDate: purchaseDate,
        paid: paid,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePurchase({
    required String id,
    required String productId,
    required int quantity,
    required double amount,
    String? supplier,
    required DateTime purchaseDate,
    required bool paid,
    required bool locked,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updatePurchase(
        id: id,
        productId: productId,
        quantity: quantity,
        amount: amount,
        supplier: supplier,
        purchaseDate: purchaseDate,
        paid: paid,
        locked: locked,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePurchase(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deletePurchase(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final purchaseNotifierProvider =
    StateNotifierProvider<PurchaseNotifier, AsyncValue<void>>((ref) {
      return PurchaseNotifier(ref.watch(purchaseRepositoryProvider));
    });

// Filtres
class PurchaseFilters {
  final String? productId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? supplier;

  const PurchaseFilters({
    this.productId,
    this.startDate,
    this.endDate,
    this.supplier,
  });

  bool get isActive =>
      productId != null ||
      startDate != null ||
      endDate != null ||
      supplier != null;

  PurchaseFilters copyWith({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    String? supplier,
  }) => PurchaseFilters(
    productId: productId ?? this.productId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    supplier: supplier ?? this.supplier,
  );
}

class PurchaseFiltersNotifier extends StateNotifier<PurchaseFilters> {
  PurchaseFiltersNotifier() : super(const PurchaseFilters());

  void setFilters({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    String? supplier,
  }) {
    state = state.copyWith(
      productId: productId,
      startDate: startDate,
      endDate: endDate,
      supplier: supplier,
    );
  }

  void clearFilters() => state = const PurchaseFilters();
}

final purchaseFiltersProvider =
    StateNotifierProvider<PurchaseFiltersNotifier, PurchaseFilters>((ref) {
      return PurchaseFiltersNotifier();
    });

final filteredPurchasesProvider = Provider<AsyncValue<List<PurchaseModel>>>((
  ref,
) {
  final purchasesAsync = ref.watch(purchasesProvider);
  final filters = ref.watch(purchaseFiltersProvider);

  return purchasesAsync.when(
    data: (purchases) {
      final filtered = purchases.where((p) {
        if (filters.productId != null && p.productId != filters.productId)
          return false;
        if (filters.startDate != null &&
            p.purchaseDate.isBefore(filters.startDate!))
          return false;
        if (filters.endDate != null && p.purchaseDate.isAfter(filters.endDate!))
          return false;
        if (filters.supplier != null &&
            !(p.supplier?.toLowerCase().contains(
                  filters.supplier!.toLowerCase(),
                ) ??
                false))
          return false;
        return true;
      }).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// Tab state
final purchaseTabProvider = StateProvider<int>((ref) => 0);
