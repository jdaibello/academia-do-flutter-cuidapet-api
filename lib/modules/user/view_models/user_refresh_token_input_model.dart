import 'package:cuidapet_api/application/helpers/i_request_mapping.dart';

class UserRefreshTokenInputModel extends IRequestMapping {
  int user;
  int? supplier;
  String accessToken;
  late String refreshToken;

  UserRefreshTokenInputModel({
    required this.user,
    this.supplier,
    required this.accessToken,
    required String dataRequest,
  }) : super(dataRequest);

  @override
  void map() {
    refreshToken = data['refresh_token'];
  }
}
