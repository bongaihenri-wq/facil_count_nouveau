import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DashboardDatabaseHelper {
  // Instance unique pour le Singleton
  static final DashboardDatabaseHelper instance = DashboardDatabaseHelper._init();
  static Database? _database;

  DashboardDatabaseHelper._init();

  /// 🔓 Accesseur pour récupérer l'instance de la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dashboard_global.db');
    return _database!;
  }

  /// ⚙️ Initialisation du fichier de base de données
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// 🛠️ Création des tables physiques à la toute première ouverture de la base
  Future _createDB(Database db, int version) async {
    // 1. Table des ventes globales
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventes (
        id TEXT PRIMARY KEY,
        date_vente TEXT,
        montant_total REAL
      )
    ''');

    // 2. Table de détail des ventes (Liaison produit <-> vente)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventes_items (
        id TEXT PRIMARY KEY,
        vente_id TEXT,
        produit_nom TEXT,
        quantite REAL,
        prix_unitaire REAL,
        FOREIGN KEY (vente_id) REFERENCES ventes (id) ON DELETE CASCADE
      )
    ''');
    
    // 3. Table des achats (Pour ton graphe mensuel d'achats)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS achats (
        id TEXT PRIMARY KEY,
        date_achat TEXT,
        montant_total REAL
      )
    ''');

    // 4. Table des dépenses (Pour la marge et le dashboard)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS depenses (
        id TEXT PRIMARY KEY,
        expense_date TEXT,
        amount REAL
      )
    ''');
  }

  /// 🔒 Fermeture de la base de données propre
  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
