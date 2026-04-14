import 'package:facil_count_nouveau/data/models/subscription_model.dart';

class UserModel {
  final String id;
  final String phoneNumber;
  final String password;
  final String businessId;
  final String role;
  final String firstName;
  final String lastName;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SubscriptionModel? subscription; // L'objet complet

  static const int trialDurationDays = 30;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.password,
    required this.businessId,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.subscription,
  });

  // --- LOGIQUE D'ACCÈS AMÉLIORÉE ---

  // L'utilisateur a accès s'il a un abonnement valide OU s'il est encore en essai
  bool get canAccessProFeatures {
    if (subscription != null && subscription!.isValid) return true;
    return !isTrialExpired;
  }

  // Identification précise du palier
  bool get isBaseUser => subscription?.type == SubscriptionType.base;
  bool get isEliteUser => subscription?.type == SubscriptionType.elite;
  bool get isPremiumUser => subscription?.type == SubscriptionType.premium;

  // --- FACTORY CORRIGÉ ---

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phoneNumber: json['phone_number'],
      password: json['password'],
      businessId: json['business_id'],
      role: json['role'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      // 🟢 CORRECTION : Il faut transformer le JSON de l'abonnement s'il existe
      subscription: json['subscription'] != null 
          ? SubscriptionModel.fromJson(json['subscription']) 
          : null,
    );
  }

  // --- GETTERS ---

  String get fullName {
    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();
    if (trimmedFirst.isEmpty && trimmedLast.isEmpty) return 'Utilisateur';
    return '$trimmedFirst $trimmedLast'.trim();
  }

  String get initial {
    if (firstName.trim().isNotEmpty) {
      return firstName.trim().substring(0, 1).toUpperCase();
    }
    return lastName.trim().isNotEmpty ? lastName.substring(0, 1).toUpperCase() : 'U';
  }

  bool get isAdmin => role == 'admin';

  int get daysSinceCreation => DateTime.now().difference(createdAt).inDays;
  int get trialDaysRemaining => (trialDurationDays - daysSinceCreation).clamp(0, trialDurationDays);
  bool get isTrialExpired => daysSinceCreation >= trialDurationDays;
  double get trialProgress => (trialDaysRemaining / trialDurationDays).clamp(0.0, 1.0);
  bool get hasSubscriptionAlert => !canAccessProFeatures || trialDaysRemaining <= 5;

  // --- COPY WITH (Mise à jour pour inclure subscription) ---

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? password,
    String? businessId,
    String? role,
    String? firstName,
    String? lastName,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    SubscriptionModel? subscription,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      businessId: businessId ?? this.businessId,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscription: subscription ?? this.subscription,
    );
  }
}
