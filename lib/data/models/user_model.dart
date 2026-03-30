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

  String get fullName => '$firstName $lastName';
  bool get isAdmin => role == 'admin';
}
