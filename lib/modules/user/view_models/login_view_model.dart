import 'package:cuidapet_api/application/helpers/i_request_mapping.dart';

class LoginViewModel extends IRequestMapping {
  late String login;
  late String password;
  late bool socialLogin;
  late String avatar;
  late String socialType;
  late String socialKey;
  late bool supplierUser;

  LoginViewModel(String dataRequest) : super(dataRequest);

  @override
  void map() {
    login = data['login'];
    password = data['password'];
    socialLogin = data['social_login'];
    avatar = data['avatar'];
    socialType = data['social_type'];
    socialKey = data['social_key'];
    supplierUser = data['supplier_user'];
  }
}
