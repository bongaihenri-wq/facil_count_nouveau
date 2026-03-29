// lib/presentation/providers/purchase_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/purchase_model.dart';
import '../../data/repositories/purchase_repository.dart';
import 'expense_provider.dart';

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
  final String? period;

  const PurchaseFilters({
    this.productId,
    this.startDate,
    this.endDate,
    this.supplier,
    this.period,
  });

  bool get isActive =>
      productId != null ||
      startDate != null ||
      endDate != null ||
      supplier != null ||
      period != null;

  PurchaseFilters copyWith({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    String? supplier,
    String? period,
  }) => PurchaseFilters(
    productId: productId ?? this.productId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    supplier: supplier ?? this.supplier,
    period: period ?? this.period,
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

// ⭐ CORRIGÉ : Retourne List<PurchaseModel> directement (identique à SaleScreen)
final filteredPurchasesProvider = Provider<List<PurchaseModel>>((ref) {
  final allPurchases = ref.watch(purchasesProvider).valueOrNull ?? [];
  final filters = ref.watch(purchaseFiltersProvider);

  print('Filtres actifs: ${filters.isActive}');

  return allPurchases.where((purchase) {
    if (filters.productId != null && purchase.productId != filters.productId) {
      return false;
    }
    if (filters.startDate != null &&
        purchase.purchaseDate.isBefore(filters.startDate!)) {
      return false;
    }
    if (filters.endDate != null &&
        purchase.purchaseDate.isAfter(filters.endDate!)) {
      return false;
    }
    if (filters.supplier != null &&
        !(purchase.supplier?.toLowerCase().contains(
              filters.supplier!.toLowerCase(),
            ) ??
            false)) {
      return false;
    }
    return true;
  }).toList();
});

// Tab state
final purchaseTabProvider = StateProvider<int>((ref) => 0);