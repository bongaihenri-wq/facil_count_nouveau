import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/sync_service.dart';
import '../../data/local/app_database.dart';
import '../../data/local/database_extensions.dart';
import '../../data/models/sale_model.dart';

class SyncQueueManager {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final SyncService _syncService;

  SyncQueueManager(this._db, this._supabase, this._syncService);

  /// 🔥🔥🔥 AJOUTE UNE VENTE : Local + Queue + Sync immédiat
  Future<void> queueSale(SaleModel sale) async {
    final now = DateTime.now();

    print('🔥 SyncQueueManager.queueSale() - ID: ${sale.id}');
    print('🔥 businessId: ${sale.businessId}');
    print('🔥 userId: ${sale.userId}');

    // ✅ VALIDATION : Vérifie que les champs critiques sont présents
    if (sale.businessId.isEmpty) {
      throw Exception('businessId requis pour la vente');
    }
    if (sale.userId.isEmpty) {
      throw Exception('userId requis pour la vente');
    }

    // 1. Sauvegarde locale IMMÉDIATE (pour affichage instantané)
    await _saveLocalSale(sale, now);

    // 2. Ajoute à la file d'attente de sync
    await _addToSyncQueue(sale, now);

    // 3. Tente la synchronisation immédiate si online
    try {
      await _syncService.trySync();
    } catch (e) {
      print('⚠️ Sync immédiate échouée, reste en file d\'attente: $e');
      // Pas de throw ici, la vente est déjà sauvegardée localement
    }
  }

  /// Sauvegarde locale avec la structure correcte
  Future<void> _saveLocalSale(SaleModel sale, DateTime now) async {
    await _db.into(_db.localSales).insert(
      LocalSalesCompanion(
        id: Value(sale.id),
        businessId: Value(sale.businessId),
        saleDate: Value(sale.saleDate),
        totalAmount: Value(sale.amount),
        items: Value(jsonEncode([sale.toJson()])), // Stocke la vente complète
        isSynced: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      mode: InsertMode.insertOrReplace,
    );
    print('✅ Vente sauvegardée localement');
  }

  /// Ajoute à la file d'attente de synchronisation
  Future<void> _addToSyncQueue(SaleModel sale, DateTime now) async {
    final id = _generateId();

    // 🔥 PRÉPARE LE PAYLOAD AVEC TOUTES LES DONNÉES NÉCESSAIRES
    final payload = {
      ...sale.toJson(),
      'sync_id': id,
      'queued_at': now.toIso8601String(),
    };

    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        id: Value(id),
        opType: const Value('insert'), // 🔥 'insert' pas 'sale'
        recId: Value(sale.id),
        tblName: const Value('sales'),
        payload: Value(jsonEncode(payload)),
        createdAt: Value(now),
        updatedAt: Value(now),
        status: const Value('pending'),
      ),
    );
    print('✅ Vente ajoutée à la file d\'attente: $id');
  }

  /// Récupère toutes les ventes locales (sync et non-sync)
  Future<List<SaleModel>> getLocalSales(String businessId) async {
    final query = _db.select(_db.localSales)
      ..where((s) => s.businessId.equals(businessId))
      ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]);

    final localSales = await query.get();
    
    print('🔍 SyncQueueManager - Ventes locales trouvées: ${localSales.length}');

    return localSales.expand((sale) {
      try {
        final items = jsonDecode(sale.items) as List<dynamic>;
        return items.map((item) => SaleModel.fromJson(item as Map<String, dynamic>));
      } catch (e) {
        print('❌ Erreur parsing vente locale ${sale.id}: $e');
        return <SaleModel>[];
      }
    }).toList();
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'SYNC_${now}_$rand';
  }
}
