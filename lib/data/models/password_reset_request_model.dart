class PasswordResetRequestModel {
  final String id;
  final String? userId;
  final String phoneNumber;
  final String status;        // pending | validated | rejected
  final DateTime createdAt;
  final DateTime? validatedAt;

  PasswordResetRequestModel({
    required this.id,
    this.userId,
    required this.phoneNumber,
    required this.status,
    required this.createdAt,
    this.validatedAt,
  });

  factory PasswordResetRequestModel.fromJson(Map<String, dynamic> json) =>
      PasswordResetRequestModel(
        id: json['id'],
        userId: json['user_id'],
        phoneNumber: json['phone_number'],
        status: json['status'] ?? 'pending',
        createdAt: DateTime.parse(json['created_at']),
        validatedAt: json['validated_at'] != null
            ? DateTime.parse(json['validated_at'])
            : null,
      );
}