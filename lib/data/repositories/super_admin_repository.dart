import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import '../models/password_reset_request_model.dart';
import '../models/user_model.dart';

class SuperAdminRepository {
  final _client = Supabase.instance.client;

  // ========== VUE GLOBALE ==========

  Future<List<UserModel>> getAllUsers() async {
    final data = await _client
        .from('users')
        .select('*')
        .order('created_at', ascending: false);
    return (data as List).map((j) => UserModel.fromJson(j)).toList();
  }

  /// 🆕 Dernière activité (vente/achat/dépense/facture) par user
  Future<Map<String, DateTime>> getUsersLastActivity() async {
    final map = <String, DateTime>{};
    Future<void> scan(String table) async {
      try {
        final data = await _client.from(table).select('user_id, created_at');
        for (final row in (data as List)) {
          final uid = row['user_id']?.toString();
          final dt = DateTime.tryParse(row['created_at']?.toString() ?? '');
          if (uid != null && dt != null) {
            if (!map.containsKey(uid) || dt.isAfter(map[uid]!)) map[uid] = dt;
          }
        }
      } catch (_) {}
    }
    await scan('sales');
    await scan('purchases');
    await scan('expenses');
    await scan('invoices');
    return map;
  }

  Future<Map<String, int>> getStats() async {
    final users = await _client.from('users').select('id');
    final pending =
        await _client.from('payments').select('id').eq('status', 'pending');
    final pendingResets = await _client
        .from('password_reset_requests')
        .select('id')
        .eq('status', 'pending');
    return {
      'totalUsers': (users as List).length,
      'pendingPayments': (pending as List).length,
      'pendingResets': (pendingResets as List).length,
    };
  }

  // ========== PAIEMENTS (super admin) ==========

  Future<List<PaymentModel>> getPendingPayments() async {
    final data = await _client
        .from('payments')
        .select('*')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (data as List).map((j) => PaymentModel.fromJson(j)).toList();
  }

    Future<List<PaymentModel>> getPayments({int? month, int? year, String? status}) async {
    dynamic q = _client.from('payments').select('*');
    if (status != null) q = q.eq('status', status);
    if (year != null) {
      final from = DateTime(year, month ?? 1, 1);
      final to = (month != null && month < 12)
          ? DateTime(year, month + 1, 1)
          : DateTime(year + 1, 1, 1);
      q = q.gte('created_at', from.toIso8601String())
           .lt('created_at', to.toIso8601String());
    }
    // 🆕 .order() EN DERNIER (après tous les filtres)
    final data = await q.order('created_at', ascending: false);
    return (data as List).map((j) => PaymentModel.fromJson(j)).toList();
  }
  /// 🆕 Payeurs groupés par numéro (nom boutique, total, statuts)
  Future<List<Map<String, dynamic>>> getPayers({int? month, int? year}) async {
    final payments = await getPayments(month: month, year: year);
    final bizData = await _client.from('businesses').select('id, name, code');
    final bizMap = <String, Map<String, dynamic>>{};
    for (final b in (bizData as List)) {
      bizMap[b['id'] as String] = b as Map<String, dynamic>;
    }

    final grouped = <String, Map<String, dynamic>>{};
    for (final p in payments) {
      final key = p.phoneNumber ?? 'Inconnu';
      grouped.putIfAbsent(key, () {
        final biz = bizMap[p.businessId];
        return {
          'phone': key,
          'businessName': biz?['name'] ?? '-',
          'businessCode': p.businessCode ?? biz?['code'] ?? '-',
          'total': 0.0,
          'validated': 0,
          'pending': 0,
          'rejected': 0,
          'lastDate': p.createdAt,
        };
      });
      final g = grouped[key]!;
      g['total'] = (g['total'] as double) + p.amount;
      g[p.status] = (g[p.status] as int) + 1;
      if (p.createdAt.isAfter(g['lastDate'] as DateTime)) {
        g['lastDate'] = p.createdAt;
      }
    }
    final list = grouped.values.toList();
    list.sort((a, b) =>
        (b['lastDate'] as DateTime).compareTo(a['lastDate'] as DateTime));
    return list;
  }

  Future<void> validatePayment(String paymentId, String validatorId) async {
    final payment = await _client.from('payments').select('*').eq('id', paymentId).single();
    final businessId = payment['business_id'] as String;
    final planType = payment['plan_type'] as String;
    final amount = payment['amount'] as num;

    final existing = await _client.from('subscriptions').select('id').eq('business_id', businessId).maybeSingle();
    if (existing != null) {
      await _client.from('subscriptions').update({
        'status': 'active', 'type': planType, 'amount': amount,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('business_id', businessId);
    } else {
      await _client.from('subscriptions').insert({
        'business_id': businessId, 'status': 'active', 'type': planType, 'amount': amount,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'is_trial': false,
      });
    }

    await _client.from('users').update({
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('business_id', businessId);

    await _client.from('payments').update({
      'status': 'validated', 'validated_by': validatorId,
      'validated_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);
  }

  Future<void> rejectPayment(String paymentId, String validatorId) async {
    await _client.from('payments').update({
      'status': 'rejected', 'validated_by': validatorId,
      'validated_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);
  }

  // ========== RÉINITIALISATIONS MDP ==========

  Future<List<PasswordResetRequestModel>> getPendingResetRequests() async {
    final data = await _client.from('password_reset_requests').select('*')
        .eq('status', 'pending').order('created_at', ascending: false);
    return (data as List).map((j) => PasswordResetRequestModel.fromJson(j)).toList();
  }

  Future<String> validateResetRequest(String requestId, String validatorId) async {
    final res = await _client.functions
        .invoke('admin-reset-password', body: {'requestId': requestId});
    if (res.status != 200) throw Exception(res.data['error'] ?? 'Erreur validation');
    return res.data['tempPassword'] as String;
  }

  Future<void> rejectResetRequest(String requestId, String validatorId) async {
    await _client.from('password_reset_requests').update({
      'status': 'rejected', 'validated_by': validatorId,
      'validated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  // ========== PAIEMENTS (côté USER) ==========

  Future<void> insertPendingPayment({
    required String businessId,
    required String? userId,
    required String planType,
    required double amount,
    String? method,
    String? phone,
    String? reference,
    String? businessCode,
  }) async {
    await _client.from('payments').insert({
      'business_id': businessId, 'user_id': userId, 'plan_type': planType,
      'amount': amount, 'currency': 'XOF',
      'payment_method': method ?? 'manual', 'phone_number': phone,
      'payment_reference': reference, 'business_code': businessCode,
      'status': 'pending',
    });
  }

  // ========== MOT DE PASSE OUBLIÉ (côté USER) ==========

  Future<String?> findUserIdByPhone(String phone) async {
    final data = await _client.from('users').select('id').eq('phone_number', phone).maybeSingle();
    return data?['id'] as String?;
  }

  Future<bool> submitResetRequest(String phone) async {
    final res = await _client.functions
        .invoke('request-password-reset', body: {'phoneNumber': phone});
    if (res.status != 200) {
      throw Exception(res.data['error'] ?? 'Erreur envoi demande');
    }
    return res.data['found'] == true;
  }

  Future<PasswordResetRequestModel?> latestResetRequest(String phone) async {
    final data = await _client.from('password_reset_requests').select('*')
        .eq('phone_number', phone).order('created_at', ascending: false)
        .limit(1).maybeSingle();
    if (data == null) return null;
    return PasswordResetRequestModel.fromJson(data);
  }
}