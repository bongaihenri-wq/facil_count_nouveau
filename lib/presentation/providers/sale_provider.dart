import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/sale_repository.dart';
import 'expense_provider.dart';
import 'product_provider.dart';

final saleRepositoryProvider = Provider(
  (ref) => SaleRepository(ref.watch(supabaseClientProvider)),
);

// Sales list - AsyncValue
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
    state = const AsyncValue.loading();
    try {
      await _repo.updateSale(
        id: id,
        productId: productId,
        quantity: quantity,
        amount: amount,
        customer: customer,
        saleDate: saleDate,
        paid: paid,
        locked: locked,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSale(SaleModel sale) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteSale(sale.id, sale.productId, sale.quantity);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Filtres
class SaleFilters {
  final String? productId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minQuantity;
  final int? maxQuantity;
  final String? period;  // ← AJOUTÉ

  const SaleFilters({
    this.productId,
    this.startDate,
    this.endDate,
    this.minQuantity,
    this.maxQuantity,
    this.period,  // ← AJOUTÉ
  });

  bool get isActive =>
      productId != null ||
      startDate != null ||
      endDate != null ||
      minQuantity != null ||
      maxQuantity != null ||
      period != null;  // ← AJOUTÉ

  SaleFilters copyWith({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    int? minQuantity,
    int? maxQuantity,
    String? period,  // ← AJOUTÉ
  }) => SaleFilters(
    productId: productId ?? this.productId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    minQuantity: minQuantity ?? this.minQuantity,
    maxQuantity: maxQuantity ?? this.maxQuantity,
    period: period ?? this.period,  // ← AJOUTÉ
  );
}

class SaleFiltersNotifier extends StateNotifier<SaleFilters> {
  SaleFiltersNotifier() : super(const SaleFilters());

  void setFilters({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    int? minQuantity,
    int? maxQuantity,
  }) {
    state = state.copyWith(
      productId: productId,
      startDate: startDate,
      endDate: endDate,
      minQuantity: minQuantity,
      maxQuantity: maxQuantity,
    );
  }

  void clearFilters() => state = const SaleFilters();
}

final saleFiltersProvider =
    StateNotifierProvider<SaleFiltersNotifier, SaleFilters>((ref) {
      return SaleFiltersNotifier();
    });

// ⭐ GARDÉ COMME PROVIDER SIMPLE - Liste directe, pas AsyncValue
final filteredSalesProvider = Provider<List<SaleModel>>((ref) {
  final allSales = ref.watch(salesProvider).valueOrNull ?? [];
  final filters = ref.watch(saleFiltersProvider);

  print('Filtres actifs: ${filters.isActive}');

  return allSales.where((sale) {
    if (filters.productId != null && sale.productId != filters.productId) {
      return false;
    }
    if (filters.startDate != null &&
        sale.saleDate.isBefore(filters.startDate!)) {
      return false;
    }
    if (filters.endDate != null && sale.saleDate.isAfter(filters.endDate!)) {
      return false;
    }
    if (filters.minQuantity != null && sale.quantity < filters.minQuantity!) {
      return false;
    }
    if (filters.maxQuantity != null && sale.quantity > filters.maxQuantity!) {
      return false;
    }
    return true;
  }).toList();
});

final saleNotifierProvider =
    StateNotifierProvider<SaleNotifier, AsyncValue<void>>((ref) {
      return SaleNotifier(ref.watch(saleRepositoryProvider));
    });

// Tab state
final saleTabProvider = StateProvider<int>((ref) => 0);
