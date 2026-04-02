import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/sync_service.dart';
import '../../data/local/app_database.dart';
import '../../data/local/database_extensions.dart';

class SyncQueueManager {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final SyncService _syncService;

  SyncQueueManager(this._db, this._supabase, this._syncService);

  /// Ajoute une vente à la file d'attente
  Future<void> queueSale(Map<String, dynamic> saleData) async {
    final now = DateTime.now();
    final id = _generateId();

    // Sauvegarde locale immédiate
    await _db.into(_db.localSales).insert(
      LocalSalesCompanion(
        id: Value(saleData['id']),
        businessId: Value(saleData['business_id']),
        saleDate: Value(DateTime.parse(saleData['sale_date'])),
        totalAmount: Value(saleData['total_amount'].toDouble()),
        items: Value(jsonEncode(saleData['items'])),
        isSynced: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      mode: InsertMode.insertOrReplace,
    );

    // Ajoute à la file d'attente
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        id: Value(id),
        opType: const Value('sale'),
        recId: Value(saleData['id']),
        tblName: const Value('sales'),
        payload: Value(jsonEncode(saleData)),
        createdAt: Value(now),
        updatedAt: Value(now),
        status: const Value('pending'),
      ),
    );

    // Tente sync immédiate si online
    await _syncService.trySync();
  }

  /// Ajoute un achat à la file d'attente
  Future<void> queuePurchase(Map<String, dynamic> purchaseData) async {
    final now = DateTime.now();
    final id = _generateId();

    // Sauvegarde locale
    await _db.into(_db.localPurchases).insert(
      LocalPurchasesCompanion(
        id: Value(purchaseData['id']),
        businessId: Value(purchaseData['business_id']),
        supplierId: Value(purchaseData['supplier_id']),
        purchaseDate: Value(DateTime.parse(purchaseData['purchase_date'])),
        totalAmount: Value(purchaseData['total_amount'].toDouble()),
        items: Value(jsonEncode(purchaseData['items'])),
        isSynced: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      mode: InsertMode.insertOrReplace,
    );

    // Ajoute à la file d'attente
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        id: Value(id),
        opType: const Value('purchase'),
        recId: Value(purchaseData['id']),
        tblName: const Value('purchases'),
        payload: Value(jsonEncode(purchaseData)),
        createdAt: Value(now),
        updatedAt: Value(now),
        status: const Value('pending'),
      ),
    );

    await _syncService.trySync();
  }

  /// Ajoute un produit à la file d'attente
  Future<void> queueProduct(Map<String, dynamic> productData) async {
    final now = DateTime.now();
    final id = _generateId();

    // Sauvegarde locale
    await _db.into(_db.localProducts).insert(
      LocalProductsCompanion(
        id: Value(productData['id']),
        businessId: Value(productData['business_id']),
        name: Value(productData['name']),
        description: Value(productData['description']),
        purchasePrice: Value(productData['purchase_price'].toDouble()),
        salePrice: Value(productData['sale_price'].toDouble()),
        stockQuantity: Value(productData['stock_quantity'].toDouble()),
        unit: Value(productData['unit'] ?? 'unité'),
        isSynced: const Value(false),
        lastSyncAt: const Value.absent(),
        updatedAt: Value(now),
      ),
      mode: InsertMode.insertOrReplace,
    );

    // Ajoute à la file d'attente
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        id: Value(id),
        opType: const Value('product'),
        recId: Value(productData['id']),
        tblName: const Value('products'),
        payload: Value(jsonEncode(productData)),
        createdAt: Value(now),
        updatedAt: Value(now),
        status: const Value('pending'),
      ),
    );

    await _syncService.trySync();
  }

  /// Ajoute un ajustement de stock à la file d'attente
  Future<void> queueStockAdjustment(String productId, double newQuantity) async {
    final now = DateTime.now();
    final id = _generateId();

    // Update local
    await _db.updateStock(productId, newQuantity);

    // Ajoute à la file d'attente
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        id: Value(id),
        opType: const Value('stock'),
        recId: Value(productId),
        tblName: const Value('products'),
        payload: Value(jsonEncode({
          'id': productId,
          'stock_quantity': newQuantity,
          'updated_at': now.toIso8601String(),
        })),
        createdAt: Value(now),
        updatedAt: Value(now),
        status: const Value('pending'),
      ),
    );

    await _syncService.trySync();
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'SYNC_${now}_$rand';
  }
}