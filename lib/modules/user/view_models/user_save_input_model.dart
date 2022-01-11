import 'package:cuidapet_api/application/helpers/i_request_mapping.dart';

class UserSaveInputModel extends IRequestMapping {
  late String email;
  late String password;
  int? supplierId;

  UserSaveInputModel({
    required this.email,
    required this.password,
    this.supplierId,
  }) : super.empty();

  UserSaveInputModel.requestMapping(String dataRequest) : super(dataRequest);

  @override
  void map() {
    email = data['email'];
    password = data['password'];
  }
}
