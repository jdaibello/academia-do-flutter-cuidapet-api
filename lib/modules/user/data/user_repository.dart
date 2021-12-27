import 'package:cuidapet_api/application/database/i_database_connection.dart';
import 'package:cuidapet_api/application/exceptions/database_exception.dart';
import 'package:cuidapet_api/application/exceptions/user_exists_exception.dart';
import 'package:cuidapet_api/application/exceptions/user_not_found_exception.dart';
import 'package:cuidapet_api/application/helpers/crypt_helper.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/entities/user.dart';
import 'package:cuidapet_api/modules/user/view_models/platform.dart';
import 'package:injectable/injectable.dart';
import 'package:mysql1/mysql1.dart';

import './i_user_repository.dart';

@LazySingleton(as: IUserRepository)
class UserRepository implements IUserRepository {
  final IDatabaseConnection connection;
  final ILogger log;

  UserRepository({required this.connection, required this.log});

  @override
  Future<User> createUser(User user) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();
      final query = '''
            INSERT usuario (email, tipo_cadastro, img_avatar, senha, fornecedor_id, social_id) 
            VALUES (?, ?, ?, ?, ?, ?)
          ''';

      final result = await conn.query(query, [
        user.email,
        user.registerType,
        user.imageAvatar,
        CryptHelper.generateSha256Hash(user.password ?? ''),
        user.supplierId,
        user.socialKey,
      ]);

      final userId = result.insertId;
      return user.copyWith(id: userId, password: null);
    } on MySqlException catch (e, s) {
      if (e.message.contains('usuario.email_UNIQUE')) {
        log.error('User already registered in the database', e, s);
        throw UserExistsException();
      }

      log.error('Error when creating user', e, s);
      throw DatabaseException(
        message: 'Error when creating user',
        exception: e,
      );
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<User> loginWithEmailAndPassword(
    String email,
    String password,
    bool supplierUser,
  ) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();
      var query = '''
        SELECT * 
        FROM usuario
        WHERE email = ? AND senha = ?
      ''';

      if (supplierUser) {
        query += ' AND fornecedor_id IS NOT NULL';
      } else {
        query += ' AND fornecedor_id IS NULL';
      }

      final result = await conn.query(query, [
        email,
        CryptHelper.generateSha256Hash(password),
      ]);

      if (result.isEmpty) {
        log.error('Invalid e-mail or password');
        throw UserNotFoundException(message: 'Invalid e-mail or password');
      } else {
        final userSqlData = result.first;
        return User(
          id: userSqlData['id'] as int,
          email: userSqlData['email'],
          registerType: userSqlData['tipo_cadastro'],
          iosToken: (userSqlData['ios_token'] as Blob?)?.toString(),
          androidToken: (userSqlData['android_token'] as Blob?)?.toString(),
          refreshToken: (userSqlData['refresh_token'] as Blob?)?.toString(),
          imageAvatar: (userSqlData['img_avatar'] as Blob?)?.toString(),
          supplierId: userSqlData['fornecedor_id'],
        );
      }
    } on MySqlException catch (e, s) {
      log.error('Error when logging in', e, s);
      throw DatabaseException(message: e.message);
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<User> loginByEmailAndSocialKey(
    String email,
    String socialKey,
    String socialType,
  ) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final result = await conn.query(
        'SELECT * FROM usuario WHERE email = ?',
        [email],
      );

      if (result.isEmpty) {
        throw UserNotFoundException(message: 'User not found');
      } else {
        final dataMysql = result.first;

        if (dataMysql['social_id'] == null ||
            dataMysql['social_id'] != socialKey) {
          await conn.query(
            '''
              UPDATE usuario 
              SET social_id = ?, tipo_cadastro = ? 
              WHERE id = ?
            ''',
            [
              socialKey,
              socialType,
              dataMysql['id'],
            ],
          );
        }

        return User(
          id: dataMysql['id'] as int,
          email: dataMysql['email'],
          registerType: dataMysql['tipo_cadastro'],
          iosToken: (dataMysql['ios_token'] as Blob?)?.toString(),
          androidToken: (dataMysql['android_token'] as Blob?)?.toString(),
          refreshToken: (dataMysql['refresh_token'] as Blob?)?.toString(),
          imageAvatar: (dataMysql['img_avatar'] as Blob?)?.toString(),
          supplierId: dataMysql['fornecedor_id'],
        );
      }
    } on MySqlException catch (e, s) {
      log.error('Error while logging in with social network', e, s);
      throw DatabaseException();
    } finally {
      conn?.close();
    }
  }

  @override
  Future<void> updateUserDeviceTokenAndRefreshToken(User user) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final setParams = {};

      if (user.iosToken != null) {
        setParams.putIfAbsent('ios_token', () => user.iosToken);
      } else {
        setParams.putIfAbsent('android_token', () => user.androidToken);
      }

      final query = '''
        UPDATE usuario
        SET 
          ${setParams.keys.elementAt(0)} = ?, 
          refresh_token = ? 
        WHERE id = ?
      ''';

      await conn.query(
        query,
        [
          setParams.values.elementAt(0),
          user.refreshToken!,
          user.id!,
        ],
      );
    } on MySqlException catch (e, s) {
      log.error('Error when confirming login', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> updateRefreshToken(User user) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      await conn.query(
        'UPDATE usuario SET refresh_token = ? WHERE id = ?',
        [
          user.refreshToken!,
          user.id!,
        ],
      );
    } on MySqlException catch (e, s) {
      log.error('Error while updating refresh token', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<User> findById(int id) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final result = await conn.query(
        '''
          SELECT 
            id, email, tipo_cadastro, ios_token, android_token, 
            refresh_token, img_avatar, fornecedor_id 
          FROM usuario
          WHERE id = ?
        ''',
        [id],
      );

      if (result.isEmpty) {
        log.error('User not found with id [$id]');
        throw UserNotFoundException(message: 'User not found with id [$id]');
      } else {
        final dataMysql = result.first;

        return User(
          id: dataMysql['id'] as int,
          email: dataMysql['email'],
          registerType: dataMysql['tipo_cadastro'],
          iosToken: (dataMysql['ios_token'] as Blob?)?.toString(),
          androidToken: (dataMysql['android_token'] as Blob?)?.toString(),
          refreshToken: (dataMysql['refresh_token'] as Blob?)?.toString(),
          imageAvatar: (dataMysql['img_avatar'] as Blob?)?.toString(),
          supplierId: dataMysql['fornecedor_id'],
        );
      }
    } on MySqlException catch (e, s) {
      log.error('Error while finding user by id', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> updateUrlAvatar(int id, String urlAvatar) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      await conn.query(
        'UPDATE usuario SET img_avatar = ? WHERE id = ?',
        [urlAvatar, id],
      );
    } on MySqlException catch (e, s) {
      log.error('Error while updating avatar', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> updateDeviceToken(
    int id,
    String token,
    Platform platform,
  ) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      var set = '';
      if (platform == Platform.ios) {
        set = 'ios_token = ?';
      } else {
        set = 'android_token = ?';
      }

      final query = 'UPDATE usuario SET $set WHERE id = ?';
      await conn.query(query, [token, id]);
    } on MySqlException catch (e, s) {
      log.error('Error when updating device token', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }
}
