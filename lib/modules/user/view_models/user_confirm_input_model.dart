import 'package:cuidapet_api/application/exceptions/request_validation_exception.dart';
import 'package:cuidapet_api/application/helpers/i_request_mapping.dart';

class UserConfirmInputModel extends IRequestMapping {
  int userId;
  String accessToken;
  String? iosDevideToken;
  String? androidDeviceToken;

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

  void validateRequest() {
    final errors = <String, String>{};

    if (iosDevideToken == null && androidDeviceToken == null) {
      errors['ios_token or android_token'] = 'required';
    }

    if (errors.isNotEmpty) {
      throw RequestValidationException(errors);
    }
  }
}
