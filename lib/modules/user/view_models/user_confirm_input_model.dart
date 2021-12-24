import 'package:cuidapet_api/application/helpers/i_request_mapping.dart';

class UserConfirmInputModel extends IRequestMapping {
  int userId;
  String accessToken;
  late String iosDevideToken;
  late String androidDeviceToken;

  UserConfirmInputModel({
    required this.userId,
    required this.accessToken,
    required String data,
  }) : super(data);

  @override
  void map() {
    iosDevideToken = data['ios_token'];
    androidDeviceToken = data['android_token'];
  }
}
