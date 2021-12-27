import 'package:cuidapet_api/application/database/i_database_connection.dart';
import 'package:cuidapet_api/application/exceptions/database_exception.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/entities/category.dart';
import 'package:injectable/injectable.dart';
import 'package:mysql1/mysql1.dart';

import './i_categories_repository.dart';

@LazySingleton(as: ICategoriesRepository)
class CategoriesRepository implements ICategoriesRepository {
  IDatabaseConnection connection;
  ILogger log;

  CategoriesRepository({required this.connection, required this.log});

  @override
  Future<List<Category>> findAll() async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final result = await conn.query('SELECT * FROM categorias_fornecedor');

      if (result.isNotEmpty) {
        return result
            .map(
              (c) => Category(
                id: c['id'],
                name: c['nome_categoria'],
                type: c['tipo_categoria'],
              ),
            )
            .toList();
      }

      return [];
    } on MySqlException catch (e, s) {
      log.error('Error when finding provider categories', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }
}
