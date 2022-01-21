import 'dart:convert';

import 'package:cuidapet_api/application/exceptions/database_exception.dart';
import 'package:cuidapet_api/application/exceptions/user_exists_exception.dart';
import 'package:cuidapet_api/application/exceptions/user_not_found_exception.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/entities/user.dart';
import 'package:cuidapet_api/modules/user/data/user_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../core/fixture/fixture_reader.dart';
import '../../../core/log/mock_logger.dart';
import '../../../core/mysql/mysql_mocks.dart';

void main() {
  late MockDatabaseConnection database;
  late ILogger log;
  late UserRepository userRepository;

  setUp(() {
    database = MockDatabaseConnection();
    log = MockLogger();
    userRepository = UserRepository(connection: database, log: log);
  });

  group('Group test findById', () {
    test('should return user by id', () async {
      //Arrange
      final userId = 1;
      final userFixtureDB = FixtureReader.getJsonData(
        'modules/user/data/fixture/find_by_id_success_fixture.json',
      );

      final mockResults = MockResults(userFixtureDB, [
        'ios_token',
        'android_token',
        'refresh_token',
        'img_avatar',
      ]);

      database.mockQuery(mockResults);

      final usersMap = jsonDecode(userFixtureDB);
      final userExpected = User(
        id: usersMap['id'],
        email: usersMap['email'],
        registerType: usersMap['tipo_cadastro'],
        iosToken: usersMap['ios_token'],
        androidToken: usersMap['android_token'],
        refreshToken: usersMap['refresh_token'],
        imageAvatar: usersMap['img_avatar'],
        supplierId: usersMap['fornecedor_id'],
      );

      //Act
      final user = await userRepository.findById(userId);

      //Assert
      expect(user, isA<User>());
      expect(user, userExpected);
      database.verifyConnectionClose();
    });

    test('should return exception UserNotFoundException option 1', () async {
      //Arrange
      final id = 1;
      final mockResults = MockResults();
      database.mockQuery(mockResults, [id]);
      final userRepository = UserRepository(connection: database, log: log);

      //Act
      var call = userRepository.findById;

      //Assert
      expect(() => call(id), throwsA(isA<UserNotFoundException>()));
      await Future.delayed(Duration(seconds: 1));
      database.verifyConnectionClose();
    });

    test('should return exception UserNotFoundException option 2', () async {
      //Arrange
      final id = 1;
      final mockResults = MockResults();
      database.mockQuery(mockResults, [id]);
      final userRepository = UserRepository(connection: database, log: log);

      //Act
      try {
        await userRepository.findById(id);
      } catch (e) {
        if (e is UserNotFoundException) {
        } else {
          fail('Exception errada, deveria retornar um UserNotFoundException');
        }
      }

      //Assert
      database.verifyConnectionClose();
    });
  });

  group('Group test create user', () {
    test('should create user successfully', () async {
      // Arrange
      final userId = 1;
      final mockResults = MockResults();
      when(() => mockResults.insertId).thenReturn(userId);
      database.mockQuery(mockResults);

      final userInsert = User(
        email: 'joao.pedro@gmail.com',
        registerType: 'APP',
        imageAvatar: '',
        password: '123123',
      );

      final userExpected = User(
        id: userId,
        email: 'joao.pedro@gmail.com',
        registerType: 'APP',
        imageAvatar: '',
        password: '',
      );

      // Act
      final user = await userRepository.createUser(userInsert);

      // Assert
      expect(user, userExpected);
    });

    test('should throw DatabaseException', () async {
      // Arrange
      database.mockQueryException();

      // Act
      var call = userRepository.createUser;

      // Assert
      expect(() => call(User()), throwsA(isA<DatabaseException>()));
    });

    test('should throw UserExistsException', () async {
      // Arrange
      final exception = MockMysqlException();
      when(() => exception.message).thenReturn('usuario.email_UNIQUE');
      database.mockQueryException(exception);

      // Act
      var call = userRepository.createUser;

      // Assert
      expect(() => call(User()), throwsA(isA<UserExistsException>()));
    });
  });
}
