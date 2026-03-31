class InvoiceModel {
  final String id;
  final String type; // 'Achats', 'Ventes', 'Dépenses'
  final String number;
  final DateTime invoiceDate;
  final double amount;
  final String status; // 'Payée', 'En attente', 'Annulée'
  final String? imageUrl;
  final String? supplier;
  final String? notes;
  final bool locked;
  final DateTime createdAt;
  final String? businessId;

  InvoiceModel({
    required this.id,
    required this.type,
    required this.number,
    required this.invoiceDate,
    required this.amount,
    required this.status,
    this.imageUrl,
    this.supplier,
    this.notes,
    this.locked = false,
    required this.createdAt,
    this.businessId,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      number: json['number'] ?? '',
      invoiceDate: DateTime.parse(json['invoice_date']),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] ?? 'En attente',
      imageUrl: json['image_url'],
      supplier: json['supplier'],
      notes: json['notes'],
      locked: json['locked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      businessId: json['business_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'number': number,
      'invoice_date': invoiceDate.toIso8601String(),
      'amount': amount,
      'status': status,
      'image_url': imageUrl,
      'supplier': supplier,
      'notes': notes,
      'locked': locked,
      'created_at': createdAt.toIso8601String(),
      'business_id': businessId,
    };
  }

  InvoiceModel copyWith({
    String? id,
    String? type,
    String? number,
    DateTime? invoiceDate,
    double? amount,
    String? status,
    String? imageUrl,
    String? supplier,
    String? notes,
    bool? locked,
    DateTime? createdAt,
    String? businessId,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      type: type ?? this.type,
      number: number ?? this.number,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      supplier: supplier ?? this.supplier,
      notes: notes ?? this.notes,
      locked: locked ?? this.locked,
      createdAt: createdAt ?? this.createdAt,
      businessId: businessId ?? this.businessId,
    );
  }
}
