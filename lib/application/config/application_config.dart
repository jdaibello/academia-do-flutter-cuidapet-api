import 'package:dotenv/dotenv.dart' show load, env;

class ApplicationConfig {
  Future<void> loadConfigApplication() async {
    await _loadEnv();
    final variavel = env['DATABASE_URL'];

    print(variavel);
  }

  Future<void> _loadEnv() async => load();
}
