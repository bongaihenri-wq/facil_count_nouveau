import 'package:flutter/foundation.dart';

enum SubscriptionType {
  trial,      // 30 jours (Inclus à l'inscription)
  base,       // 1 000 CFA / mois
  elite,      // 2 500 CFA / mois
  premium,    // 5 000 CFA / mois
}

enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  pending,
}

class SubscriptionModel {
  final String id;
  final String businessId;
  final String? planId; // Ajouté comme propriété
  final SubscriptionType type;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? gracePeriodEnd;
  final bool isTrial;
  final double amount;
  final String currency;
  final String? paymentMethod;
  final String? paymentReference;
  final Map<String, dynamic>? metadata;

  SubscriptionModel({
    required this.id,
    required this.businessId,
    this.planId,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.gracePeriodEnd,
    this.isTrial = false,
    required this.amount,
    this.currency = 'XOF',
    this.paymentMethod,
    this.paymentReference,
    this.metadata,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    // Logique pour déterminer le type selon le montant (amount) 
    // ou le champ 'type' si présent dans le JSON
    double amt = (json['amount'] as num?)?.toDouble() ?? 0.0;
    
    SubscriptionType detectedType;
    if (json['type'] != null) {
      detectedType = SubscriptionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SubscriptionType.trial,
      );
    } else {
      // Détection par montant si le champ type est absent
      if (amt >= 5000) detectedType = SubscriptionType.premium;
      else if (amt >= 2500) detectedType = SubscriptionType.elite;
      else if (amt >= 1000) detectedType = SubscriptionType.base;
      else detectedType = SubscriptionType.trial;
    }

    return SubscriptionModel(
      id: json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      planId: json['plan_id'],
      type: detectedType,
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.expired,
      ),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      gracePeriodEnd: json['grace_period_end'] != null
          ? DateTime.parse(json['grace_period_end'])
          : null,
      isTrial: json['is_trial'] ?? false,
      amount: amt,
      currency: json['currency'] ?? 'XOF',
      paymentMethod: json['payment_method'],
      paymentReference: json['payment_reference'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'plan_id': planId,
      'type': type.name,
      'status': status.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'grace_period_end': gracePeriodEnd?.toIso8601String(),
      'is_trial': isTrial,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'metadata': metadata,
    };
  }

  // --- LOGIQUE MÉTIER ---

  bool get isValid {
    final now = DateTime.now();
    if (status == SubscriptionStatus.cancelled) return false;
    if (status == SubscriptionStatus.active && now.isBefore(endDate)) return true;
    if (gracePeriodEnd != null && now.isBefore(gracePeriodEnd!)) return true;
    return false;
  }

  int get daysRemaining {
    if (!isValid) return 0;
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  bool get isInGracePeriod {
    if (gracePeriodEnd == null) return false;
    final now = DateTime.now();
    return now.isAfter(endDate) && now.isBefore(gracePeriodEnd!);
  }

  String get alertMessage {
    if (isInGracePeriod) {
      final days = gracePeriodEnd!.difference(DateTime.now()).inDays;
      return '⚠️ Période de grâce: $days jours restants';
    }
    if (daysRemaining <= 0) return '❌ Abonnement expiré';
    if (daysRemaining <= 3) return '🔴 Expire dans $daysRemaining jours';
    if (daysRemaining <= 7) return '🟠 Expire dans $daysRemaining jours';
    if (isTrial) return '🟢 Essai: $daysRemaining jours restants';
    return '🟢 Actif: $daysRemaining jours restants';
  }

  SubscriptionModel copyWith({
    String? id,
    String? businessId,
    String? planId,
    SubscriptionType? type,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? gracePeriodEnd,
    bool? isTrial,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? paymentReference,
    Map<String, dynamic>? metadata,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      planId: planId ?? this.planId,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      gracePeriodEnd: gracePeriodEnd ?? this.gracePeriodEnd,
      isTrial: isTrial ?? this.isTrial,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      metadata: metadata ?? this.metadata,
    );
  }
}

