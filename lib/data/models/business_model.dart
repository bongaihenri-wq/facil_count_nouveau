// ❌ SUPPRIMEZ CES LIGNES :
// import 'package:json_annotation/json_annotation.dart';
// part 'business_model.g.dart';
// @JsonSerializable()

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

  // ✅ FROMJSON MANUEL
  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  // ✅ TOJSON MANUEL
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'address': address,
    'city': city,
    'country': country,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
