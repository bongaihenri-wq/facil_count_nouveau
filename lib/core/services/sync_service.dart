// lib/core/services/sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:facil_count_nouveau/data/local/app_database.dart';
import 'package:facil_count_nouveau/data/local/database_extensions.dart';
import 'package:facil_count_nouveau/data/models/sync_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// 🔥 EXPORTE CES CLASSES pour qu'elles soient accessibles
export 'sync_service.dart' show SyncService, SyncResult, PushResult, ConflictResolution;

// 🔥 CLASSE PRINCIPALE
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  
  bool _isOnline = false;
  bool get isOnline => _isOnline;
  
  final _syncController = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get onSync => _syncController.stream;

  Timer? _autoSyncTimer;

  SyncService(this._db, this._supabase) {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (wasOffline && _isOnline) {
        trySync();
      }
    });

    Connectivity().checkConnectivity().then((r) {
      _isOnline = r != ConnectivityResult.none;
    });

    _autoSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOnline) trySync();
    });
  }

  void dispose() {
    _syncController.close();
    _autoSyncTimer?.cancel();
  }

  Future<SyncResult> trySync() async {
    if (!_isOnline) {
      return SyncResult(
        success: false,
        errors: ['Hors ligne'],
        timestamp: DateTime.now(),
      );
    }

    final result = await _performSync();
    _syncController.add(result);
    return result;
  }

  Future<SyncResult> _performSync() async {
    final timestamp = DateTime.now();
    var result = SyncResult(success: true, timestamp: timestamp);

    try {
      final pushResult = await _pushToSupabase();
      result = result.copyWith(
        pushed: pushResult.pushed,
        conflicts: pushResult.conflicts.length,
        pendingConflicts: pushResult.conflicts,
        errors: pushResult.errors,
      );

      if (!result.needsManualResolution) {
        final pulled = await _pullFromSupabase();
        result = result.copyWith(pulled: pulled);
      }

      return result;
    } catch (e) {
      return result.copyWith(
        success: false,
        errors: [...result.errors, e.toString()],
      );
    }
  }

  Future<PushResult> _pushToSupabase() async {
    final pending = await _db.getPendingEntries();
    final conflicts = <Conflict>[];
    final errors = <String>[];
    int pushed = 0;

    for (final entry in pending) {
      try {
        final item = _entryToItem(entry);
        final conflict = await _processItem(item);

        if (conflict != null) {
          conflicts.add(conflict);
        } else {
          pushed++;
          await _db.markCompleted(entry.id);
        }
      } catch (e) {
        errors.add('${entry.tblName}/${entry.recId}: $e');
        await _db.markFailed(entry.id, e.toString());
      }
    }

    return PushResult(pushed: pushed, conflicts: conflicts, errors: errors);
  }

  Future<Conflict?> _processItem(SyncItem item) async {
    switch (item.conflictStrategy) {
      case ConflictStrategy.appendOnly:
        return await _pushAppendOnly(item);
      case ConflictStrategy.lastWriteWins:
        return await _pushLastWriteWins(item);
      case ConflictStrategy.manualMerge:
        return await _pushWithConflictCheck(item);
    }
  }

  Future<Conflict?> _pushAppendOnly(SyncItem item) async {
    final data = item.data;

    final existing = await _supabase
        .from(item.tblName)
        .select('id')
        .eq('id', item.recId)
        .maybeSingle();

    if (existing != null) {
      return null;
    }

    await _supabase.from(item.tblName).insert(data);
    return null;
  }

  Future<Conflict?> _pushLastWriteWins(SyncItem item) async {
    await _supabase.from(item.tblName).update({
      'stock_quantity': item.data['stock_quantity'],
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', item.recId);

    return null;
  }

  Future<Conflict?> _pushWithConflictCheck(SyncItem item) async {
    final local = item.data;
    final productId = item.recId;

    final remote = await _supabase
        .from('products')
        .select()
        .eq('id', productId)
        .maybeSingle();

    if (remote == null) {
      await _supabase.from('products').insert(local);
      return null;
    }

    final localProduct = await _db.getProduct(productId);
    final remoteUpdated = DateTime.parse(remote['updated_at']);
    final lastSync = localProduct?.lastSyncAt;

    final hasConflict = lastSync == null || remoteUpdated.isAfter(lastSync);

    if (!hasConflict) {
      await _supabase.from('products').upsert(local);
      return null;
    }

    return await _analyzeConflict(item, local, remote);
  }

  Future<Conflict?> _analyzeConflict(
    SyncItem item,
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) async {
    final localTime = DateTime.parse(local['updated_at']);
    final remoteTime = DateTime.parse(remote['updated_at']);

    final priceChanged = local['sale_price'] != remote['sale_price'] ||
                        local['purchase_price'] != remote['purchase_price'];
    final stockChanged = local['stock_quantity'] != remote['stock_quantity'];

    if (priceChanged || stockChanged) {
      await _resolveLastWriteWins(local, remote, localTime, remoteTime);
      return null;
    }

    final nameChanged = local['name'] != remote['name'];
    final descChanged = (local['description'] ?? '') != (remote['description'] ?? '');

    if (nameChanged || descChanged) {
      final field = nameChanged ? 'name' : 'description';
      final localValue = local[field];
      final remoteValue = remote[field];
      final entityName = local['name'] ?? remote['name'] ?? 'Produit';

      final conflict = Conflict(
        id: const Uuid().v4(),
        recId: item.recId,
        entityName: entityName,
        tblName: item.tblName,
        field: field,
        localValue: localValue,
        remoteValue: remoteValue,
        localTime: localTime,
        remoteTime: remoteTime,
        originalOpId: item.id,
        detectedAt: DateTime.now(),
      );

      await _db.queueOperation(
        opType: 'conflict',
        recId: conflict.id,
        tblName: 'conflicts',
        payload: conflict.toJson(),
      );

      await _db.markConflict(item.id);
      return conflict;
    }

    await _supabase.from('products').upsert(local);
    return null;
  }

  Future<void> _resolveLastWriteWins(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
    DateTime localTime,
    DateTime remoteTime,
  ) async {
    if (localTime.isAfter(remoteTime)) {
      await _supabase.from('products').upsert(local);
    } else {
      await _saveRemoteProductToLocal(remote);
    }
  }

  Future<int> _pullFromSupabase() async {
    int count = 0;
    final lastSync = await _db.getLastSyncTime() ?? DateTime(2000);

    final sales = await _supabase
        .from('sales')
        .select()
        .gt('created_at', lastSync.toIso8601String());

    for (final sale in sales) {
      await _saveRemoteSaleToLocal(sale);
      count++;
    }

    final purchases = await _supabase
        .from('purchases')
        .select()
        .gt('created_at', lastSync.toIso8601String());

    for (final purchase in purchases) {
      await _saveRemotePurchaseToLocal(purchase);
      count++;
    }

    final products = await _supabase
        .from('products')
        .select()
        .gt('updated_at', lastSync.toIso8601String());

    for (final product in products) {
      await _syncProductFromRemote(product);
      count++;
    }

    return count;
  }

  Future<void> _syncProductFromRemote(Map<String, dynamic> remote) async {
    final pending = await _db.getPendingEntries();
    final hasPending = pending.any((p) => 
      p.recId == remote['id'] && 
      p.tblName == 'products' &&
      p.status == 'pending'
    );

    if (hasPending) return;

    await _saveRemoteProductToLocal(remote);
  }

  Future<void> _saveRemoteSaleToLocal(Map<String, dynamic> data) async {
    await _db.saveSale(LocalSalesCompanion(
      id: Value(data['id']),
      businessId: Value(data['business_id']),
      saleDate: Value(DateTime.parse(data['sale_date'])),
      totalAmount: Value(data['total_amount'].toDouble()),
      items: Value(jsonEncode(data['items'])),
      isSynced: const Value(true),
      createdAt: Value(DateTime.parse(data['created_at'])),
    ));
  }

  Future<void> _saveRemotePurchaseToLocal(Map<String, dynamic> data) async {
    await _db.savePurchase(LocalPurchasesCompanion(
      id: Value(data['id']),
      businessId: Value(data['business_id']),
      supplierId: Value(data['supplier_id']),
      purchaseDate: Value(DateTime.parse(data['purchase_date'])),
      totalAmount: Value(data['total_amount'].toDouble()),
      items: Value(jsonEncode(data['items'])),
      isSynced: const Value(true),
      createdAt: Value(DateTime.parse(data['created_at'])),
    ));
  }

  Future<void> _saveRemoteProductToLocal(Map<String, dynamic> data) async {
    await _db.saveProduct(LocalProductsCompanion(
      id: Value(data['id']),
      businessId: Value(data['business_id']),
      name: Value(data['name']),
      description: Value(data['description']),
      purchasePrice: Value(data['purchase_price']?.toDouble() ?? 0),
      salePrice: Value(data['sale_price']?.toDouble() ?? 0),
      stockQuantity: Value(data['stock_quantity']?.toDouble() ?? 0),
      unit: Value(data['unit'] ?? 'unité'),
      isSynced: const Value(true),
      lastSyncAt: Value(DateTime.now()),
    ));
  }

  Future<void> resolveConflict({
    required String conflictId,
    required ConflictResolution choice,
    String? mergedValue,
  }) async {
    final entry = await (_db.select(_db.syncQueue)
          ..where((q) => q.id.equals(conflictId)))
        .getSingleOrNull();

    if (entry == null) throw Exception('Conflit introuvable');

    final conflict = Conflict.fromJson(jsonDecode(entry.payload));

    switch (choice) {
      case ConflictResolution.keepLocal:
        final localData = Map<String, dynamic>.from(conflict.localValue is Map 
            ? conflict.localValue 
            : {'name': conflict.localValue});
        localData[conflict.field] = conflict.localValue;
        localData['updated_at'] = DateTime.now().toIso8601String();
        await _supabase.from('products').upsert(localData);
        await _saveRemoteProductToLocal(localData);
        break;

      case ConflictResolution.keepRemote:
        final remoteData = await _supabase
            .from('products')
            .select()
            .eq('id', conflict.recId)
            .single();
        await _saveRemoteProductToLocal(remoteData);
        break;

      case ConflictResolution.merge:
        if (mergedValue == null) throw Exception('Valeur de fusion requise');
        final merged = Map<String, dynamic>.from(conflict.localValue is Map
            ? conflict.localValue
            : {'name': conflict.localValue});
        merged[conflict.field] = mergedValue;
        merged['updated_at'] = DateTime.now().toIso8601String();
        await _supabase.from('products').upsert(merged);
        await _saveRemoteProductToLocal(merged);
        break;
    }

    await _db.deleteEntry(conflictId);
    await _db.markCompleted(conflict.originalOpId);
  }

  SyncItem _entryToItem(SyncQueueData entry) => SyncItem(
    id: entry.id,
    type: SyncOperationType.values.firstWhere((e) => e.name == entry.opType),
    recId: entry.recId,
    tblName: entry.tblName,
    data: jsonDecode(entry.payload),
    createdAt: entry.createdAt,
    syncedAt: entry.syncedAt,
    status: SyncStatus.values.firstWhere((e) => e.name == entry.status),
    errMsg: entry.errMsg,
    retryCount: entry.retryCount,
  );

  Future<List<Conflict>> getPendingConflicts() async {
    final entries = await _db.getConflictEntries();
    return entries
        .where((e) => e.opType == 'conflict')
        .map((e) => Conflict.fromJson(jsonDecode(e.payload)))
        .toList();
  }

  Future<int> getPendingCount() async {
    return await _db.getPendingEntries().then((e) => e.length);
  }

  Future<int> getConflictCount() async {
    return await _db.getConflictEntries().then((e) => e.length);
  }
}

// 🔥 CLASSE SyncResult (doit être dans le même fichier ou importée)
class SyncResult {
  final bool success;
  final int? pushed;
  final int? pulled;
  final int? conflicts;
  final List<Conflict>? pendingConflicts;
  final List<String> errors;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    this.pushed,
    this.pulled,
    this.conflicts,
    this.pendingConflicts,
    this.errors = const [],
    required this.timestamp,
  });

  bool get needsManualResolution => pendingConflicts?.isNotEmpty ?? false;

  SyncResult copyWith({
    bool? success,
    int? pushed,
    int? pulled,
    int? conflicts,
    List<Conflict>? pendingConflicts,
    List<String>? errors,
    DateTime? timestamp,
  }) {
    return SyncResult(
      success: success ?? this.success,
      pushed: pushed ?? this.pushed,
      pulled: pulled ?? this.pulled,
      conflicts: conflicts ?? this.conflicts,
      pendingConflicts: pendingConflicts ?? this.pendingConflicts,
      errors: errors ?? this.errors,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// 🔥 CLASSE PushResult
class PushResult {
  final int pushed;
  final List<Conflict> conflicts;
  final List<String> errors;

  PushResult({
    required this.pushed,
    required this.conflicts,
    required this.errors,
  });
}

// 🔥 ENUM ConflictResolution
enum ConflictResolution {
  keepLocal,
  keepRemote,
  merge,
}