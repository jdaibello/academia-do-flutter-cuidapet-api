import 'package:cuidapet_api/entities/category.dart';

class Supplier {
  final int? id;
  final String? name;
  final String? logo;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final Category? category;

  Supplier({
    this.id,
    this.name,
    this.logo,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.category,
  });

  Supplier copyWith({
    int? id,
    String? name,
    String? logo,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    Category? category,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
    );
  }
}
