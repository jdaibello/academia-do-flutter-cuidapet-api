import 'package:cuidapet_api/application/middlewares/middlewares.dart';
import 'package:shelf/shelf.dart';

class DefaultContentTypeMiddleware extends Middlewares {
  final String contentType;

  DefaultContentTypeMiddleware(this.contentType);

  @override
  Future<Response> execute(Request request) async {
    final response = await innerHandler(request);

    return response.change(
      headers: {
        'content-type': contentType,
      },
    );
  }
}
