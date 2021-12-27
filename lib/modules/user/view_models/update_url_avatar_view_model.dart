import 'package:cuidapet_api/application/helpers/i_request_mapping.dart';

class UpdateUrlAvatarViewModel extends IRequestMapping {
  int userId;
  late String urlAvatar;

  UpdateUrlAvatarViewModel({
    required this.userId,
    required String dataRequest,
  }) : super(dataRequest);

  @override
  void map() {
    urlAvatar = data['url_avatar'];
  }
}
