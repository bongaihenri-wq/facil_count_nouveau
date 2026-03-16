class Business {
  final String id;
  final String name;
  final String type;
  final String? address;
  final String? city;
  final String? country;

  Business({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.city,
    this.country,
  });

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      address: map['address'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'city': city,
      'country': country,
    };
  }
}
