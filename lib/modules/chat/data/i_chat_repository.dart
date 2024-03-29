import 'package:cuidapet_api/entities/chat.dart';

abstract class IChatRepository {
  Future<int> startChat(int scheduleId);
  Future<Chat?> findChatById(int chatId);
  Future<List<Chat>> getChatsByUser(int userId);
  Future<List<Chat>> getChatsBySupplier(int supplierId);
  Future<void> endChat(int chatId);
}
