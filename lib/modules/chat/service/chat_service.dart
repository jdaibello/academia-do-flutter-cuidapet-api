import 'package:cuidapet_api/application/facades/push_notification_facade.dart';
import 'package:cuidapet_api/entities/chat.dart';
import 'package:cuidapet_api/modules/chat/data/i_chat_repository.dart';
import 'package:cuidapet_api/modules/chat/view_models/chat_notify_view_model.dart';
import 'package:injectable/injectable.dart';

import './i_chat_service.dart';

@LazySingleton(as: IChatService)
class ChatService implements IChatService {
  final IChatRepository repository;
  final PushNotificationFacade pushNotificationFacade;

  ChatService({required this.repository, required this.pushNotificationFacade});

  @override
  Future<int> startChat(int scheduleId) => repository.startChat(scheduleId);

  @override
  Future<void> notifyChat(ChatNotifyViewModel model) async {
    final chat = await repository.findChatById(model.chat);

    if (chat != null) {
      switch (model.notificationUserType) {
        case NotificationUserType.user:
          _notifyUser(chat.userDeviceToken?.tokens, model, chat);
          break;
        case NotificationUserType.supplier:
          _notifyUser(chat.supplierDeviceToken?.tokens, model, chat);
          break;
        default:
          throw Exception('Notification type not found');
      }
    }
  }

  @override
  Future<List<Chat>> getChatsByUser(int userId) =>
      repository.getChatsByUser(userId);

  @override
  Future<List<Chat>> getChatsBySupplier(int supplierId) =>
      repository.getChatsBySupplier(supplierId);

  @override
  Future<void> endChat(int chatId) => repository.endChat(chatId);

  void _notifyUser(
    List<String?>? tokens,
    ChatNotifyViewModel model,
    Chat chat,
  ) {
    final payload = <String, dynamic>{
      'type': 'CHAT_MESSAGE',
      'chat': {
        'id': chat.id,
        'nome': chat.name,
        'fornecedor': {
          'nome': chat.supplier.name,
          'logo': chat.supplier.logo,
        }
      }
    };

    pushNotificationFacade.sendMessage(
      devices: tokens ?? [],
      title: 'Nova Mensagem',
      body: model.message,
      payload: payload,
    );
  }
}
