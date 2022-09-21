import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/modules/user/controller/user_controller.dart';
import 'package:cuidapet_api/modules/user/service/i_user_service.dart';
import 'package:cuidapet_api/modules/user/view_models/user_update_device_token_input_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../../../core/fixture/fixture_reader.dart';
import '../../../core/log/mock_logger.dart';
import '../../../core/shelf/mock_shelf_request.dart';
import 'mocks/mock_user_service.dart';

void main() {
  late IUserService userService;
  late ILogger log;
  late Request request;
  late UserController userController;

  setUp(() {
    userService = MockUserService();
    log = MockLogger();
    request = MockShelfRequest();
    userController = UserController(userService: userService, log: log);
  });

  test('should update device token', () async {
    // Arrange
    final requestFixture = FixtureReader.getJsonData(
      'modules/user/controller/fixture/update_device_token.json',
    );

    final userId = '123';
    final model = UserUpdateDeviceTokenInputModel(
      userId: int.parse(userId),
      dataRequest: requestFixture,
    );

    when(() => request.headers).thenReturn({'user': '123'});
    when(() => request.readAsString()).thenAnswer((_) async => requestFixture);
    when(() => userService.updateDeviceToken(model)).thenAnswer((_) async => _);

    // Act
    final response = await userController.updateDeviceToken(request);

    // Assert
    expect(response.statusCode, 200);
    verify(() => request.readAsString()).called(1);
    verify(() => request.headers['user']).called(1);
    verify(() => userService.updateDeviceToken(model)).called(1);
  });
}