import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../data/models/subscription_model.dart';

export '../../data/models/subscription_model.dart';

// ==================== ENUMS ====================

enum PaymentMethod {
  wave,
  orangeMoney,
  card,
  cash,
  manual,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

// ==================== MODÈLES ====================

class PaymentTransaction {
  final String id;
  final String businessId;
  final PaymentMethod method;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? phoneNumber;
  final String? transactionReference;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  PaymentTransaction({
    required this.id,
    required this.businessId,
    required this.method,
    required this.amount,
    this.currency = 'XOF',
    this.status = PaymentStatus.pending,
    this.phoneNumber,
    this.transactionReference,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.metadata,
  });

  PaymentTransaction copyWith({
    PaymentStatus? status,
    String? transactionReference,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentTransaction(
      id: id,
      businessId: businessId,
      method: method,
      amount: amount,
      currency: currency,
      status: status ?? this.status,
      phoneNumber: phoneNumber,
      transactionReference: transactionReference ?? this.transactionReference,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isSuccessful => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.processing;
  bool get isFailed => status == PaymentStatus.failed || status == PaymentStatus.cancelled;
}

class SubscriptionOption {
  final SubscriptionType type;
  final String title;
  final String price;
  final String description;
  final int durationDays;
  final int discount;
  final bool isRecommended;
  final bool isAdminOnly;

  const SubscriptionOption({
    required this.type,
    required this.title,
    required this.price,
    required this.description,
    required this.durationDays,
    this.discount = 0,
    this.isRecommended = false,
    this.isAdminOnly = false,
  });
}

// ==================== SERVICE PRINCIPAL ====================

class PaymentService {
  PaymentService._();
  static final PaymentService _instance = PaymentService._();
  factory PaymentService() => _instance;

  // Mode simulation pour les tests
  static bool simulationMode = true;

  // Configuration des prix (FCFA)
  static const Map<SubscriptionType, double> _prices = {
    SubscriptionType.trial: 0,
    SubscriptionType.monthly: 5000,
    SubscriptionType.quarterly: 13500,
    SubscriptionType.semestrial: 25000,
    SubscriptionType.yearly: 48000,
    SubscriptionType.lifetime: 150000,
  };

  // Durées en jours
  static const Map<SubscriptionType, int> _durations = {
    SubscriptionType.trial: 14,
    SubscriptionType.monthly: 30,
    SubscriptionType.quarterly: 90,
    SubscriptionType.semestrial: 180,
    SubscriptionType.yearly: 365,
    SubscriptionType.lifetime: 36500, // ~100 ans
  };

  // Labels localisés
  static const Map<SubscriptionType, String> _labels = {
    SubscriptionType.trial: 'Essai gratuit',
    SubscriptionType.monthly: 'Mensuel',
    SubscriptionType.quarterly: 'Trimestriel',
    SubscriptionType.semestrial: 'Semestriel',
    SubscriptionType.yearly: 'Annuel',
    SubscriptionType.lifetime: 'À vie',
  };

  // ==================== GETTERS STATIQUES ====================

  static double getPrice(SubscriptionType type) => _prices[type] ?? 5000;
  static int getDuration(SubscriptionType type) => _durations[type] ?? 30;
  static String getLabel(SubscriptionType type) => _labels[type] ?? 'Inconnu';

  static String getPriceLabel(SubscriptionType type) {
    final price = getPrice(type);
    if (price == 0) return 'Gratuit';
    return '${price.toStringAsFixed(0)} CFA';
  }

  static String getDescription(SubscriptionType type) {
    return switch (type) {
      SubscriptionType.trial => '14 jours pour découvrir l\'app',
      SubscriptionType.monthly => 'Parfait pour démarrer',
      SubscriptionType.quarterly => 'Économisez 10%',
      SubscriptionType.semestrial => 'Économisez 17% - Recommandé',
      SubscriptionType.yearly => 'Économisez 20% - Meilleur rapport',
      SubscriptionType.lifetime => 'Accès illimité - Réservé admin',
    };
  }

  // ==================== OPTIONS D'ABONNEMENT ====================

  /// Options pour les utilisateurs standards (sans lifetime)
  static List<SubscriptionOption> getUserOptions() {
    return const [
      SubscriptionOption(
        type: SubscriptionType.monthly,
        title: 'Mensuel',
        price: '5 000 CFA',
        description: 'Parfait pour démarrer',
        durationDays: 30,
        discount: 0,
      ),
      SubscriptionOption(
        type: SubscriptionType.quarterly,
        title: 'Trimestriel',
        price: '13 500 CFA',
        description: 'Économisez 10%',
        durationDays: 90,
        discount: 10,
      ),
      SubscriptionOption(
        type: SubscriptionType.semestrial,
        title: 'Semestriel',
        price: '25 000 CFA',
        description: 'Économisez 17% - Recommandé',
        durationDays: 180,
        discount: 17,
        isRecommended: true,
      ),
      SubscriptionOption(
        type: SubscriptionType.yearly,
        title: 'Annuel',
        price: '48 000 CFA',
        description: 'Économisez 20% - Meilleur rapport',
        durationDays: 365,
        discount: 20,
      ),
    ];
  }

  /// Option admin (lifetime)
  static SubscriptionOption? getAdminOption() {
    return const SubscriptionOption(
      type: SubscriptionType.lifetime,
      title: 'À vie',
      price: '150 000 CFA',
      description: 'Accès illimité - Réservé admin',
      durationDays: 36500,
      discount: 99,
      isAdminOnly: true,
    );
  }

  /// Toutes les options selon le rôle
  static List<SubscriptionOption> getAllOptions({bool isAdmin = false}) {
    final options = [...getUserOptions()];
    if (isAdmin) {
      final adminOption = getAdminOption();
      if (adminOption != null) options.add(adminOption);
    }
    return options;
  }

  // ==================== MÉTHODES DE PAIEMENT ====================

  /// Paiement par Wave
  Future<PaymentTransaction> initiateWavePayment({
    required String businessId,
    required SubscriptionType type,
    String? phoneNumber,
  }) async {
    final amount = getPrice(type);
    
    final transaction = PaymentTransaction(
      id: 'WAVE_${_generateId()}',
      businessId: businessId,
      method: PaymentMethod.wave,
      amount: amount,
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
      metadata: {
        'provider': 'wave',
        'subscription_type': type.name,
        'duration_days': getDuration(type),
        'simulation': simulationMode,
      },
    );

    if (simulationMode) {
      await Future.delayed(const Duration(seconds: 2));
      return transaction.copyWith(
        status: PaymentStatus.completed,
        transactionReference: 'WAVE_REF_${_generateId()}',
        completedAt: DateTime.now(),
      );
    }

    // TODO: Intégrer l'API Wave réelle
    throw UnimplementedError('API Wave à intégrer');
  }

  /// Paiement par Orange Money
  Future<PaymentTransaction> initiateOrangeMoneyPayment({
    required String businessId,
    required SubscriptionType type,
    required String phoneNumber,
  }) async {
    final amount = getPrice(type);
    
    final transaction = PaymentTransaction(
      id: 'OM_${_generateId()}',
      businessId: businessId,
      method: PaymentMethod.orangeMoney,
      amount: amount,
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
      metadata: {
        'provider': 'orange_money',
        'subscription_type': type.name,
        'duration_days': getDuration(type),
        'simulation': simulationMode,
      },
    );

    if (simulationMode) {
      await Future.delayed(const Duration(seconds: 2));
      return transaction.copyWith(
        status: PaymentStatus.completed,
        transactionReference: 'OM_REF_${_generateId()}',
        completedAt: DateTime.now(),
      );
    }

    // TODO: Intégrer l'API Orange Money réelle
    throw UnimplementedError('API Orange Money à intégrer');
  }

  /// Paiement par carte (stripe/flutterwave)
  Future<PaymentTransaction> initiateCardPayment({
    required String businessId,
    required SubscriptionType type,
    required String cardToken,
  }) async {
    final amount = getPrice(type);
    
    final transaction = PaymentTransaction(
      id: 'CARD_${_generateId()}',
      businessId: businessId,
      method: PaymentMethod.card,
      amount: amount,
      createdAt: DateTime.now(),
      metadata: {
        'provider': 'stripe',
        'subscription_type': type.name,
        'card_token': cardToken,
      },
    );

    if (simulationMode) {
      await Future.delayed(const Duration(seconds: 1));
      return transaction.copyWith(
        status: PaymentStatus.completed,
        transactionReference: 'CARD_REF_${_generateId()}',
        completedAt: DateTime.now(),
      );
    }

    throw UnimplementedError('API Carte à intégrer');
  }

  /// Paiement manuel (admin)
  Future<PaymentTransaction> createManualPayment({
    required String businessId,
    required SubscriptionType type,
    String? notes,
  }) async {
    final amount = getPrice(type);
    
    return PaymentTransaction(
      id: 'MANUAL_${_generateId()}',
      businessId: businessId,
      method: PaymentMethod.manual,
      amount: amount,
      status: PaymentStatus.completed, // Directement complété
      transactionReference: 'ADMIN_${_generateId()}',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      metadata: {
        'provider': 'manual',
        'subscription_type': type.name,
        'notes': notes,
        'admin_created': true,
      },
    );
  }

  // ==================== UTILITAIRES ====================

  /// Vérifie le statut d'une transaction
  Future<PaymentStatus> checkTransactionStatus(String transactionId) async {
    if (simulationMode) return PaymentStatus.completed;
    
    // TODO: Implémenter la vérification réelle
    return PaymentStatus.pending;
  }

  /// Rembourse une transaction
  Future<PaymentTransaction?> refundTransaction(String transactionId) async {
    // TODO: Implémenter le remboursement
    return null;
  }

  /// Génère un ID unique
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return '${timestamp}_$random';
  }
}