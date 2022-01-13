import 'package:cuidapet_api/application/database/i_database_connection.dart';
import 'package:cuidapet_api/application/exceptions/database_exception.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/entities/schedule.dart';
import 'package:cuidapet_api/entities/schedule_supplier_service.dart';
import 'package:cuidapet_api/entities/supplier.dart';
import 'package:cuidapet_api/entities/supplier_service.dart';
import 'package:injectable/injectable.dart';
import 'package:mysql1/mysql1.dart';

import './i_schedule_repository.dart';

@LazySingleton(as: IScheduleRepository)
class ScheduleRepository implements IScheduleRepository {
  final IDatabaseConnection connection;
  final ILogger log;

  ScheduleRepository({required this.connection, required this.log});

  @override
  Future<void> save(Schedule schedule) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      await conn.transaction((_) async {
        final result = await conn!.query(
          '''
            INSERT INTO agendamento(
              data_agendamento, usuario_id, fornecedor_id, status, nome, nome_pet
            )
            VALUES (?, ?, ?, ?, ?, ?)
          ''',
          [
            schedule.scheduleDate.toIso8601String(),
            schedule.userId,
            schedule.supplier.id,
            schedule.status,
            schedule.name,
            schedule.petName,
          ],
        );

        final scheduleId = result.insertId;

        if (scheduleId != null) {
          await conn.queryMulti(
            '''
              INSERT INTO agendamento_servicos VALUES(?, ?)
            ''',
            schedule.services.map(
              (s) => [
                scheduleId,
                s.service.id,
              ],
            ),
          );
        }
      });
    } on MySqlException catch (e, s) {
      log.error('Error when scheduling service', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> changeStatus(String status, int scheduleId) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      await conn.query(
        '''
          UPDATE agendamento SET status = ? 
          WHERE id = ?
        ''',
        [
          status,
          scheduleId,
        ],
      );
    } on MySqlException catch (e, s) {
      log.error('Error when changing a service status', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<List<Schedule>> findAllSchedulesByUser(int userId) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final query =
          '''
        SELECT 
          a.id, 
          a.data_agendamento, 
          a.status, 
          a.nome, 
          a.nome_pet, 
          f.id AS fornec_id, 
          f.nome AS fornec_nome, 
          f.logo 
        FROM agendamento AS a 
        INNER JOIN fornecedor AS f ON f.id = a.fornecedor_id 
        WHERE a.usuario_id = ? 
        ORDER BY a.data_agendamento DESC
      ''';

      final result = await conn.query(query, [userId]);

      final scheduleResultFuture = result
          .map(
            (s) async => Schedule(
              id: s['id'],
              scheduleDate: s['data_agendamento'],
              status: s['status'],
              name: s['nome'],
              petName: s['nome_pet'],
              userId: userId,
              supplier: Supplier(
                id: s['fornec_id'],
                logo: (s['logo'] as Blob?).toString(),
                name: s['fornec_nome'],
              ),
              services: await _findAllServicesBySchedule(s['id']),
            ),
          )
          .toList();

      return Future.wait(scheduleResultFuture);
    } on MySqlException catch (e, s) {
      log.error('Error when finding user schedules', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  Future<List<ScheduleSupplierService>> _findAllServicesBySchedule(
    int scheduleId,
  ) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      final result = await conn.query(
        '''
          SELECT 
            fs.id, fs.nome_servico, fs.valor_servico, fs.fornecedor_id 
          FROM agendamento_servicos AS ags 
          INNER JOIN fornecedor_servicos fs ON fs.id = ags.fornecedor_servicos_id 
          WHERE ags.agendamento_id = ?
        ''',
        [scheduleId],
      );

      return result
          .map(
            (s) => ScheduleSupplierService(
              service: SupplierService(
                id: s['id'],
                name: s['nome_servico'],
                price: s['valor_servico'],
                supplierId: s['fornecedor_id'],
              ),
            ),
          )
          .toList();
    } on MySqlException catch (e, s) {
      log.error('Error when finding the services from a schedule', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }
}
