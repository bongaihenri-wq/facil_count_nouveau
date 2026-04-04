import 'dart:convert';
import 'package:drift/drift.dart';
import 'app_database.dart';

// ==================== SALES EXTENSIONS ====================

extension SaleQueries on AppDatabase {
  Future<List<LocalSale>> getAllSales(String businessId) async {
    return await (select(localSales)
          ..where((s) => s.businessId.equals(businessId))
          ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]))
        .get();
  }

  Future<LocalSale?> getSale(String id) async {
    return await (select(localSales)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> saveSale(LocalSalesCompanion sale) async {
    await into(localSales).insertOnConflictUpdate(sale);
  }

  Future<void> markSaleSynced(String id) async {
    await (update(localSales)..where((s) => s.id.equals(id)))
        .write(const LocalSalesCompanion(isSynced: Value(true)));
  }

  Stream<List<LocalSale>> watchSales(String businessId) {
    return (select(localSales)
          ..where((s) => s.businessId.equals(businessId))
          ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]))
        .watch();
  }
}

// ==================== PURCHASES EXTENSIONS ====================

extension PurchaseQueries on AppDatabase {
  Future<List<LocalPurchase>> getAllPurchases(String businessId) async {
    return await (select(localPurchases)
          ..where((p) => p.businessId.equals(businessId))
          ..orderBy([(p) => OrderingTerm.desc(p.purchaseDate)]))
        .get();
  }

  Future<void> savePurchase(LocalPurchasesCompanion purchase) async {
    await into(localPurchases).insertOnConflictUpdate(purchase);
  }

  Future<void> markPurchaseSynced(String id) async {
    await (update(localPurchases)..where((p) => p.id.equals(id)))
        .write(const LocalPurchasesCompanion(isSynced: Value(true)));
  }

  Stream<List<LocalPurchase>> watchPurchases(String businessId) {
    return (select(localPurchases)
          ..where((p) => p.businessId.equals(businessId))
          ..orderBy([(p) => OrderingTerm.desc(p.purchaseDate)]))
        .watch();
  }
}

// ==================== PRODUCTS EXTENSIONS ====================

extension ProductQueries on AppDatabase {
  Future<List<LocalProduct>> getAllProducts(String businessId) async {
    return await (select(localProducts)
          ..where((p) => p.businessId.equals(businessId))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  Future<LocalProduct?> getProduct(String id) async {
    return await (select(localProducts)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> saveProduct(LocalProductsCompanion product) async {
    await into(localProducts).insertOnConflictUpdate(product);
  }

  Future<void> updateProductStock(String id, double quantity) async {
    await (update(localProducts)..where((p) => p.id.equals(id)))
        .write(LocalProductsCompanion(
          stockQuantity: Value(quantity),
          isSynced: const Value(false),
          updatedAt: Value(DateTime.now()), // ✅ AJOUTÉ
        ));
  }

  Future<void> markProductSynced(String id, DateTime syncTime) async {
    await (update(localProducts)..where((p) => p.id.equals(id)))
        .write(LocalProductsCompanion(
          isSynced: const Value(true),
          lastSyncAt: Value(syncTime),
          updatedAt: Value(DateTime.now()), // ✅ AJOUTÉ
        ));
  }

  Stream<List<LocalProduct>> watchProducts(String businessId) {
    return (select(localProducts)
          ..where((p) => p.businessId.equals(businessId))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Stream<LocalProduct?> watchProduct(String id) {
    return (select(localProducts)..where((p) => p.id.equals(id)))
        .watchSingleOrNull();
  }
}

// ==================== STOCK EXTENSIONS ====================

extension StockQueries on AppDatabase {
  Future<void> updateStock(String productId, double quantity) async {
    await (update(localProducts)..where((p) => p.id.equals(productId)))
        .write(LocalProductsCompanion(
          stockQuantity: Value(quantity),
          isSynced: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
  }
}

// ==================== SYNC QUEUE EXTENSIONS ====================

extension SyncQueueQueries on AppDatabase {
  Future<List<SyncQueueData>> getPendingEntries() async {
    return await (select(syncQueue)
          ..where((q) => q.status.equals('pending'))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  Future<List<SyncQueueData>> getFailedEntries() async {
    return await (select(syncQueue)
          ..where((q) => q.status.equals('failed') & q.retryCount.isSmallerThanValue(5))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  Future<List<SyncQueueData>> getConflictEntries() async {
    return await (select(syncQueue)
          ..where((q) => q.status.equals('conflict')))
        .get();
  }

  Future<SyncQueueData?> getEntry(String id) async {
    return await (select(syncQueue)..where((q) => q.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> queueOperation({
    required String opType,
    required String recId,
    required String tblName,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now();
    await into(syncQueue).insert(
      SyncQueueCompanion(
        id: Value(generateId()),
        opType: Value(opType),
        recId: Value(recId),
        tblName: Value(tblName),
        payload: Value(jsonEncode(payload)),
        status: const Value('pending'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markCompleted(String id) async {
    await (update(syncQueue)..where((q) => q.id.equals(id)))
        .write(SyncQueueCompanion(
          status: const Value('completed'),
          syncedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> markFailed(String id, String error) async {
    final entry = await getEntry(id);
    if (entry == null) return;

    final newCount = entry.retryCount + 1;
    final newStatus = newCount >= 5 ? 'failed' : 'pending';

    await (update(syncQueue)..where((q) => q.id.equals(id)))
        .write(SyncQueueCompanion(
          status: Value(newStatus),
          errMsg: Value(error),
          retryCount: Value(newCount),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> markConflict(String id) async {
    await (update(syncQueue)..where((q) => q.id.equals(id)))
        .write(SyncQueueCompanion(
          status: const Value('conflict'),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> deleteEntry(String id) async {
    await (delete(syncQueue)..where((q) => q.id.equals(id))).go();
  }

  Future<DateTime?> getLastSyncTime() async {
    final last = await (select(syncQueue)
          ..where((q) => q.status.equals('completed') & q.syncedAt.isNotNull())
          ..orderBy([(q) => OrderingTerm.desc(q.syncedAt)])
          ..limit(1))
        .getSingleOrNull();
    return last?.syncedAt;
  }

  Stream<int> watchPendingCount() {
    return (select(syncQueue)..where((q) => q.status.equals('pending')))
        .watch()
        .map((list) => list.length);
  }

  Stream<int> watchConflictCount() {
    return (select(syncQueue)..where((q) => q.status.equals('conflict')))
        .watch()
        .map((list) => list.length);
  }

  Future<SyncQueueData?> getPendingEntry(String recId, String tblName) async {
    return await (select(syncQueue)
          ..where((q) => q.recId.equals(recId) & 
                        q.tblName.equals(tblName) & 
                        q.status.equals('pending')))
        .getSingleOrNull();
  }
}