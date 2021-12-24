import 'dart:async';
import 'dart:convert';

import 'package:cuidapet_api/application/exceptions/user_exists_exception.dart';
import 'package:cuidapet_api/application/exceptions/user_not_found_exception.dart';
import 'package:cuidapet_api/application/helpers/jwt_helper.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/entities/user.dart';
import 'package:cuidapet_api/modules/user/service/i_user_service.dart';
import 'package:cuidapet_api/modules/user/view_models/login_view_model.dart';
import 'package:cuidapet_api/modules/user/view_models/user_confirm_input_model.dart';
import 'package:cuidapet_api/modules/user/view_models/user_save_input_model.dart';
import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'auth_controller.g.dart';

@Injectable()
class AuthController {
  IUserService userService;
  ILogger log;

  AuthController({required this.userService, required this.log});

  @Route.post('/')
  Future<Response> login(Request request) async {
    try {
      final loginViewModel = LoginViewModel(await request.readAsString());

      User user;

      if (!loginViewModel.socialLogin) {
        user = await userService.loginWithEmailAndPassword(
          loginViewModel.login,
          loginViewModel.password,
          loginViewModel.supplierUser,
        );
      } else {
        // Social login (Facebook, Google, Apple, etc...)
        user = await userService.loginWithSocial(
          loginViewModel.login,
          loginViewModel.avatar,
          loginViewModel.socialType,
          loginViewModel.socialKey,
        );
      }

      return Response.ok(
        jsonEncode(
          {'access_token': JwtHelper.generateJWT(user.id!, user.supplierId)},
        ),
      );
    } on UserNotFoundException {
      return Response.forbidden(
        jsonEncode(
          {'message': 'Invalid user or password'},
        ),
      );
    } catch (e, s) {
      log.error('Error when logging in', e, s);
      return Response.forbidden(
        jsonEncode(
          {'message': 'Error while logging in'},
        ),
      );
    }
  }

  @Route.post('/register')
  Future<Response> saveUser(Request request) async {
    try {
      final userModel = UserSaveInputModel(await request.readAsString());
      await userService.createUser(userModel);
      return Response.ok(
        jsonEncode(
          {'message': 'Registration performed successfully'},
        ),
      );
    } on UserExistsException {
      return Response(
        400,
        body: jsonEncode(
          {'message': 'User already registered in database'},
        ),
      );
    } catch (e, s) {
      log.error('Error when registering user', e, s);
      return Response.internalServerError();
    }
  }

  @Route('PATCH', '/confirm')
  Future<Response> confirmLogin(Request request) async {
    final user = int.parse(request.headers['user']!);
    final supplier = int.tryParse(request.headers['supplier'] ?? '');
    final token = JwtHelper.generateJWT(user, supplier).replaceAll(
      'Bearer ',
      '',
    );

    final inputModel = UserConfirmInputModel(
      userId: user,
      accessToken: token,
      data: await request.readAsString(),
    );

    final refreshToken = await userService.confirmLogin(inputModel);

    return Response.ok(
      jsonEncode(
        {
          'access_token': 'Bearer $token',
          'refresh_token': refreshToken,
        },
      ),
    );
  }

  Router get router => _$AuthControllerRouter(this);
}
