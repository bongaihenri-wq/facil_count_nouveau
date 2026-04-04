import 'package:drift/drift.dart';

// ==================== ENUMS ====================

enum SyncOperationType {
  sale,
  purchase,
  product,
  stock,
}

enum SyncStatus {
  pending,
  syncing,
  completed,
  failed,
  conflict,
}

enum ConflictStrategy {
  appendOnly,
  lastWriteWins,
  manualMerge,
}

// ==================== SYNC ITEM ====================

class SyncItem {
  final String id;
  final SyncOperationType type;
  final String recId;        // ✅ RENOMMÉ: entityId → recId
  final String tblName;      // ✅ RENOMMÉ: tableName → tblName
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final SyncStatus status;
  final String? errMsg;      // ✅ RENOMMÉ: errorMessage → errMsg
  final int retryCount;

  SyncItem({
    required this.id,
    required this.type,
    required this.recId,
    required this.tblName,
    required this.data,
    required this.createdAt,
    this.syncedAt,
    this.status = SyncStatus.pending,
    this.errMsg,
    this.retryCount = 0,
  });

  bool get isAppendOnly => 
      type == SyncOperationType.sale || type == SyncOperationType.purchase;
  
  bool get isLastWriteWins => type == SyncOperationType.stock;
  
  bool get needsConflictCheck => type == SyncOperationType.product;

  ConflictStrategy get conflictStrategy {
    switch (type) {
      case SyncOperationType.sale:
      case SyncOperationType.purchase:
        return ConflictStrategy.appendOnly;
      case SyncOperationType.stock:
        return ConflictStrategy.lastWriteWins;
      case SyncOperationType.product:
        return ConflictStrategy.manualMerge;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'rec_id': recId,
    'tbl_name': tblName,
    'data': data,
    'created_at': createdAt.toIso8601String(),
    'synced_at': syncedAt?.toIso8601String(),
    'status': status.name,
    'err_msg': errMsg,
    'retry_count': retryCount,
  };

  factory SyncItem.fromJson(Map<String, dynamic> json) => SyncItem(
    id: json['id'],
    type: SyncOperationType.values.firstWhere((e) => e.name == json['type']),
    recId: json['rec_id'],
    tblName: json['tbl_name'],
    data: json['data'],
    createdAt: DateTime.parse(json['created_at']),
    syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at']) : null,
    status: SyncStatus.values.firstWhere((e) => e.name == json['status']),
    errMsg: json['err_msg'],
    retryCount: json['retry_count'] ?? 0,
  );

  SyncItem copyWith({
    SyncStatus? status,
    DateTime? syncedAt,
    String? errMsg,
    int? retryCount,
  }) => SyncItem(
    id: id,
    type: type,
    recId: recId,
    tblName: tblName,
    data: data,
    createdAt: createdAt,
    syncedAt: syncedAt ?? this.syncedAt,
    status: status ?? this.status,
    errMsg: errMsg ?? this.errMsg,
    retryCount: retryCount ?? this.retryCount,
  );
}

// ==================== CONFLICT ====================

class Conflict {
  final String id;
  final String recId;           // ✅ RENOMMÉ: entityId → recId
  final String entityName;
  final String tblName;         // ✅ RENOMMÉ: tableName → tblName
  final String field;
  final dynamic localValue;
  final dynamic remoteValue;
  final DateTime localTime;
  final DateTime remoteTime;
  final String originalOpId;
  final DateTime detectedAt;

  Conflict({
    required this.id,
    required this.recId,
    required this.entityName,
    required this.tblName,
    required this.field,
    required this.localValue,
    required this.remoteValue,
    required this.localTime,
    required this.remoteTime,
    required this.originalOpId,
    required this.detectedAt,
  });

  bool get isLocalNewer => localTime.isAfter(remoteTime);

  Map<String, dynamic> toJson() => {
    'id': id,
    'rec_id': recId,
    'entity_name': entityName,
    'tbl_name': tblName,
    'field': field,
    'local_value': localValue,
    'remote_value': remoteValue,
    'local_time': localTime.toIso8601String(),
    'remote_time': remoteTime.toIso8601String(),
    'original_op_id': originalOpId,
    'detected_at': detectedAt.toIso8601String(),
  };

  factory Conflict.fromJson(Map<String, dynamic> json) => Conflict(
    id: json['id'],
    recId: json['rec_id'],
    entityName: json['entity_name'],
    tblName: json['tbl_name'],
    field: json['field'],
    localValue: json['local_value'],
    remoteValue: json['remote_value'],
    localTime: DateTime.parse(json['local_time']),
    remoteTime: DateTime.parse(json['remote_time']),
    originalOpId: json['original_op_id'],
    detectedAt: DateTime.parse(json['detected_at']),
  );
}

// ==================== SYNC RESULT ====================

class SyncResult {
  final bool success;
  final int pushed;
  final int pulled;
  final int conflicts;
  final List<String> errors;
  final List<Conflict> pendingConflicts;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.errors = const [],
    this.pendingConflicts = const [],
    required this.timestamp,
  });

  bool get hasConflicts => pendingConflicts.isNotEmpty;
  bool get needsManualResolution => pendingConflicts.isNotEmpty;

  SyncResult copyWith({
    bool? success,
    int? pushed,
    int? pulled,
    int? conflicts,
    List<String>? errors,
    List<Conflict>? pendingConflicts,
  }) => SyncResult(
    success: success ?? this.success,
    pushed: pushed ?? this.pushed,
    pulled: pulled ?? this.pulled,
    conflicts: conflicts ?? this.conflicts,
    errors: errors ?? this.errors,
    pendingConflicts: pendingConflicts ?? this.pendingConflicts,
    timestamp: timestamp,
  );
}