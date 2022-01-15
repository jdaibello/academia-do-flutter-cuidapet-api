import 'package:cuidapet_api/application/helpers/i_request_mapping.dart';

enum NotificationUserType { user, supplier }

class ChatNotifyViewModel extends IRequestMapping {
  late int chat;
  late String message;
  late NotificationUserType notificationUserType;

  ChatNotifyViewModel(String dataRequest) : super(dataRequest);

  @override
  void map() {
    chat = data['chat'];
    message = data['message'];

    String notificationTypeRequest = data['to'];

    notificationUserType = notificationTypeRequest.toLowerCase() == 'u'
        ? NotificationUserType.user
        : NotificationUserType.supplier;
  }
}
