import 'package:cuidapet_api/application/database/i_database_connection.dart';
import 'package:cuidapet_api/application/exceptions/database_exception.dart';
import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/entities/schedule.dart';
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
}
