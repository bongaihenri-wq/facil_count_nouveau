class InvoiceModel {
  final String id;
  final String type; // Achats, Ventes, Dépenses
  final String? number;
  final DateTime invoiceDate;
  final double amount;
  final String status; // Payée, En attente, Annulée
  final String? imageUrl;
  final String? supplier; // Fournisseur ou Client
  final String? notes;
  final bool locked;
  final DateTime createdAt;

  InvoiceModel({
    required this.id,
    required this.type,
    this.number,
    required this.invoiceDate,
    required this.amount,
    required this.status,
    this.imageUrl,
    this.supplier,
    this.notes,
    this.locked = false,
    required this.createdAt,
  });

  // 1. Convertit un JSON venant de Supabase en objet Dart (InvoiceModel)
  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'Dépenses',
      number: json['number'],
      // Gestion sécurisée de la date de facture
      invoiceDate: json['invoice_date'] != null 
          ? DateTime.parse(json['invoice_date']) 
          : DateTime.now(),
      // Conversion sécurisée du montant en double (qu'il vienne en int ou double)
      amount: (json['amount'] is num) 
          ? (json['amount'] as num).toDouble() 
          : 0.0,
      status: json['status'] ?? 'En attente',
      imageUrl: json['image_url'],
      supplier: json['supplier'],
      notes: json['notes'],
      locked: json['locked'] ?? false,
      // Gestion sécurisée de la date de création
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  // 2. Convertit notre objet Dart en Map/JSON pour l'envoyer à Supabase
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
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
    };

    // On retire l'ID si la facture est vide (nouvelle facture), 
    // Supabase va s'occuper de générer un UUID automatiquement !
    if (id.isEmpty) {
      data.remove('id');
    }

    return data;
  }

  // 3. Permet de créer une copie de l'objet en modifiant seulement quelques champs
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
    );
  }
}
