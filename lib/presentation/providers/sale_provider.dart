// lib/presentation/providers/sale_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/sale_model.dart'; 
import '../../data/repositories/sale_repository.dart'; 
import '../../core/utils/business_helper.dart';
import '../../core/utils/date_filter_helper.dart'; 
import '../screens/sales/sale_screen.dart';
import '/presentation/screens/dashboard/providers/dashboard_provider.dart';

/// 1. Provider du Repository
final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final client = Supabase.instance.client;
  final businessHelper = ref.watch(businessHelperProvider);
  return SaleRepository(client, businessHelper, ref);
});

// 2. Provider de la liste brute des ventes (Devenu indépendant grâce à .family !) 🟢
// On lui passe un objet DateFilter (qui contient un .start et un .end)
final salesProvider = FutureProvider.family<List<SaleModel>, DateFilterRange>((ref, period) async {
  final repo = ref.watch(saleRepositoryProvider);
  
  print('🛰️ Provider Ventes - Récupération autonome via .family');
  print('📅 Dates envoyées à Supabase : ${period.start} au ${period.end}');
  
  return repo.getSales(
    startDate: period.start,
    endDate: period.end,
  );
});

/// 3. Notifier pour gérer les actions d'écriture (Create, Update, Delete)
class SaleNotifier extends StateNotifier<AsyncValue<void>> {
  final SaleRepository _repo;

  SaleNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> createSale({
    required String productId,
    required int quantity,
    required double amount,
    String? clientId, 
    required DateTime saleDate,
    bool isPaid = true, 
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

/// 4. Classe et Notifier pour les filtres secondaires (Hors date)
class SaleFilters {
  final String? productId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? clientId; 
  final String? period;
  final int? minQuantity;
  final int? maxQuantity;

  const SaleFilters({
    this.productId,
    this.startDate,
    this.endDate,
    this.clientId,
    this.period, 
    this.minQuantity, 
    this.maxQuantity,
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
    String? period, 
    int? minQuantity, 
    int? maxQuantity,
  }) => SaleFilters(
    productId: productId ?? this.productId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    clientId: clientId ?? this.clientId,
    period: period ?? this.period,
    minQuantity: minQuantity ?? this.minQuantity,
    maxQuantity: maxQuantity ?? this.maxQuantity,
  );
}

class SaleFiltersNotifier extends StateNotifier<SaleFilters> {
  SaleFiltersNotifier() : super(const SaleFilters());

  void setFilters({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    String? clientId, 
    int? minQuantity, 
    int? maxQuantity,
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

/// 5. Le Provider dérivé qui applique les filtres en mémoire (Clients, Produits...) 🟢
final filteredSalesProvider = Provider<List<SaleModel>>((ref) {
  // 1. On écoute la période PROPRE à l'écran des ventes
  final currentSalePeriod = ref.watch(selectedSalePeriodProvider);
  
  // 2. On passe cette période au provider brut avec .family
  final allSales = ref.watch(salesProvider(currentSalePeriod)).valueOrNull ?? [];
  final filters = ref.watch(saleFiltersProvider);

  print('Filtres Ventes actifs: ${filters.isActive}');

  // Si aucun filtre secondaire n'est coché, on renvoie la liste filtrée uniquement par date
  if (!filters.isActive) {
    return allSales;
  }

  return allSales.where((sale) {
    if (filters.productId != null && sale.productId != filters.productId) {
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

/// 6. Tab state pour naviguer entre Liste et Dashboard
final saleTabProvider = StateProvider<int>((ref) => 0);
