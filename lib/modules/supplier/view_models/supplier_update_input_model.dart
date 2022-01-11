import 'package:cuidapet_api/application/helpers/i_request_mapping.dart';

class SupplierUpdateInputModel extends IRequestMapping {
  int supplierId;
  late String name;
  late String logo;
  late String address;
  late String phone;
  late double latitude;
  late double longitude;
  late int categoryId;

  SupplierUpdateInputModel({
    required this.supplierId,
    required String dataRequest,
  }) : super(dataRequest);

  @override
  void map() {
    name = data['name'];
    logo = data['logo'];
    address = data['address'];
    phone = data['phone'];
    longitude = data['longitude'];
    latitude = data['latitude'];
    categoryId = data['category'];
  }
}
