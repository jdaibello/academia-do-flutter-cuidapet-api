import 'package:cuidapet_api/application/database/i_database_connection.dart';
import 'package:cuidapet_api/application/exceptions/database_exception.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/entities/chat.dart';
import 'package:cuidapet_api/entities/device_token.dart';
import 'package:cuidapet_api/entities/supplier.dart';
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

  @override
  Future<Chat?> findChatById(int chatId) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final query =
          '''
            SELECT 
              c.id,
              c.data_criacao,
              c.status,
              a.nome AS agendamento_nome,
              a.nome_pet AS  agendamento_nome_pet,
              a.fornecedor_id,
              a.usuario_id,
              f.nome AS fornec_nome,
              f.logo,
              uc.android_token AS user_android_token,
              uc.ios_token AS user_ios_token,
              uf.android_token AS fornec_android_token,
              uf.ios_token AS fornec_ios_token
            FROM chats AS c 
            INNER JOIN agendamento a ON a.id = c.agendamento_id 
            INNER JOIN fornecedor f ON f.id = a.fornecedor_id 
            -- Dados do usuário Cliente do petshop
            INNER JOIN usuario uc ON uc.id = a.usuario_id 
            -- Dados do usuário Fornecedor (O PETSHOP)
            INNER JOIN usuario uf ON uf.fornecedor_id = f.id 
            WHERE c.id = ?
          ''';

      final result = await conn.query(
        query,
        [chatId],
      );

      if (result.isNotEmpty) {
        final resultMySql = result.first;
        return Chat(
          id: resultMySql['id'],
          status: resultMySql['status'],
          name: resultMySql['agendamento_nome'],
          petName: resultMySql['agendamento_nome_pet'],
          supplier: Supplier(
            id: resultMySql['fornecedor_id'],
            name: resultMySql['fornec_nome'],
          ),
          userId: resultMySql['usuario_id'],
          userDeviceToken: DeviceToken(
            android: (resultMySql['user_android_token'] as Blob?)?.toString(),
            ios: (resultMySql['user_ios_token'] as Blob?)?.toString(),
          ),
          supplierDeviceToken: DeviceToken(
            android: (resultMySql['fornec_android_token'] as Blob?)?.toString(),
            ios: (resultMySql['fornec_ios_token'] as Blob?)?.toString(),
          ),
        );
      }
    } on MySqlException catch (e, s) {
      log.error('Error when finding chat data', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<List<Chat>> getChatsByUser(int userId) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final query =
          '''
            SELECT 
              c.id, c.data_criacao, c.status, 
              a.nome, a.nome_pet, a.fornecedor_id, a.usuario_id, 
              f.nome as fornec_nome, f.logo
            FROM chats AS c 
            INNER JOIN agendamento a ON a.id = c.agendamento_id 
            INNER JOIN fornecedor f ON f.id = a.fornecedor_id 
            WHERE a.usuario_id = ? AND c.status = 'A' 
            ORDER BY c.data_criacao
          ''';

      final result = await conn.query(query, [userId]);

      return result
          .map(
            (c) => Chat(
              id: c['id'],
              userId: c['usuario_id'],
              supplier: Supplier(
                id: c['fornecedor_id'],
                name: c['fornec_nome'],
                logo: (c['logo'] as Blob?)?.toString(),
              ),
              name: c['nome'],
              petName: c['nome_pet'],
              status: c['status'],
            ),
          )
          .toList();
    } on MySqlException catch (e, s) {
      log.error('Error when finding chats from a user', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<List<Chat>> getChatsBySupplier(int supplierId) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final query =
          '''
            SELECT 
              c.id, c.data_criacao, c.status, 
              a.nome, a.nome_pet, a.fornecedor_id, a.usuario_id, 
              f.nome as fornec_nome, f.logo
            FROM chats AS c 
            INNER JOIN agendamento a ON a.id = c.agendamento_id 
            INNER JOIN fornecedor f ON f.id = a.fornecedor_id 
            WHERE a.fornecedor_id = ? AND c.status = 'A' 
            ORDER BY c.data_criacao
          ''';

      final result = await conn.query(query, [supplierId]);

      return result
          .map(
            (c) => Chat(
              id: c['id'],
              userId: c['usuario_id'],
              supplier: Supplier(
                id: c['fornecedor_id'],
                name: c['fornec_nome'],
                logo: (c['logo'] as Blob?)?.toString(),
              ),
              name: c['nome'],
              petName: c['nome_pet'],
              status: c['status'],
            ),
          )
          .toList();
    } on MySqlException catch (e, s) {
      log.error('Error when finding chats from a supplier', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> endChat(int chatId) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      await conn.query(
        '''
          UPDATE chats SET status = 'F' WHERE id = ?
        ''',
        [chatId],
      );
    } on MySqlException catch (e, s) {
      log.error('Error when finishing the chat', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }
}
