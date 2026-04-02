import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

// ==================== TABLES ====================

@DataClassName('LocalSale')
class LocalSales extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  DateTimeColumn get saleDate => dateTime()();
  RealColumn get totalAmount => real()();
  TextColumn get items => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)(); // ✅ AJOUTÉ

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalPurchase')
class LocalPurchases extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get supplierId => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get totalAmount => real()();
  TextColumn get items => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)(); // ✅ AJOUTÉ

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalProduct')
class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get purchasePrice => real()();
  RealColumn get salePrice => real()();
  RealColumn get stockQuantity => real().withDefault(const Constant(0.0))();
  TextColumn get unit => text().withDefault(const Constant('unité'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)(); // ✅ AJOUTÉ

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get opType => text()();
  TextColumn get recId => text()();
  TextColumn get tblName => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)(); // ✅ AJOUTÉ
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errMsg => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== DATABASE ====================

@DriftDatabase(tables: [LocalSales, LocalPurchases, LocalProducts, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'facilcount_db');
  }

  static final _uuid = Uuid();
  String generateId() => _uuid.v4();
}
