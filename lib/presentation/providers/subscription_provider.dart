// lib/presentation/providers/subscription_provider.dart
import 'package:facil_count_nouveau/presentation/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/license_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/utils/business_helper.dart';
import '../../../data/models/subscription_model.dart';

// ==================== IMPORTS DES PROVIDERS EXISTANTS ====================
// Ces providers sont définis dans d'autres fichiers :
// - supabaseClientProvider → lib/presentation/providers/auth_provider.dart ou autre
// - licenseServiceProvider → à créer ici si inexistant
// - businessHelperProvider → lib/core/utils/business_helper.dart (déjà existant)

// ==================== PROVIDERS LOCAUX (si non existants ailleurs) ====================

final licenseServiceProvider = Provider<LicenseService>((ref) {
  final supabase = ref.watch(supabaseClientProvider); // Supposé existant
  return LicenseService(supabase);
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

// ⚠️ businessHelperProvider est DÉJÀ défini dans business_helper.dart
// On l'importe/impute depuis là-bas

// ==================== PROVIDERS D'ÉTAT ====================

final daysRemainingProvider = Provider<int>((ref) {
  final subscriptionAsync = ref.watch(subscriptionNotifierProvider);
  return subscriptionAsync.when(
    data: (sub) => sub.daysRemaining,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionModel>>((ref) {
  final licenseService = ref.watch(licenseServiceProvider);
  final paymentService = ref.watch(paymentServiceProvider);
  final businessHelper = ref.watch(businessHelperProvider); // ✅ Existant dans business_helper.dart
  
  return SubscriptionNotifier(licenseService, paymentService, businessHelper);
});

// ==================== NOTIFIER ====================

class SubscriptionNotifier extends StateNotifier<AsyncValue<SubscriptionModel>> {
  final LicenseService _licenseService;
  final PaymentService _paymentService;
  final BusinessHelper _businessHelper;

  SubscriptionNotifier(
    this._licenseService,
    this._paymentService,
    this._businessHelper,
  ) : super(const AsyncValue.loading()) {
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    state = const AsyncValue.loading();
    try {
      final businessId = await _businessHelper.getBusinessId();
      final subscription = await _licenseService.getOrCreateSubscription(businessId);
      state = AsyncValue.data(subscription);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> renewWithPayment(
    SubscriptionType type,
    PaymentMethod method, {
    String? phoneNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final businessId = await _businessHelper.getBusinessId();

      PaymentTransaction transaction;
      switch (method) {
        case PaymentMethod.wave:
          transaction = await _paymentService.initiateWavePayment(
            businessId: businessId,
            type: type,
            phoneNumber: phoneNumber,
          );
          break;
        case PaymentMethod.orangeMoney:
          if (phoneNumber == null) throw Exception('Numéro requis');
          transaction = await _paymentService.initiateOrangeMoneyPayment(
            businessId: businessId,
            type: type,
            phoneNumber: phoneNumber,
          );
          break;
        case PaymentMethod.card:
          throw Exception('Paiement par carte non implémenté');
        case PaymentMethod.cash:
        case PaymentMethod.manual:
          transaction = await _paymentService.createManualPayment(
            businessId: businessId,
            type: type,
          );
          break;
      }

      if (!transaction.isSuccessful) {
        throw Exception('Paiement échoué');
      }

      final newSubscription = await _licenseService.renewSubscription(
        businessId,
        type,
        paymentMethod: method.name,
        transactionId: transaction.transactionReference!,
        paymentInfo: {
          'amount': transaction.amount,
          'transaction_id': transaction.id,
          'method': method.name,
        },
      );

      state = AsyncValue.data(newSubscription);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> renew(
    SubscriptionType type, {
    Map<String, dynamic>? paymentInfo,
  }) async {
    state = const AsyncValue.loading();
    try {
      final businessId = await _businessHelper.getBusinessId();
      final newSubscription = await _licenseService.renewSubscription(
        businessId,
        type,
        paymentMethod: 'manual',
        transactionId: 'MANUAL_${DateTime.now().millisecondsSinceEpoch}',
        paymentInfo: paymentInfo,
      );
      state = AsyncValue.data(newSubscription);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      final businessId = await _businessHelper.getBusinessId();
      final subscription = await _licenseService.forceRefresh(businessId);
      state = AsyncValue.data(subscription);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> shortenTrial(int daysLeft) async {
    try {
      final businessId = await _businessHelper.getBusinessId();
      await _licenseService.shortenTrialForTesting(businessId, daysLeft);
      await loadSubscription();
    } catch (e) {
      debugPrint('Erreur shortenTrial: $e');
    }
  }
}