import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import '../../core/utils/business_helper.dart';
import '../../core/services/sync_queue_manager.dart';

class SaleRepository {
  final SupabaseClient _client;
  final BusinessHelper _businessHelper;
  final SyncQueueManager? _syncManager; // 🔥 AJOUTÉ

  SaleRepository(this._client, this._businessHelper, {SyncQueueManager? syncManager})
      : _syncManager = syncManager;

  Future<List<SaleModel>> getSales() async {
    final businessId = await _businessHelper.getBusinessId();
    print('🔍 SaleRepository.getSales() - filtre business_id: $businessId');

    if (businessId.isEmpty) {
      print('❌ ERREUR: business_id est vide !');
      return [];
    }

    try {
      // 🔥 RÉCUPÈRE D'ABORD LES VENTES LOCALES (non sync)
      final localSales = await _syncManager?.getLocalSales(businessId) ?? [];
      print('🔍 Ventes locales: ${localSales.length}');

      // 🔥 RÉCUPÈRE LES VENTES SUPABASE
      final data = await _client
          .from('sales')
          .select('*, products(name), clients(name)')
          .eq('business_id', businessId)
          .order('sale_date', ascending: false);

      print('🔍 Données brutes Supabase : $data');
      print('🔍 Nombre de ventes Supabase : ${data.length}');

      // 🔥 MERGE LES DEUX LISTES (local + remote)
      final remoteSales = (data as List).map((json) => SaleModel.fromJson(json)).toList();
      
      // Évite les doublons (par ID)
      final allSales = <String, SaleModel>{};
      for (var sale in remoteSales) {
        allSales[sale.id] = sale;
      }
      for (var sale in localSales) {
        if (!allSales.containsKey(sale.id)) {
          allSales[sale.id] = sale;
        }
      }

      final result = allSales.values.toList()
        ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

      print('✅ Total ventes (local + remote): ${result.length}');
      return result;
    } catch (e, stackTrace) {
      print('❌ Erreur lors de getSales(): $e');
      print(stackTrace);
      // 🔥 EN CAS D'ERREUR, RETOURNE AU MOINS LES LOCALES
      return await _syncManager?.getLocalSales(businessId) ?? [];
    }
  }

  Future<SaleModel> createSale({
    required String productId,
    required int quantity,
    required double amount,
    String? clientId,
    required DateTime saleDate,
  }) async {
    final businessId = await _businessHelper.getBusinessId();
    final userId = _client.auth.currentUser?.id;
    
    print('🔍 SaleRepository.createSale() - business_id: $businessId');
    print('🔍 SaleRepository.createSale() - user_id: $userId');

    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // 🔥 CRÉE LE MODÈLE COMPLET AVEC TOUTES LES DONNÉES
    final sale = SaleModel(
      id: const Uuid().v4(),
      businessId: businessId, // 🔥 REQUIS
      userId: userId, // 🔥 AJOUTÉ - CRITIQUE POUR RLS
      productId: productId,
      quantity: quantity,
      amount: amount,
      clientId: clientId,
      saleDate: saleDate,
      paid: true,
      locked: false,
      createdAt: DateTime.now(),
    );

    print('🔍 Sale créée: ${sale.toJson()}');

    // 🔥🔥🔥 STRATÉGIE : Sauvegarde locale + tentative sync immédiate
    if (_syncManager != null) {
      // Mode avec gestion offline : passe par le queue manager
      await _syncManager.queueSale(sale);
      print('✅ Vente mise en file d\'attente (offline capable)');
    } else {
      // Mode direct (fallback) : insertion immédiate
      await _insertDirectToSupabase(sale);
      print('✅ Vente insérée directement');
    }

    return sale;
  }

  // 🔥 MÉTHODE PRIVÉE pour insertion directe (fallback)
  Future<void> _insertDirectToSupabase(SaleModel sale) async {
    try {
      final data = await _client
          .from('sales')
          .insert(sale.toJson())
          .select('*, products(name), clients(name)')
          .single();

      print('✅ Vente insérée directement: ${data['id']}');
    } catch (e, stackTrace) {
      print('❌ ERREUR INSERTION DIRECTE: $e');
      print(stackTrace);
      throw Exception('Échec insertion vente: $e');
    }
  }

  Future<SaleModel> updateSale({...}) async { /* ... même logique ... */ }
  Future<void> deleteSale(...) async { /* ... même logique ... */ }
}