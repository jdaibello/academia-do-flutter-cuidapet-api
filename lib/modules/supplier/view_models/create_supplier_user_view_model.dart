import 'package:cuidapet_api/application/helpers/i_request_mapping.dart';

class CreateSupplierUserViewModel extends IRequestMapping {
  late String supplierName;
  late String email;
  late String password;
  late int category;

  CreateSupplierUserViewModel(String dataRequest) : super(dataRequest);

  @override
  void map() {
    supplierName = data['supplier_name'];
    email = data['email'];
    password = data['password'];
    category = data['category_id'];
  }
}
