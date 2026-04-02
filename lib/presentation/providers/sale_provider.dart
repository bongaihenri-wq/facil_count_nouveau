import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/sale_repository.dart';
import '../../core/utils/business_helper.dart';
import '../../core/services/sync_queue_manager.dart';
import '../../core/services/sync_service.dart';
import '../../data/local/app_database.dart';

// 🔥 PROVIDERS DE SERVICES (à ajouter si pas déjà présents)

final databaseProvider = Provider<AppDatabase>((ref) {
  // Retourne ton instance d'AppDatabase (Drift)
  return AppDatabase(); // Adapte selon ta configuration
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = Supabase.instance.client;
  return SyncService(db, supabase);
});

final syncQueueManagerProvider = Provider<SyncQueueManager>((ref) {
  final db = ref.watch(databaseProvider);
  final supabase = Supabase.instance.client;
  final syncService = ref.watch(syncServiceProvider);
  return SyncQueueManager(db, supabase, syncService);
});

// 🔥 MODIFIÉ : SaleRepository avec SyncQueueManager injecté
final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final client = Supabase.instance.client;
  final businessHelper = ref.watch(businessHelperProvider);
  final syncManager = ref.watch(syncQueueManagerProvider); // 🔥 AJOUTÉ
  
  return SaleRepository(
    client, 
    businessHelper, 
    syncManager: syncManager, // 🔥 AJOUTÉ
  );
});

// 🔥 Sales list - avec gestion du cache et retry
final salesProvider = FutureProvider<List<SaleModel>>((ref) async {
  final repo = ref.watch(saleRepositoryProvider);
  
  try {
    final sales = await repo.getSales();
    print('✅ salesProvider: ${sales.length} ventes trouvées');
    return sales;
  } catch (e, stackTrace) {
    print('❌ salesProvider - Erreur: $e');
    print(stackTrace);
    // 🔥 EN CAS D'ERREUR, RETOURNE UNE LISTE VIDE AU LIEU DE CRASHER
    return [];
  }
});

// 🔥 AJOUTÉ : Provider pour forcer le refresh manuel
final salesRefreshProvider = StateProvider<int>((ref) => 0);

// 🔥 AJOUTÉ : Provider de sales avec refresh capability
final salesWithRefreshProvider = FutureProvider<List<SaleModel>>((ref) async {
  // Écoute le refresh provider pour forcer le rebuild
  ref.watch(salesRefreshProvider);
  
  final repo = ref.watch(saleRepositoryProvider);
  
  try {
    final sales = await repo.getSales();
    print('✅ salesWithRefreshProvider: ${sales.length} ventes trouvées');
    return sales;
  } catch (e, stackTrace) {
    print('❌ salesWithRefreshProvider - Erreur: $e');
    print(stackTrace);
    return [];
  }
});

// Filtres (inchangé)
class SaleFilters {
  final String? productId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minQuantity;
  final int? maxQuantity;
  final String? period;

  const SaleFilters({
    this.productId,
    this.startDate,
    this.endDate,
    this.minQuantity,
    this.maxQuantity,
    this.period,
  });

  bool get isActive =>
      productId != null ||
      startDate != null ||
      endDate != null ||
      minQuantity != null ||
      maxQuantity != null ||
      period != null;

  SaleFilters copyWith({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    int? minQuantity,
    int? maxQuantity,
    String? period,
  }) => SaleFilters(
    productId: productId ?? this.productId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    minQuantity: minQuantity ?? this.minQuantity,
    maxQuantity: maxQuantity ?? this.maxQuantity,
    period: period ?? this.period,
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
    String? period,
  }) {
    state = state.copyWith(
      productId: productId,
      startDate: startDate,
      endDate: endDate,
      minQuantity: minQuantity,
      maxQuantity: maxQuantity,
      period: period,
    );
  }

  void clearFilters() => state = const SaleFilters();
}

final saleFiltersProvider = StateNotifierProvider<SaleFiltersNotifier, SaleFilters>((ref) {
  return SaleFiltersNotifier();
});

