import 'package:facil_count_nouveau/data/local/database_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:facil_count_nouveau/data/local/app_database.dart';
import 'package:facil_count_nouveau/data/models/sync_models.dart';
import 'package:facil_count_nouveau/core/services/sync_service.dart';
import 'package:facil_count_nouveau/core/services/sync_queue_manager.dart';

// ==================== PROVIDERS DE BASE ====================

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// ==================== SERVICES ====================

// ✅ SyncService prend AppDatabase ET SupabaseClient
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final service = SyncService(db, supabase);
  
  ref.onDispose(() => service.dispose());
  
  return service;
});

// ✅ CORRIGÉ : SyncQueueManager prend AppDatabase, SupabaseClient ET SyncService
final syncQueueManagerProvider = Provider<SyncQueueManager>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final syncService = ref.watch(syncServiceProvider);
  return SyncQueueManager(db, supabase, syncService);
});

// ==================== ÉTATS ====================

final connectivityProvider = StreamProvider<bool>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return Stream.periodic(const Duration(seconds: 5))
      .map((_) => syncService.isOnline);
});

final pendingCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchPendingCount();
});

final conflictCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchConflictCount();
});

final pendingConflictsProvider = FutureProvider<List<Conflict>>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getPendingConflicts();
});

// ==================== NOTIFIER ====================

// 🔥 CORRIGÉ : Typage non-nullable
class SyncState extends StateNotifier<AsyncValue<SyncResult>> {
  final SyncService _syncService;

  SyncState(this._syncService) : super(const AsyncValue.data(null as SyncResult));

  Future<void> sync() async {
    state = const AsyncValue.loading();
    try {
      final result = await _syncService.trySync();
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resolveConflict({
    required String conflictId,
    required ConflictResolution resolution,
    String? mergedValue,
  }) async {
    try {
      await _syncService.resolveConflict(
        conflictId: conflictId,
        choice: resolution,
        mergedValue: mergedValue,
      );
      await sync();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 🔥 CORRIGÉ : Typage non-nullable
final syncStateProvider = StateNotifierProvider<SyncState, AsyncValue<SyncResult>>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncState(syncService);
});