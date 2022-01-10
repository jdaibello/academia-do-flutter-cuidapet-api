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
}
