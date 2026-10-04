import 'package:supabase_flutter/supabase_flutter.dart';

/// 🔒 Gestion centralisée du verrouillage (ventes/achats/dépenses/factures)
class LockRepository {
  final _client = Supabase.instance.client;

  /// Tables autorisées + colonne de date associée
  static const _tables = {
    'Ventes': _LockTarget('sales', 'sale_date'),
    'Achats': _LockTarget('purchases', 'purchase_date'),
    'Dépenses': _LockTarget('expenses', 'expenses_date'),
    'Factures': _LockTarget('invoices', 'invoice_date'),
  };

  Future<Map<String, dynamic>> _currentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Session expirée, reconnectez-vous');
    final data = await _client
        .from('users')
        .select('role, business_id')
        .eq('id', userId)
        .single();
    return {'id': userId, 'role': data['role'] as String, 'business_id': data['business_id'] as String?};
  }

  void _checkUnlockAllowed(Map<String, dynamic> user) {
    final role = user['role'] as String;
    if (role != 'admin' && role != 'super_admin') {
      throw Exception('Seul l\'administrateur peut déverrouiller. Contactez votre admin.');
    }
  }

  /// 🔒 Verrouillage / 🔓 déverrouillage GROUPÉ (jour ou période)
  Future<int> bulkLockUnlock({
    required String actionType,   // clé de _tables : 'Ventes' | 'Achats' | 'Dépenses' | 'Factures'
    required bool lock,           // true = verrouiller, false = déverrouiller
    required DateTime from,
    required DateTime to,
    required String scope,        // 'day' | 'period'
    String? note,                 // ex: "Point de contrôle du 02/10"
  }) async {
    final target = _tables[actionType];
    if (target == null) throw Exception('Type d\'action invalide');

    final user = await _currentUser();
    if (!lock) _checkUnlockAllowed(user); // 🚫 user simple : verrouiller OK, déverrouiller interdit

    final now = DateTime.now().toIso8601String();
    final res = await _client
        .from(target.table)
        .update({
          'locked': lock,
          if (lock) 'locked_at': now,
          if (lock) 'locked_by': user['id'],
        })
        .eq('business_id', user['business_id'])
        .gte(target.dateColumn, from.toIso8601String())
        .lt(target.dateColumn, to.toIso8601String())
        .select('id');

    // Registre (audit / point de contrôle)
    await _client.from('lock_events').insert({
      'business_id': user['business_id'],
      'action_type': target.table,
      'operation': lock ? 'lock' : 'unlock',
      'scope': scope,
      'date_from': from.toIso8601String(),
      'date_to': to.toIso8601String(),
      'operator_id': user['id'],
      'operator_role': user['role'],
      'note': note,
    });

    return (res as List).length;
  }

  /// 🔒 Verrouillage / 🔓 déverrouillage d'UNE LIGNE (depuis les listes)
  Future<void> toggleSingle({
    required String actionType,
    required String id,
    required bool lock,
  }) async {
    final target = _tables[actionType];
    if (target == null) throw Exception('Type d\'action invalide');

    final user = await _currentUser();
    if (!lock) _checkUnlockAllowed(user);

    final now = DateTime.now().toIso8601String();
    await _client.from(target.table).update({
      'locked': lock,
      if (lock) 'locked_at': now,
      if (lock) 'locked_by': user['id'],
    }).eq('id', id);

    await _client.from('lock_events').insert({
      'business_id': user['business_id'],
      'action_type': target.table,
      'operation': lock ? 'lock' : 'unlock',
      'scope': 'single',
      'date_from': now,
      'date_to': now,
      'target_id': id,
      'operator_id': user['id'],
      'operator_role': user['role'],
    });
  }

  /// 📜 Historique des clôtures du business (registre)
  Future<List<Map<String, dynamic>>> getLockEvents({int limit = 50}) async {
    final user = await _currentUser();
    final data = await _client
        .from('lock_events')
        .select('*')
        .eq('business_id', user['business_id'])
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }
}

class _LockTarget {
  final String table;
  final String dateColumn;
  const _LockTarget(this.table, this.dateColumn);
}