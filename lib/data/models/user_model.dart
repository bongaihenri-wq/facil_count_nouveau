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
  });

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
    );
  }

  // 🟢 Concaténation propre du nom complet
  String get fullName {
    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();
    if (trimmedFirst.isEmpty && trimmedLast.isEmpty) return 'Utilisateur';
    return '$trimmedFirst $trimmedLast'.trim();
  }

  // 🟢 Retourne la première lettre sécurisée (évite les crashs si le nom est vide)
  String get initial {
    if (firstName.trim().isNotEmpty) {
      return firstName.trim().substring(0, 1).toUpperCase();
    } else if (lastName.trim().isNotEmpty) {
      return lastName.trim().substring(0, 1).toUpperCase();
    }
    return 'U'; // Par défaut
  }

  bool get isAdmin => role == 'admin';

  // 🟢 Très utile pour mettre à jour un utilisateur dans Riverpod
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
    );
  }
}