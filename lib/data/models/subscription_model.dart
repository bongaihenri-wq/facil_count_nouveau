import 'package:flutter/foundation.dart';

enum SubscriptionType {
  trial,      // 14 jours - Test
  monthly,    // 30 jours - 5 000 CFA
  quarterly,  // 90 jours - 13 500 CFA
  semestrial, // 180 jours - 25 000 CFA ⭐
  yearly,     // 365 jours - 48 000 CFA
  lifetime,   // À vie - Réservé admin - 150 000 CFA
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
  final SubscriptionType type;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? gracePeriodEnd;
  final bool isTrial;
  final Map<String, dynamic>? metadata;

  SubscriptionModel({
    required this.id,
    required this.businessId,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.gracePeriodEnd,
    this.isTrial = false,
    this.metadata,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      businessId: json['business_id'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SubscriptionType.trial,
      ),
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
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'type': type.name,
      'status': status.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'grace_period_end': gracePeriodEnd?.toIso8601String(),
      'is_trial': isTrial,
      'metadata': metadata,
    };
  }

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
    return endDate.difference(now).inDays;
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
    SubscriptionType? type,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? gracePeriodEnd,
    bool? isTrial,
    Map<String, dynamic>? metadata,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      gracePeriodEnd: gracePeriodEnd ?? this.gracePeriodEnd,
      isTrial: isTrial ?? this.isTrial,
      metadata: metadata ?? this.metadata,
    );
  }
}