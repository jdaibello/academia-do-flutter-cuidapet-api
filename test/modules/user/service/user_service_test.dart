import 'package:cuidapet_api/application/exceptions/service_exception.dart';
import 'package:cuidapet_api/application/exceptions/user_not_found_exception.dart';
import 'package:cuidapet_api/application/helpers/jwt_helper.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/entities/user.dart';
import 'package:cuidapet_api/modules/user/data/i_user_repository.dart';
import 'package:cuidapet_api/modules/user/service/i_user_service.dart';
import 'package:cuidapet_api/modules/user/service/user_service.dart';
import 'package:cuidapet_api/modules/user/view_models/refresh_token_view_model.dart';
import 'package:cuidapet_api/modules/user/view_models/user_refresh_token_input_model.dart';
import 'package:dotenv/dotenv.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../core/log/mock_logger.dart';

class MockUserRepository extends Mock implements IUserRepository {}

void main() {
  late IUserRepository userRepository;
  late ILogger log;
  late IUserService userService;

  setUp(() {
    userRepository = MockUserRepository();
    log = MockLogger();
    userService = UserService(userRepository: userRepository, log: log);
    registerFallbackValue(User());
    load();
  });

  group('Group test login with email and password', () {
    test('should login with email and password successfully', () async {
      // Arrange
      final id = 1;
      final email = 'joao.pedro@gmail.com';
      final password = '123123';
      final supplierUser = false;

      final userMock = User(
        id: id,
        email: email,
      );

      when(() => userRepository.loginWithEmailAndPassword(
            email,
            password,
            supplierUser,
          )).thenAnswer((_) async => userMock);

      // Act
      final user = await userService.loginWithEmailAndPassword(
        email,
        password,
        supplierUser,
      );

      // Assert
      expect(user, userMock);
      verify(() => userRepository.loginWithEmailAndPassword(
          email, password, supplierUser)).called(1);
    });

    test(
        'should login with email and password and return UserNotFoundException',
        () async {
      // Arrange
      final email = 'joao.pedro@gmail.com';
      final password = '123123';
      final supplierUser = false;

      when(
        () => userRepository.loginWithEmailAndPassword(
          email,
          password,
          supplierUser,
        ),
      ).thenThrow(UserNotFoundException(message: 'User not found'));

      // Act
      final call = userService.loginWithEmailAndPassword;

      // Assert
      expect(() => call(email, password, supplierUser),
          throwsA(isA<UserNotFoundException>()));
      verify(() => userRepository.loginWithEmailAndPassword(
          email, password, supplierUser)).called(1);
    });
  });

  group('Group test login with social', () {
    test('should login with social successfully', () async {
      // Arrange
      final id = 1;
      final email = 'joao.pedro@gmail.com';
      final socialKey = 'G123';
      final socialType = 'GOOGLE';

      final userReturnLogin = User(
        id: id,
        email: email,
        socialKey: socialKey,
        registerType: socialType,
      );

      when(
        () => userRepository.loginByEmailAndSocialKey(
          email,
          socialKey,
          socialType,
        ),
      ).thenAnswer((_) async => userReturnLogin);

      // Act
      final user = await userService.loginWithSocial(
        email,
        '',
        socialType,
        socialKey,
      );

      // Assert
      expect(user, userReturnLogin);
      verify(() => userRepository.loginByEmailAndSocialKey(
          email, socialKey, socialType)).called(1);
    });

    test('should login with social with user not found and create a new user',
        () async {
      // Arrange
      final id = 1;
      final email = 'joao.pedro@gmail.com';
      final socialKey = 'G123';
      final socialType = 'GOOGLE';

      final userCreated = User(
        id: id,
        email: email,
        socialKey: socialKey,
        registerType: socialType,
      );

      when(
        () => userRepository.loginByEmailAndSocialKey(
          email,
          socialKey,
          socialType,
        ),
      ).thenThrow(UserNotFoundException(message: 'User not found'));

      when(() => userRepository.createUser(any<User>()))
          .thenAnswer((_) async => userCreated);

      // Act
      final user = await userService.loginWithSocial(
        email,
        '',
        socialType,
        socialKey,
      );

      // Assert
      expect(user, userCreated);
      verify(() => userRepository.loginByEmailAndSocialKey(
          email, socialKey, socialType)).called(1);
      verify(() => userRepository.createUser(any<User>())).called(1);
    });
  });

  group('Group test refresh token', () {
    test('should refresh token successfully', () async {
      // Arrange
      env['REFRESH_TOKEN_NOT_BEFORE_HOURS'] = '0';
      final userId = 1;
      final accessToken = JwtHelper.generateJWT(userId, null);
      final refreshToken = JwtHelper.refreshToken(accessToken);
      final model = UserRefreshTokenInputModel(
        user: userId,
        accessToken: accessToken,
        dataRequest: '{"refresh_token": "$refreshToken"}',
      );

      when(() => userRepository.updateRefreshToken(any()))
          .thenAnswer((_) async => _);

      // Act
      final responseToken = await userService.refreshToken(model);

      // Assert
      expect(responseToken, isA<RefreshTokenViewModel>());
      expect(responseToken.accessToken, isNotEmpty);
      expect(responseToken.refreshToken, isNotEmpty);
      verify(() => userRepository.updateRefreshToken(any())).called(1);
    });

    test('should try refresh token JWT but return validate error (Bearer)',
        () async {
      // Arrange
      final model = UserRefreshTokenInputModel(
        user: 1,
        accessToken: '',
        dataRequest: '{"refresh_token": ""}',
      );

      // Act
      final call = userService.refreshToken;

      // Assert
      expect(() => call(model), throwsA(isA<ServiceException>()));
    });

    test(
        'should try refresh token JWT but return validate error (JwtException)',
        () async {
      // Arrange
      final userId = 1;
      final accessToken = JwtHelper.generateJWT(userId, null);
      final refreshToken = JwtHelper.refreshToken('123');
      final model = UserRefreshTokenInputModel(
        user: userId,
        accessToken: accessToken,
        dataRequest: '{"refresh_token": "$refreshToken"}',
      );

      // Act
      final call = userService.refreshToken;

      // Assert
      expect(() => call(model), throwsA(isA<ServiceException>()));
    });
  });
}
