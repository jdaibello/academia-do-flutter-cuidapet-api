import 'dart:io';

import 'package:args/args.dart';
import 'package:cuidapet_api/application/config/application_config.dart';
import 'package:cuidapet_api/application/middlewares/cors/cors_middleware.dart';
import 'package:cuidapet_api/application/middlewares/default_content_type/default_content_type_middleware.dart';
import 'package:cuidapet_api/application/middlewares/security/security_middleware.dart';
import 'package:get_it/get_it.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = '0.0.0.0';

void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8080';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  final router = Router();
  final appConfig = ApplicationConfig();
  await appConfig.loadConfigApplication(router);

  final getIt = GetIt.I;

  var handler = const shelf.Pipeline()
      .addMiddleware(CorsMiddleware().handler)
      .addMiddleware(
        DefaultContentTypeMiddleware(
          'application/json;charset=utf-8',
        ).handler,
      )
      .addMiddleware(SecurityMiddleware(getIt.get()).handler)
      .addMiddleware(shelf.logRequests())
      .addHandler(router);

  var server = await io.serve(handler, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}
