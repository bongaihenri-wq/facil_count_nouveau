import 'dart:math';
import '../../data/models/subscription_model.dart';

enum PaymentMethod { wave, orangeMoney, card, cash, manual }

// Modèle pour les résultats de transaction
class PaymentTransaction {
  final String id;
  final String? transactionReference;
  final double amount;
  final bool isSuccessful;

  PaymentTransaction({
    required this.id,
    this.transactionReference,
    required this.amount,
    this.isSuccessful = true,
  });
}

class PaymentService {
  PaymentService._();
  static final PaymentService _instance = PaymentService._();
  factory PaymentService() => _instance;

  static bool simulationMode = true;

  // Configuration des prix
  static const Map<SubscriptionType, double> _prices = {
    SubscriptionType.trial: 0,
    SubscriptionType.base: 2500,
    SubscriptionType.elite: 5000,
    SubscriptionType.premium: 10000,
  };

  // ✅ CORRECTION : Définition réelle des labels
  static const Map<SubscriptionType, String> _labels = {
    SubscriptionType.trial: 'Essai Gratuit',
    SubscriptionType.base: 'Forfait Base',
    SubscriptionType.elite: 'Forfait Elite',
    SubscriptionType.premium: 'Forfait Premium',
  };

  // --- MÉTHODES STATIQUES ---

  /// Retourne le prix pour un type donné
  static double getPrice(SubscriptionType type) => _prices[type] ?? 1000;

  /// Retourne le nom lisible pour l'UI
  static String getLabel(SubscriptionType type) {
    return _labels[type] ?? 'Inconnu';
  }

  /// Retourne le prix formaté (ex: 1000 CFA)
  static String getPriceLabel(SubscriptionType type) {
    final price = getPrice(type);
    if (price == 0) return 'Gratuit';
    return '${price.toStringAsFixed(0)} CFA';
  }

  // --- MÉTHODES D'INSTANCE ---

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// 🟢 Paiement Wave
  Future<PaymentTransaction> initiateWavePayment({
    required String businessId,
    required SubscriptionType type,
    String? phoneNumber,
  }) async {
    if (simulationMode) await Future.delayed(const Duration(seconds: 1));
    return PaymentTransaction(
      id: 'WAVE_${_generateId()}',
      transactionReference: 'WV_REF_${_generateId()}',
      amount: getPrice(type),
    );
  }

  /// 🟢 Paiement Orange Money
  Future<PaymentTransaction> initiateOrangeMoneyPayment({
    required String businessId,
    required SubscriptionType type,
    required String phoneNumber,
  }) async {
    if (simulationMode) await Future.delayed(const Duration(seconds: 1));
    return PaymentTransaction(
      id: 'OM_${_generateId()}',
      transactionReference: 'OM_REF_${_generateId()}',
      amount: getPrice(type),
    );
  }

  /// 🟢 Paiement Manuel (Admin)
  Future<PaymentTransaction> createManualPayment({
    required String businessId,
    required SubscriptionType type,
  }) async {
    return PaymentTransaction(
      id: 'MAN_${_generateId()}',
      transactionReference: 'MAN_REF_${_generateId()}',
      amount: getPrice(type),
    );
  }
}
