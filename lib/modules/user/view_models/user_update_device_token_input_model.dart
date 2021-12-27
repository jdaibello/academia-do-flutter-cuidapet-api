import 'package:cuidapet_api/application/helpers/i_request_mapping.dart';
import 'package:cuidapet_api/modules/user/view_models/platform.dart';

class UserUpdateDeviceTokenInputModel extends IRequestMapping {
  int userId;
  late String token;
  late Platform platform;

  UserUpdateDeviceTokenInputModel({
    required this.userId,
    required String dataRequest,
  }) : super(dataRequest);

  @override
  void map() {
    token = data['token'];
    platform = data['platform'].toString().toLowerCase() == 'ios'
        ? Platform.ios
        : Platform.android;
  }
}
