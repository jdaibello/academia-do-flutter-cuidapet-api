import 'package:dotenv/dotenv.dart' show env;
import 'package:jaguar_jwt/jaguar_jwt.dart';

class JwtHelper {
  static final _jwtSecret = env['JWT_SECRET'] ?? env['LOCAL_JWT_SECRET']!;

  JwtHelper._();

  static JwtClaim getClaims(String token) {
    return verifyJwtHS256Signature(token, _jwtSecret);
  }
}
