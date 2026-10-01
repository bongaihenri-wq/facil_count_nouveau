import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import '../models/password_reset_request_model.dart';
import '../models/user_model.dart';

class SuperAdminRepository {
  final _client = Supabase.instance.client;

  // ========== VUE GLOBALE ==========

  /// Tous les utilisateurs (tous business confondus)
  Future<List<UserModel>> getAllUsers() async {
    final data = await _client
        .from('users')
        .select('*')
        .order('created_at', ascending: false);
    return (data as List).map((j) => UserModel.fromJson(j)).toList();
  }

  /// Stats rapides pour le dashboard
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

  /// 🎯 VALIDATION = déblocage automatique complet du compte
  Future<void> validatePayment(String paymentId, String validatorId) async {
    final payment = await _client
        .from('payments')
        .select('*')
        .eq('id', paymentId)
        .single();

    final businessId = payment['business_id'] as String;
    final planType = payment['plan_type'] as String;
    final amount = payment['amount'] as num;

    // 2. Mettre à jour (ou créer) l'abonnement du business
    final existing = await _client
        .from('subscriptions')
        .select('id')
        .eq('business_id', businessId)
        .maybeSingle();

    if (existing != null) {
      await _client.from('subscriptions').update({
        'status': 'active',
        'type': planType,
        'amount': amount,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('business_id', businessId);
    } else {
      await _client.from('subscriptions').insert({
        'business_id': businessId,
        'status': 'active',
        'type': planType,
        'amount': amount,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'is_trial': false,
      });
    }

    // 3. Débloquer immédiatement les users du business
    await _client.from('users').update({
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('business_id', businessId);

    // 4. Marquer le paiement comme validé
    await _client.from('payments').update({
      'status': 'validated',
      'validated_by': validatorId,
      'validated_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);
  }

  Future<void> rejectPayment(String paymentId, String validatorId) async {
    await _client.from('payments').update({
      'status': 'rejected',
      'validated_by': validatorId,
      'validated_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);
  }

  // ========== RÉINITIALISATIONS MDP (super admin) ==========

  Future<List<PasswordResetRequestModel>> getPendingResetRequests() async {
    final data = await _client
        .from('password_reset_requests')
        .select('*')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (data as List)
        .map((j) => PasswordResetRequestModel.fromJson(j))
        .toList();
  }

  /// 🆕 Validation via Edge Function : crée un MDP temporaire
  /// Retourne le mot de passe temporaire à communiquer au client
  Future<String> validateResetRequest(
      String requestId, String validatorId) async {
    final res = await _client.functions
        .invoke('admin-reset-password', body: {'requestId': requestId});
    if (res.status != 200) {
      throw Exception(res.data['error'] ?? 'Erreur validation');
    }
    return res.data['tempPassword'] as String;
  }

  Future<void> rejectResetRequest(String requestId, String validatorId) async {
    await _client.from('password_reset_requests').update({
      'status': 'rejected',
      'validated_by': validatorId,
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
  }) async {
    await _client.from('payments').insert({
      'business_id': businessId,
      'user_id': userId,
      'plan_type': planType,
      'amount': amount,
      'currency': 'XOF',
      'payment_method': method ?? 'manual',
      'phone_number': phone,
      'payment_reference': reference,
      'status': 'pending',
    });
  }

  // ========== MOT DE PASSE OUBLIÉ (côté USER) ==========

  Future<String?> findUserIdByPhone(String phone) async {
    final data = await _client
        .from('users')
        .select('id')
        .eq('phone_number', phone)
        .maybeSingle();
    return data?['id'] as String?;
  }

  /// 🆕 Demande de reset via Edge Function (anonyme OK)
  Future<bool> submitResetRequest(String phone) async {
    final res = await _client.functions.invoke('request-password-reset',
        body: {'phoneNumber': phone});
    if (res.status != 200) {
      throw Exception(res.data['error'] ?? 'Erreur envoi demande');
    }
    return res.data['found'] == true;
  }

  Future<PasswordResetRequestModel?> latestResetRequest(String phone) async {
    final data = await _client
        .from('password_reset_requests')
        .select('*')
        .eq('phone_number', phone)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return PasswordResetRequestModel.fromJson(data);
  }
}