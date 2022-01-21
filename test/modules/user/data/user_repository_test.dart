import 'dart:convert';

import 'package:cuidapet_api/application/exceptions/database_exception.dart';
import 'package:cuidapet_api/application/exceptions/user_exists_exception.dart';
import 'package:cuidapet_api/application/exceptions/user_not_found_exception.dart';
import 'package:cuidapet_api/application/helpers/crypt_helper.dart';
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
      await Future.delayed(Duration(milliseconds: 200));
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
      database.verifyConnectionClose();
    });

    test('should throw DatabaseException', () async {
      // Arrange
      database.mockQueryException();

      // Act
      var call = userRepository.createUser;

      // Assert
      expect(() => call(User()), throwsA(isA<DatabaseException>()));
      await Future.delayed(Duration(milliseconds: 200));
      database.verifyConnectionClose();
    });

    test('should throw UserExistsException', () async {
      // Arrange
      final exception = MockMysqlException();
      when(() => exception.message).thenReturn('usuario.email_UNIQUE');
      database.mockQueryException(mockException: exception);

      // Act
      var call = userRepository.createUser;

      // Assert
      expect(() => call(User()), throwsA(isA<UserExistsException>()));
      await Future.delayed(Duration(milliseconds: 200));
      database.verifyConnectionClose();
    });
  });

  group('Group test login with email and password', () {
    test('should login with email and password', () async {
      //Arrange
      final userFixtureDB = FixtureReader.getJsonData(
        'modules/user/data/fixture/login_with_email_and_password_successfully.json',
      );

      final mockResults = MockResults(userFixtureDB, [
        'ios_token',
        'android_token',
        'refresh_token',
        'img_avatar',
      ]);

      final email = 'joao.pedro@gmail.com';
      final password = '123123';

      database.mockQuery(
        mockResults,
        [
          email,
          CryptHelper.generateSha256Hash(password),
        ],
      );

      final userMap = jsonDecode(userFixtureDB);
      final userExpected = User(
        id: userMap['id'],
        email: userMap['email'],
        registerType: userMap['tipo_cadastro'],
        iosToken: userMap['ios_token'],
        androidToken: userMap['android_token'],
        refreshToken: userMap['refresh_token'],
        imageAvatar: userMap['img_avatar'],
        supplierId: userMap['fornecedor_id'],
      );

      //Act
      final user = await userRepository.loginWithEmailAndPassword(
        email,
        password,
        false,
      );

      //Assert
      expect(user, userExpected);
      database.verifyConnectionClose();
    });

    test(
        'should login with email and password and return exception UserNotFoundExpection',
        () async {
      //Arrange
      final mockResults = MockResults();

      final email = 'joao.pedro@gmail.com';
      final password = '123123';

      database.mockQuery(
        mockResults,
        [
          email,
          CryptHelper.generateSha256Hash(password),
        ],
      );

      //Act
      final call = userRepository.loginWithEmailAndPassword;

      //Assert
      expect(() => call(email, password, false),
          throwsA(isA<UserNotFoundException>()));

      await Future.delayed(Duration(milliseconds: 200));
      database.verifyConnectionClose();
    });

    test(
        'should login with email and password and return exception DatabaseException',
        () async {
      //Arrange
      final email = 'joao.pedro@gmail.com';
      final password = '123123';

      database.mockQueryException(params: [
        email,
        CryptHelper.generateSha256Hash(password),
      ]);

      //Act
      final call = userRepository.loginWithEmailAndPassword;

      //Assert
      expect(() => call(email, password, false),
          throwsA(isA<DatabaseException>()));

      await Future.delayed(Duration(milliseconds: 200));
      database.verifyConnectionClose();
    });
  });

  group('Group test login with email and social key', () {
    test('should login with email and social key successfully', () async {
      //Arrange
      final userFixtureDB = FixtureReader.getJsonData(
        'modules/user/data/fixture/login_with_email_and_social_key_successfully.json',
      );

      final mockResults = MockResults(
        userFixtureDB,
        [
          'ios_token',
          'android_token',
          'refresh_token',
          'img_avatar',
        ],
      );

      final email = 'joao.pedro@gmail.com';
      final socialKey = '123';
      final socialType = 'Facebook';
      final params = [email];

      database.mockQuery(mockResults, params);

      final userMap = jsonDecode(userFixtureDB);
      final userExpected = User(
        id: userMap['id'],
        email: userMap['email'],
        registerType: userMap['tipo_cadastro'],
        iosToken: userMap['ios_token'],
        androidToken: userMap['android_token'],
        refreshToken: userMap['refresh_token'],
        imageAvatar: userMap['img_avatar'],
        supplierId: userMap['fornecedor_id'],
      );

      //Act
      final user = await userRepository.loginByEmailAndSocialKey(
        email,
        socialKey,
        socialType,
      );

      //Assert
      expect(user, userExpected);
      database.verifyQueryCalled(params: params);
      database.verifyQueryNeverCalled(params: [
        socialKey,
        socialType,
        userMap['id'],
      ]);
      database.verifyConnectionClose();
    });

    test(
        'should login with email and social key successfully and update social id',
        () async {
      //Arrange
      final userFixtureDB = FixtureReader.getJsonData(
        'modules/user/data/fixture/login_with_email_and_social_key_successfully.json',
      );

      final mockResults = MockResults(
        userFixtureDB,
        [
          'ios_token',
          'android_token',
          'refresh_token',
          'img_avatar',
        ],
      );

      final userMap = jsonDecode(userFixtureDB);

      final email = 'joao.pedro@gmail.com';
      final socialKey = 'G123';
      final socialType = 'Google';
      final paramsSelect = [email];
      final paramsUpdate = <Object>[
        socialKey,
        socialType,
        userMap['id'],
      ];

      database.mockQuery(mockResults, paramsSelect);
      database.mockQuery(mockResults, paramsUpdate);

      final userExpected = User(
        id: userMap['id'],
        email: userMap['email'],
        registerType: userMap['tipo_cadastro'],
        iosToken: userMap['ios_token'],
        androidToken: userMap['android_token'],
        refreshToken: userMap['refresh_token'],
        imageAvatar: userMap['img_avatar'],
        supplierId: userMap['fornecedor_id'],
      );

      //Act
      final user = await userRepository.loginByEmailAndSocialKey(
        email,
        socialKey,
        socialType,
      );

      //Assert
      expect(user, userExpected);
      database.verifyQueryCalled(params: paramsSelect);
      database.verifyQueryCalled(params: paramsUpdate);
      database.verifyConnectionClose();
    });

    test(
        'should login with email and social key and throws UserNotFoundException',
        () async {
      //Arrange
      final mockResults = MockResults();

      final email = 'joao.pedro@gmail.com';
      final socialKey = 'G123';
      final socialType = 'Google';
      final paramsSelect = [email];

      database.mockQuery(mockResults, paramsSelect);

      //Act
      final call = userRepository.loginByEmailAndSocialKey;

      //Assert
      expect(() => call(email, socialKey, socialType),
          throwsA(isA<UserNotFoundException>()));
      await Future.delayed(Duration(milliseconds: 200));
      database.verifyQueryCalled(params: paramsSelect);
      database.verifyConnectionClose();
    });

    test('should login with email and social key and throws DatabaseException',
        () async {
      //Arrange
      final email = 'joao.pedro@gmail.com';
      final socialKey = 'G123';
      final socialType = 'Google';
      final paramsSelect = [email];

      database.mockQueryException(params: paramsSelect);

      //Act
      final call = userRepository.loginByEmailAndSocialKey;

      //Assert
      expect(() => call(email, socialKey, socialType),
          throwsA(isA<DatabaseException>()));
      await Future.delayed(Duration(milliseconds: 200));
      database.verifyQueryCalled(params: paramsSelect);
      database.verifyConnectionClose();
    });
  });
}
