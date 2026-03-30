class BusinessModel {
  final String id;
  final String name;
  final String type;
  final String? address;
  final String? city;
  final String? country;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessModel({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.city,
    this.country,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}