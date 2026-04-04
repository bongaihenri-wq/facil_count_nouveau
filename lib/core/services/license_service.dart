import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/subscription_model.dart';

class LicenseService {
  final SupabaseClient _client;
  static const int trialDays = 14;
  static const String _cacheKey = 'subscription_v3';

  LicenseService(this._client);

  String _toUuid(String input) {
    if (input.length == 36 && input.contains('-')) return input;
    
    final seed = input.hashCode;
    final rand = Random(seed);
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0,8)}-${hex.substring(8,12)}-4${hex.substring(12,15)}-${hex.substring(15,19)}-${hex.substring(19,32)}';
  }

  Future<SubscriptionModel> getOrCreateSubscription(String businessId) async {
    final uuid = _toUuid(businessId);
    
    try {
      final sub = await _fetchFromServer(uuid);
      await _saveToCache(sub);
      return sub;
    } catch (e) {
      print('⚠️ Hors ligne: $e');
      return await _loadFromCacheOrCreate(uuid);
    }
  }

  Future<SubscriptionModel> _fetchFromServer(String businessId) async {
    final response = await _client
        .from('subscriptions')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      return SubscriptionModel.fromJson(response);
    }

    return await _createTrial(businessId);
  }

  Future<SubscriptionModel> _createTrial(String businessId) async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: trialDays));
    final id = _generateUuid();

    final data = {
      'id': id,
      'business_id': businessId,
      'type': 'trial',
      'status': 'active',
      'start_date': now.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_trial': true,
      'metadata': {'auto': true},
    };

    try {
      final res = await _client.from('subscriptions').insert(data).select().single();
      return SubscriptionModel.fromJson(res);
    } catch (e) {
      print('❌ Serveur: $e');
      return _createLocal(businessId);
    }
  }

  String _generateUuid() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0,8)}-${h.substring(8,12)}-4${h.substring(12,15)}-${h.substring(15,19)}-${h.substring(19,32)}';
  }

  SubscriptionModel _createLocal(String businessId) {
    final now = DateTime.now();
    return SubscriptionModel(
      id: 'local_${now.millisecondsSinceEpoch}',
      businessId: businessId,
      type: SubscriptionType.trial,
      status: SubscriptionStatus.active,
      startDate: now,
      endDate: now.add(const Duration(days: trialDays)),
      isTrial: true,
      metadata: {'local': true},
    );
  }

  Future<void> _saveToCache(SubscriptionModel sub) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(sub.toJson()));
  }

  Future<SubscriptionModel> _loadFromCacheOrCreate(String businessId) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        if (data['business_id'] == businessId) {
          return SubscriptionModel.fromJson(data);
        }
      } catch (e) {
        print('❌ Cache invalide');
        await prefs.remove(_cacheKey);
      }
    }
    return _createLocal(businessId);
  }

  Future<LicenseCheckResult> checkLicense(String businessId) async {
    final sub = await getOrCreateSubscription(businessId);
    final isLocal = sub.id.startsWith('local_');
    
    if (sub.isValid) {
      return LicenseCheckResult(
        isValid: true, subscription: sub, message: sub.alertMessage,
        canUseApp: true, isOffline: isLocal,
      );
    }
    if (sub.isInGracePeriod) {
      return LicenseCheckResult(
        isValid: false, subscription: sub, message: sub.alertMessage,
        canUseApp: true, showWarning: true, isOffline: isLocal,
      );
    }
    return LicenseCheckResult(
      isValid: false, subscription: sub, message: 'Expiré',
      canUseApp: false, showExpiredScreen: true, isOffline: isLocal,
    );
  }

  Future<SubscriptionModel> renewSubscription(
    String businessId,
    SubscriptionType type, {
    required String paymentMethod,
    required String transactionId,
    Map<String, dynamic>? paymentInfo,
    bool isAdmin = false,
  }) async {
    // Vérifie lifetime réservé admin
    if (type == SubscriptionType.lifetime && !isAdmin) {
      throw Exception('Abonnement à vie réservé aux administrateurs');
    }

    final uuid = _toUuid(businessId);
    final now = DateTime.now();
    final days = _getDuration(type);

    final current = await getOrCreateSubscription(businessId);
    final endDate = now.add(Duration(days: days));

    final newSub = SubscriptionModel(
      id: _generateUuid(),
      businessId: uuid,
      type: type,
      status: SubscriptionStatus.active,
      startDate: current.isValid ? current.startDate : now,
      endDate: endDate,
      isTrial: false,
      metadata: {
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
        'amount': paymentInfo?['amount'],
        'previous_id': current.id,
        'is_admin': isAdmin,
      },
    );

    final data = {
      'id': newSub.id,
      'business_id': newSub.businessId,
      'type': newSub.type.name,
      'status': newSub.status.name,
      'start_date': newSub.startDate.toIso8601String(),
      'end_date': newSub.endDate.toIso8601String(),
      'is_trial': false,
      'metadata': newSub.metadata,
    };

    try {
      final res = await _client.from('subscriptions').insert(data).select().single();
      final sub = SubscriptionModel.fromJson(res);
      await _saveToCache(sub);
      return sub;
    } catch (e) {
      print('⚠️ Offline: $e');
      await _saveToCache(newSub);
      return newSub;
    }
  }

  int _getDuration(SubscriptionType type) {
    return switch (type) {
      SubscriptionType.trial => 14,
      SubscriptionType.monthly => 30,
      SubscriptionType.quarterly => 90,
      SubscriptionType.semestrial => 180,
      SubscriptionType.yearly => 365,
      SubscriptionType.lifetime => 36500,
    };
  }

  Future<void> shortenTrialForTesting(String businessId, int days) async {
    if (kReleaseMode) return;
    final uuid = _toUuid(businessId);
    final end = DateTime.now().add(Duration(days: days));

    try {
      await _client.from('subscriptions')
        .update({'end_date': end.toIso8601String()})
        .eq('business_id', uuid);
      final sub = await _fetchFromServer(uuid);
      await _saveToCache(sub);
    } catch (e) {
      print('⚠️ Test local: $e');
      final cached = await _loadFromCacheOrCreate(uuid);
      final updated = cached.copyWith(endDate: end);
      await _saveToCache(updated);
    }
  }

  Future<SubscriptionModel> forceRefresh(String businessId) async {
    final uuid = _toUuid(businessId);
    final sub = await _fetchFromServer(uuid);
    await _saveToCache(sub);
    return sub;
  }
}

class LicenseCheckResult {
  final bool isValid, canUseApp, showWarning, showExpiredScreen, isOffline;
  final SubscriptionModel subscription;
  final String message;

  LicenseCheckResult({
    required this.isValid,
    required this.subscription,
    required this.message,
    required this.canUseApp,
    this.showWarning = false,
    this.showExpiredScreen = false,
    this.isOffline = false,
  });
}