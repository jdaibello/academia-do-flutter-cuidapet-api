import 'package:cuidapet_api/application/database/i_database_connection.dart';
import 'package:cuidapet_api/application/exceptions/database_exception.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:injectable/injectable.dart';
import 'package:mysql1/mysql1.dart';

import './i_chat_repository.dart';

@LazySingleton(as: IChatRepository)
class ChatRepository implements IChatRepository {
  final IDatabaseConnection connection;
  final ILogger log;

  ChatRepository({required this.connection, required this.log});

  @override
  Future<int> startChat(int scheduleId) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final result = await conn.query(
        '''
          INSERT INTO chats(agendamento_id, status, data_criacao) 
          VALUES(?, ?, ?)
        ''',
        [
          scheduleId,
          'A',
          DateTime.now().toIso8601String(),
        ],
      );

      return result.insertId!;
    } on MySqlException catch (e, s) {
      log.error('Error when starting the chat', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }
}
