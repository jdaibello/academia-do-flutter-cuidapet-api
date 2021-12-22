import 'package:cuidapet_api/application/config/database_connection_configuration.dart';
import 'package:mysql1/mysql1.dart';

import './i_database_connection.dart';

class DatabaseConnection implements IDatabaseConnection {
  final DatabaseConnectionConfiguration _configuration;

  DatabaseConnection(this._configuration);

  @override
  Future<MySqlConnection> openConnection() {
    return MySqlConnection.connect(ConnectionSettings(
      host: _configuration.host,
      port: _configuration.port,
      user: _configuration.user,
      password: _configuration.password,
      db: _configuration.databaseName,
    ));
  }
}
