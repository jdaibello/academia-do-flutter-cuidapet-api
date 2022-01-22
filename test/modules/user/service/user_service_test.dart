import 'package:cuidapet_api/application/exceptions/user_not_found_exception.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/entities/user.dart';
import 'package:cuidapet_api/modules/user/data/i_user_repository.dart';
import 'package:cuidapet_api/modules/user/service/i_user_service.dart';
import 'package:cuidapet_api/modules/user/service/user_service.dart';
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
  });

  group('Group test login with email and password', () {
    test('should login with email and password', () async {
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
      ).thenThrow(
        UserNotFoundException(
          message: 'Invalid e-mail or password',
        ),
      );

      // Act
      final call = userService.loginWithEmailAndPassword;

      // Assert
      expect(() => call(email, password, supplierUser),
          throwsA(isA<UserNotFoundException>()));
      verify(() => userRepository.loginWithEmailAndPassword(
          email, password, supplierUser)).called(1);
    });
  });
}
