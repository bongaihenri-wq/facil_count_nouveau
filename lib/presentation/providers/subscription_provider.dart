import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/license_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/utils/business_helper.dart';
import '../../../data/models/subscription_model.dart';

// ==================== DÉPENDANCES EXTERNES ====================

// Assure-toi que ce provider existe pour fournir le client Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final licenseServiceProvider = Provider<LicenseService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return LicenseService(supabase);
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

// ==================== PROVIDERS D'ÉTAT ====================

/// Calcule le nombre de jours restants
final daysRemainingProvider = Provider<int>((ref) {
  final subscriptionAsync = ref.watch(subscriptionNotifierProvider);
  return subscriptionAsync.when(
    data: (sub) {
      final difference = sub.endDate.difference(DateTime.now()).inDays;
      return difference > 0 ? difference : 0;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionModel>>((ref) {
  final licenseService = ref.watch(licenseServiceProvider);
  final paymentService = ref.watch(paymentServiceProvider);
  // On suppose que businessHelperProvider est défini dans business_helper.dart
  final businessHelper = ref.watch(businessHelperProvider); 
  
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

  /// Charge l'abonnement actuel depuis Supabase ou le Cache
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

  /// Procédure de renouvellement avec gestion des différents modes de paiement
  Future<void> renewWithPayment(
    SubscriptionType type,
    PaymentMethod method, {
    String? phoneNumber,
  }) async {
    final currentState = state.value;
    state = const AsyncValue.loading();
    
    try {
      final businessId = await _businessHelper.getBusinessId();
      late final String txRef;
      
      // 1. Initialiser le paiement selon la méthode choisie
      if (method == PaymentMethod.wave) {
        final tx = await _paymentService.initiateWavePayment(
          businessId: businessId,
          type: type,
          phoneNumber: phoneNumber,
        );
        txRef = tx.transactionReference ?? 'WAVE_${DateTime.now().millisecondsSinceEpoch}';
      } else if (method == PaymentMethod.orangeMoney) {
        if (phoneNumber == null) throw Exception('Numéro de téléphone requis pour Orange Money');
        final tx = await _paymentService.initiateOrangeMoneyPayment(
          businessId: businessId,
          type: type,
          phoneNumber: phoneNumber,
        );
        txRef = tx.transactionReference ?? 'OM_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Paiement manuel ou cash
        final tx = await _paymentService.createManualPayment(
          businessId: businessId,
          type: type,
        );
        txRef = tx.transactionReference ?? 'MANUAL_${DateTime.now().millisecondsSinceEpoch}';
      }

      // 2. Enregistrer le renouvellement dans la table 'subscriptions'
      final newSubscription = await _licenseService.renewSubscription(
        businessId,
        type,
        paymentMethod: method.name,
        transactionId: txRef,
      );

      state = AsyncValue.data(newSubscription);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // On restaure l'ancien état après un délai pour que l'utilisateur ne reste pas bloqué sur l'erreur
      if (currentState != null) {
         Future.delayed(const Duration(seconds: 3), () => state = AsyncValue.data(currentState));
      }
      rethrow;
    }
  }

  /// Rafraîchissement forcé (utilisé par le bouton "Vérifier mon paiement")
  Future<void> refresh() async {
    try {
      final businessId = await _businessHelper.getBusinessId();
      final subscription = await _licenseService.forceRefresh(businessId);
      state = AsyncValue.data(subscription);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Utile pour le mode DEBUG uniquement
  Future<void> shortenTrial(int daysLeft) async {
    try {
      final businessId = await _businessHelper.getBusinessId();
      await _licenseService.shortenTrialForTesting(businessId, daysLeft);
      await loadSubscription();
    } catch (e) {
      debugPrint('Erreur debug shortenTrial: $e');
    }
  }
}
