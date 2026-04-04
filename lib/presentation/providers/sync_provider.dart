import 'package:facil_count_nouveau/data/local/database_extensions.dart';
import 'package:facil_count_nouveau/data/models/sync_models.dart' show Conflict;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:facil_count_nouveau/data/local/app_database.dart';
import 'package:facil_count_nouveau/core/services/sync_service.dart';
import 'package:facil_count_nouveau/core/services/sync_queue_manager.dart';

// ==================== PROVIDERS DE BASE ====================

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// ==================== SERVICES ====================

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final service = SyncService(db, supabase);
  
  ref.onDispose(() => service.dispose());
  
  return service;
});

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

// 🔥 CORRECTION : Ajout du point d'interrogation 'SyncResult?' pour autoriser un état de base nul
class SyncNotifier extends StateNotifier<AsyncValue<SyncResult?>> {
  final SyncService _syncService;

  // 🔥 CORRECTION : On initialise avec null proprement, sans forcer le cast 'as SyncResult'
  SyncNotifier(this._syncService) : super(const AsyncValue.data(null));

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

// 🔥 CORRECTION : Mise à jour du type ici aussi et renommage logique en SyncNotifier
final syncStateProvider = StateNotifierProvider<SyncNotifier, AsyncValue<SyncResult?>>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncNotifier(syncService);
});