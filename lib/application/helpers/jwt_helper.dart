import 'package:dotenv/dotenv.dart' show env;
import 'package:jaguar_jwt/jaguar_jwt.dart';

class JwtHelper {
  static final _jwtSecret = env['JWT_SECRET'] ?? env['LOCAL_JWT_SECRET']!;

  JwtHelper._();

  static String generateJWT(int userId, int? supplierId) {
    final claimSet = JwtClaim(
      issuer: 'cuidapet',
      subject: userId.toString(),
      expiry: DateTime.now().add(const Duration(seconds: 30)),
      notBefore: DateTime.now(),
      issuedAt: DateTime.now(),
      otherClaims: <String, dynamic>{
        'supplier': supplierId,
      },
      maxAge: const Duration(days: 1),
    );

    return 'Bearer ${issueJwtHS256(claimSet, _jwtSecret)}';
  }

  static JwtClaim getClaims(String token) {
    return verifyJwtHS256Signature(token, _jwtSecret);
  }

  static String refreshToken(String accessToken) {
    final expiry = int.parse(env['REFRESH_TOKEN_EXPIRY_DAYS']!);
    final notBefore = int.parse(env['REFRESH_TOKEN_NOT_BEFORE_HOURS']!);

    final claimSet = JwtClaim(
      issuer: accessToken,
      subject: 'RefreshToken',
      expiry: DateTime.now().add(Duration(days: expiry)),
      // notBefore: DateTime.now().add(Duration(hours: notBefore)),
      notBefore: DateTime.now(),
      issuedAt: DateTime.now(),
      otherClaims: <String, dynamic>{},
    );

    return 'Bearer ${issueJwtHS256(claimSet, _jwtSecret)}';
  }
}
