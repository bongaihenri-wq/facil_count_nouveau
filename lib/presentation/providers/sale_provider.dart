// lib/presentation/providers/sale_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/sale_model.dart'; // 🟢 Pointera vers ton modèle de vente
import '../../data/repositories/sale_repository.dart'; // 🟢 Pointera vers ton repository de vente
import '../../core/utils/business_helper.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final client = Supabase.instance.client;
  final businessHelper = ref.watch(businessHelperProvider);
  return SaleRepository(client, businessHelper, ref);
});

// Sales list
final salesProvider = FutureProvider<List<SaleModel>>((ref) async {
  final repo = ref.watch(saleRepositoryProvider);
  return repo.getSales();
});

// Actions
class SaleNotifier extends StateNotifier<AsyncValue<void>> {
  final SaleRepository _repo;

  SaleNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> createSale({
    required String productId,
    required int quantity,
    required double amount,
    String? clientId, // 🟢 Adapté de supplier -> clientId
    required DateTime saleDate,
    bool isPaid = true, // 🟢 Nommé isPaid pour correspondre à ton add_sale_dialog.dart
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createSale(
        productId: productId,
        quantity: quantity,
        amount: amount,
        clientId: clientId,
        saleDate: saleDate,
        isPaid: isPaid,
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
    String? clientId,
    required DateTime saleDate,
    required bool isPaid,
    required bool locked,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateSale(
        id: id,
        productId: productId,
        quantity: quantity,
        amount: amount,
        clientId: clientId,
        saleDate: saleDate,
        isPaid: isPaid,
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
      await _repo.deleteSale(
        sale.id,
        sale.productId,
        sale.quantity,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final saleNotifierProvider =
    StateNotifierProvider<SaleNotifier, AsyncValue<void>>((ref) {
      return SaleNotifier(ref.watch(saleRepositoryProvider));
    });

// Filtres
class SaleFilters {
  final String? productId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? clientId; // 🟢 Adapté de supplier -> clientId
  final String? period;
  final int? minQuantity;
  final int? maxQuantity;


  const SaleFilters({
    this.productId,
    this.startDate,
    this.endDate,
    this.clientId,
    this.period, this.minQuantity, this.maxQuantity,
  });

  bool get isActive =>
      productId != null ||
      startDate != null ||
      endDate != null ||
      clientId != null ||
      period != null;

  SaleFilters copyWith({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    String? clientId,
    String? period, int? minQuantity, int? maxQuantity,
  }) => SaleFilters(
    productId: productId ?? this.productId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    clientId: clientId ?? this.clientId,
    period: period ?? this.period,
  );
}

class SaleFiltersNotifier extends StateNotifier<SaleFilters> {
  SaleFiltersNotifier() : super(const SaleFilters());

  void setFilters({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    String? clientId, int? minQuantity, int? maxQuantity,
  }) {
    state = state.copyWith(
      productId: productId,
      startDate: startDate,
      endDate: endDate,
      clientId: clientId,
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

// Filtre dynamique des ventes
final filteredSalesProvider = Provider<List<SaleModel>>((ref) {
  final allSales = ref.watch(salesProvider).valueOrNull ?? [];
  final filters = ref.watch(saleFiltersProvider);

  print('Filtres Ventes actifs: ${filters.isActive}');

  return allSales.where((sale) {
    if (filters.productId != null && sale.productId != filters.productId) {
      return false;
    }
    if (filters.startDate != null &&
        sale.saleDate.isBefore(filters.startDate!)) {
      return false;
    }
    if (filters.endDate != null &&
        sale.saleDate.isAfter(filters.endDate!)) {
      return false;
    }
    if (filters.clientId != null &&
        !(sale.clientId?.toLowerCase().contains(
              filters.clientId!.toLowerCase(),
            ) ??
            false)) {
      return false;
    }
    return true;
  }).toList();
});

// Tab state pour les ventes
final saleTabProvider = StateProvider<int>((ref) => 0);
