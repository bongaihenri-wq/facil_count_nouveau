import 'package:json_annotation/json_annotation.dart';

part 'business_model.g.dart';

@JsonSerializable()
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

  factory BusinessModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessModelFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessModelToJson(this);
}