// 🔥 MODIFIÉ : Liste filtrée avec meilleure gestion d'erreur
final filteredSalesProvider = Provider<List<SaleModel>>((ref) {
  final allSalesAsync = ref.watch(salesProvider);
  final filters = ref.watch(saleFiltersProvider);

  print('Filtres actifs: ${filters.isActive}');

  // 🔥 Gère les états de loading/error
  final allSales = allSalesAsync.when(
    data: (sales) => sales,
    loading: () => <SaleModel>[],
    error: (err, stack) {
      print('❌ filteredSalesProvider - Erreur: $err');
      return <SaleModel>[];
    },
  );

  return allSales.where((sale) {
    if (filters.productId != null && sale.productId != filters.productId) {
      return false;
    }
    if (filters.startDate != null && sale.saleDate.isBefore(filters.startDate!)) {
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

// Tab state (inchangé)
final saleTabProvider = StateProvider<int>((ref) => 0);

// 🔥 MODIFIÉ : SaleNotifier avec gestion d'erreur améliorée et refresh forcé
class SaleNotifier extends StateNotifier<AsyncValue<void>> {
  final SaleRepository _repo;
  final Ref _ref;

  SaleNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> createSale({
    required String productId,
    required int quantity,
    required double amount,
    String? clientId,
    required DateTime saleDate,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      print('🔥 SaleNotifier.createSale() - Début');
      
      final sale = await _repo.createSale(
        productId: productId,
        quantity: quantity,
        amount: amount,
        clientId: clientId,
        saleDate: saleDate,
      );
      
      print('🔥 SaleNotifier - Vente créée: ${sale.id}');
      print('🔥 SaleNotifier - BusinessId: ${sale.businessId}');
      print('🔥 SaleNotifier - UserId: ${sale.userId}');

      // 🔥 INVALIDATION MULTIPLE ET FORCÉE
      _invalidateSalesProviders();
      
      // 🔥 ATTENDRE QUE LA SYNC SE FASSE (petit délai)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 🔥 RE-INVALIDATION APRÈS DÉLAI
      _invalidateSalesProviders();

      state = const AsyncValue.data(null);
      print('✅ Vente créée et liste rafraîchie');

    } catch (e, stackTrace) {
      print('❌❌❌ SaleNotifier.createSale() - ERREUR: $e');
      print(stackTrace);
      state = AsyncValue.error(e, stackTrace);
      // 🔥 RE-THROW pour que l'UI puisse afficher l'erreur
      throw e;
    }
  }

  Future<void> updateSale({
    required String id,
    required String productId,
    required int quantity,
    required double amount,
    String? clientId,
    required DateTime saleDate,
    required bool paid,
    required bool locked,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      print('🔥 SaleNotifier.updateSale() - ID: $id');
      
      await _repo.updateSale(
        id: id,
        productId: productId,
        quantity: quantity,
        amount: amount,
        clientId: clientId,
        saleDate: saleDate,
        paid: paid,
        locked: locked,
      );
      
      _invalidateSalesProviders();
      
      state = const AsyncValue.data(null);
      print('✅ Vente modifiée');

    } catch (e, stackTrace) {
      print('❌ SaleNotifier.updateSale() - ERREUR: $e');
      print(stackTrace);
      state = AsyncValue.error(e, stackTrace);
      throw e;
    }
  }

  Future<void> deleteSale(SaleModel sale) async {
    state = const AsyncValue.loading();
    
    try {
      print('🔥 SaleNotifier.deleteSale() - ID: ${sale.id}');
      
      await _repo.deleteSale(sale.id, sale.productId, sale.quantity);
      
      _invalidateSalesProviders();
      
      state = const AsyncValue.data(null);
      print('✅ Vente supprimée');

    } catch (e, stackTrace) {
      print('❌ SaleNotifier.deleteSale() - ERREUR: $e');
      print(stackTrace);
      state = AsyncValue.error(e, stackTrace);
      throw e;
    }
  }

  // 🔥 NOUVELLE MÉTHODE : Forcer le refresh manuel
  void forceRefresh() {
    print('🔥 SaleNotifier.forceRefresh()');
    _invalidateSalesProviders();
  }

  // 🔥 MÉTHODE PRIVÉE : Centralise l'invalidation
  void _invalidateSalesProviders() {
    print('🔥 Invalidation des providers...');
    
    // Invalide le provider principal
    _ref.invalidate(salesProvider);
    
    // Incrémente le refresh provider pour forcer le rebuild
    final currentRefresh = _ref.read(salesRefreshProvider);
    _ref.read(salesRefreshProvider.notifier).state = currentRefresh + 1;
    
    // Invalide aussi les autres providers liés
    _ref.invalidate(filteredSalesProvider);
  }
}

final saleNotifierProvider = StateNotifierProvider<SaleNotifier, AsyncValue<void>>((ref) {
  return SaleNotifier(ref.watch(saleRepositoryProvider), ref);
});

// 🔥 AJOUTÉ : Provider pour le statut de synchronisation
final syncStatusProvider = StreamProvider<SyncResult>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.onSync;
});

// 🔥 AJOUTÉ : Provider pour le nombre de ventes en attente
final pendingSalesCountProvider = FutureProvider<int>((ref) async {
  final syncManager = ref.watch(syncQueueManagerProvider);
  // Tu peux ajouter une méthode dans SyncQueueManager pour compter
  return 0; // À implémenter selon tes besoins
});