import 'package:cuidapet_api/application/database/i_database_connection.dart';
import 'package:cuidapet_api/application/exceptions/database_exception.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/dtos/supplier_near_by_me_dto.dart';
import 'package:cuidapet_api/entities/category.dart';
import 'package:cuidapet_api/entities/supplier.dart';
import 'package:cuidapet_api/entities/supplier_service.dart';
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

      final query = '''
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

  @override
  Future<Supplier?> findById(int id) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final query = '''
        SELECT
          f.id, f.nome, f.logo, f.endereco, f.telefone, ST_X(f.latlng) AS lat, ST_Y(f.latlng) AS lng,
          f.categorias_fornecedor_id, c.nome_categoria, c.tipo_categoria
        FROM fornecedor AS f
        INNER JOIN categorias_fornecedor AS c ON f.categorias_fornecedor_id = c.id
        WHERE
          f.id = ?
      ''';

      final result = await conn.query(query, [id]);

      if (result.isNotEmpty) {
        final dataMysql = result.first;

        return Supplier(
          id: dataMysql['id'],
          name: dataMysql['nome'],
          logo: (dataMysql['logo'] as Blob?).toString(),
          address: dataMysql['endereco'],
          phone: dataMysql['telefone'],
          latitude: dataMysql['lat'],
          longitude: dataMysql['lng'],
          category: Category(
            id: dataMysql['categorias_fornecedor_id'],
            name: dataMysql['nome_categoria'],
            type: dataMysql['tipo_categoria'],
          ),
        );
      }
    } on MySqlException catch (e, s) {
      log.error('Error when finding supplier', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<List<SupplierService>> findServicesBySupplierId(int supplierId) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final result = await conn.query('''
        SELECT id, fornecedor_id, nome_servico, valor_servico 
        FROM fornecedor_servicos 
        WHERE fornecedor_id = ?
      ''', [supplierId]);

      if (result.isEmpty) {
        return [];
      }

      return result
          .map((s) => SupplierService(
              id: s['id'],
              supplierId: s['fornecedor_id'],
              name: s['nome_servico'],
              price: s['valor_servico']))
          .toList();
    } on MySqlException catch (e, s) {
      log.error('Error when finding services by supplier', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }
}
