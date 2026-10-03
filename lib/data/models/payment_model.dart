class PaymentModel {
  final String id;
  final String? userId;
  final String? businessId;
  final String planType; // base | medium | elite | premium
  final double amount;
  final String currency;
  final String? paymentMethod;
  final String? phoneNumber;
  final String? reference;
  final String? businessCode; // 🆕
  final String status; // pending | validated | rejected
  final DateTime createdAt;
  final DateTime? validatedAt;

  PaymentModel({
    required this.id,
    this.userId,
    this.businessId,
    required this.planType,
    required this.amount,
    this.currency = 'XOF',
    this.paymentMethod,
    this.phoneNumber,
    this.reference,
    this.businessCode,
    required this.status,
    required this.createdAt,
    this.validatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'],
        userId: json['user_id'],
        businessId: json['business_id'],
        planType: json['plan_type'] ?? 'base',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] ?? 'XOF',
        paymentMethod: json['payment_method'],
        phoneNumber: json['phone_number'],
        reference: json['payment_reference'] ?? json['reference'],
        businessCode: json['business_code'],
        status: json['status'] ?? 'pending',
        createdAt: DateTime.parse(json['created_at']),
        validatedAt: json['validated_at'] != null
            ? DateTime.parse(json['validated_at'])
            : null,
      );
}