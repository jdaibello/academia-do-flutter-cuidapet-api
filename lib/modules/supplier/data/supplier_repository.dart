import 'package:cuidapet_api/application/database/i_database_connection.dart';
import 'package:cuidapet_api/application/exceptions/database_exception.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/dtos/supplier_near_by_me_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:mysql1/mysql1.dart';

import './i_supplier_repository.dart';

@LazySingleton(as: ISupplierRepository)
class SupplierRepository implements ISupplierRepository {
  final IDatabaseConnection connection;
  final ILogger log;

  SupplierRepository({required this.connection, required this.log});

  @override
  Future<List<SupplierNearByMeDto>> findNearByPosition(
    double latitude,
    double longitude,
    int distance,
  ) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final query =
          '''
            SELECT f.id, f.nome, f.logo, f.categorias_fornecedor_id,
            (6371 * 
              acos(
                cos(radians($latitude)) * 
                cos(radians(ST_X(f.latlng))) * 
                cos(radians($longitude) - radians(ST_Y(f.latlng))) + 
                sin(radians($latitude)) * 
                sin(radians(ST_X(f.latlng)))
              )
            ) AS distancia 
            FROM fornecedor f 
            HAVING distancia <= $distance;
          ''';
      final result = await conn.query(query);

      return result
          .map(
            (s) => SupplierNearByMeDto(
              id: s['id'],
              name: s['nome'],
              logo: (s['logo'] as Blob?)?.toString(),
              distance: s['distancia'],
              categoryId: s['categorias_fornecedor_id'],
            ),
          )
          .toList();
    } on MySqlException catch (e, s) {
      log.error('Error when finding suppliers near by me', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }
}
