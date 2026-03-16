class User {
  final String id;
  final String phoneNumber;
  final String password;
  final String businessId;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? email;
  final bool isActive;

  User({
    required this.id,
    required this.phoneNumber,
    required this.password,
    required this.businessId,
    required this.role,
    this.firstName,
    this.lastName,
    this.email,
    this.isActive = true,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      phoneNumber: map['phone_number'] as String,
      password: map['password'] as String,
      businessId: map['business_id'] as String,
      role: map['role'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      email: map['email'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'password': password,
      'business_id': businessId,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'is_active': isActive,
    };
  }
}
