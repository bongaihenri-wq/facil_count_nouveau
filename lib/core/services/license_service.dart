import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/subscription_model.dart';

class LicenseService {
  final SupabaseClient _client;
  static const String _cacheKey = 'subscription_cache';

  LicenseService(this._client);

  /// 🟢 Méthode manquante : getOrCreateSubscription
  Future<SubscriptionModel> getOrCreateSubscription(String businessId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('business_id', businessId)
          .maybeSingle();

      if (response != null) {
        final sub = SubscriptionModel.fromJson(response);
        _saveToCache(sub);
        return sub;
      }
      return _createTrial(businessId);
    } catch (e) {
      return _loadFromCache();
    }
  }

  Future<SubscriptionModel> _createTrial(String businessId) async {
    final now = DateTime.now();
    final data = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'business_id': businessId,
      'type': 'trial',
      'status': 'active',
      'start_date': now.toIso8601String(),
      'end_date': now.add(const Duration(days: 30)).toIso8601String(),
      'is_trial': true,
    };
    final res = await _client.from('subscriptions').insert(data).select().single();
    return SubscriptionModel.fromJson(res);
  }

  /// 🟢 Méthode manquante : forceRefresh
  Future<SubscriptionModel> forceRefresh(String businessId) async {
    return await getOrCreateSubscription(businessId);
  }

  /// 🟢 Méthode manquante : shortenTrialForTesting
  Future<void> shortenTrialForTesting(String businessId, int days) async {
    final newEnd = DateTime.now().add(Duration(days: days));
    await _client.from('subscriptions')
        .update({'end_date': newEnd.toIso8601String()})
        .eq('business_id', businessId);
  }

  Future<void> _saveToCache(SubscriptionModel sub) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(sub.toJson()));
  }

  Future<SubscriptionModel> _loadFromCache() async {
     final prefs = await SharedPreferences.getInstance();
     final data = prefs.getString(_cacheKey);
     if (data == null) throw Exception("Pas de connexion et pas de cache");
     return SubscriptionModel.fromJson(jsonDecode(data));
  }

  // Méthode Renew déjà fournie précédemment...
  Future<SubscriptionModel> renewSubscription(String bId, SubscriptionType type, {required String paymentMethod, required String transactionId}) async {
    // ... (Code du renewSubscription précédent)
    final now = DateTime.now();
    final data = {
      'business_id': bId,
      'type': type.name,
      'status': 'active',
      'start_date': now.toIso8601String(),
      'end_date': now.add(const Duration(days: 30)).toIso8601String(),
      'is_trial': false,
      'metadata': {'method': paymentMethod, 'tx': transactionId}
    };
    final res = await _client.from('subscriptions').insert(data).select().single();
    return SubscriptionModel.fromJson(res);
  }
}
