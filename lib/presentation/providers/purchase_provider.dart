// lib/presentation/providers/purchase_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/purchase_model.dart'; 
import '../../data/repositories/purchase_repository.dart'; 
import '../../core/utils/business_helper.dart';
import '/../core/utils/date_filter_helper.dart'; 
import '../screens/purchases/purchase_screen.dart'; 
import '/presentation/screens/dashboard/providers/dashboard_provider.dart';

/// 1. Provider du Repository
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final client = Supabase.instance.client;
  final businessHelper = ref.watch(businessHelperProvider);
  return PurchaseRepository(client, businessHelper, ref);
});

// 2. Provider de la liste brute des achats (Devenu indépendant avec .family) 🟢
final purchasesProvider = FutureProvider.family<List<PurchaseModel>, DateFilterRange>((ref, period) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  
  print('🛰️ Provider Achats - Récupération autonome via .family');
  print('📅 Dates envoyées à Supabase : ${period.start} au ${period.end}');
  
  return repo.getPurchases(
    startDate: period.start,
    endDate: period.end,
  );
});

/// 3. Notifier pour gérer les actions d'écriture (Create, Update, Delete)
class PurchaseNotifier extends StateNotifier<AsyncValue<void>> {
  final PurchaseRepository _repo;

  PurchaseNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> createPurchase({
    required String productId,
    required int quantity,
    required double amount,
    String? supplierId, 
    required DateTime purchaseDate,
    bool paid = true,
    bool locked = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createPurchase(
        productId: productId,
        quantity: quantity,
        amount: amount,
        supplierId: supplierId,
        purchaseDate: purchaseDate,
        paid: paid,
        locked: locked,
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
    String? supplierId,
    required DateTime purchaseDate,
    bool paid = true,
    bool locked = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updatePurchase(
        id: id,
        productId: productId,
        quantity: quantity,
        amount: amount,
        supplierId: supplierId,
        purchaseDate: purchaseDate,
        paid: paid,
        locked: locked,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePurchase(PurchaseModel purchase) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deletePurchase(purchase.id);
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

/// 4. Classe et Notifier pour les filtres secondaires (Hors date)
class PurchaseFilters {
  final String? productId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? supplierId; 
  final String? period;
  final int? minQuantity;
  final int? maxQuantity;

  const PurchaseFilters({
    this.productId,
    this.startDate,
    this.endDate,
    this.supplierId,
    this.period, 
    this.minQuantity, 
    this.maxQuantity,
  });

  bool get isActive =>
      productId != null ||
      startDate != null ||
      endDate != null ||
      supplierId != null ||
      period != null;

  PurchaseFilters copyWith({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    String? supplierId,
    String? period, 
    int? minQuantity, 
    int? maxQuantity,
  }) => PurchaseFilters(
    productId: productId ?? this.productId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    supplierId: supplierId ?? this.supplierId,
    period: period ?? this.period,
    minQuantity: minQuantity ?? this.minQuantity,
    maxQuantity: maxQuantity ?? this.maxQuantity,
  );
}

class PurchaseFiltersNotifier extends StateNotifier<PurchaseFilters> {
  PurchaseFiltersNotifier() : super(const PurchaseFilters());

  void setFilters({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    String? supplierId, 
    int? minQuantity, 
    int? maxQuantity,
  }) {
    state = state.copyWith(
      productId: productId,
      startDate: startDate,
      endDate: endDate,
      supplierId: supplierId,
      minQuantity: minQuantity,
      maxQuantity: maxQuantity,
    );
  }

  void clearFilters() => state = const PurchaseFilters();
}

final purchaseFiltersProvider =
    StateNotifierProvider<PurchaseFiltersNotifier, PurchaseFilters>((ref) {
      return PurchaseFiltersNotifier();
    });

/// 5. Le Provider dérivé qui applique les filtres en mémoire (Fournisseurs, Produits...) 🟢
final filteredPurchasesProvider = Provider<List<PurchaseModel>>((ref) {
  // 1. On écoute la période PROPRE à l'écran des achats
  final currentPurchasePeriod = ref.watch(selectedPurchasePeriodProvider);

  // 2. On passe cette période au provider brut avec .family
  final allPurchases = ref.watch(purchasesProvider(currentPurchasePeriod)).valueOrNull ?? [];
  final filters = ref.watch(purchaseFiltersProvider);

  print('Filtres Achats actifs: ${filters.isActive}');

  // Si aucun filtre secondaire n'est coché, on renvoie la liste filtrée uniquement par date
  if (!filters.isActive) {
    return allPurchases;
  }

  return allPurchases.where((purchase) {
    if (filters.productId != null && purchase.productId != filters.productId) {
      return false;
    }
    
    if (filters.supplierId != null &&
        !(purchase.supplier?.toLowerCase().contains(
              filters.supplierId!.toLowerCase(),
            ) ??
            false)) {
      return false;
    }
    return true;
  }).toList();
});

/// 6. Tab state pour naviguer entre Liste et Dashboard
final purchaseTabProvider = StateProvider<int>((ref) => 0);
