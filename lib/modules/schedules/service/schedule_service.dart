import 'package:cuidapet_api/entities/schedule.dart';
import 'package:cuidapet_api/entities/schedule_supplier_service.dart';
import 'package:cuidapet_api/entities/supplier.dart';
import 'package:cuidapet_api/entities/supplier_service.dart';
import 'package:cuidapet_api/modules/schedules/data/i_schedule_repository.dart';
import 'package:cuidapet_api/modules/schedules/view_models/schedule_save_input_model.dart';
import 'package:injectable/injectable.dart';

import './i_schedule_service.dart';

@LazySingleton(as: IScheduleService)
class ScheduleService implements IScheduleService {
  final IScheduleRepository repository;

  ScheduleService({required this.repository});

  @override
  Future<void> scheduleService(ScheduleSaveInputModel model) async {
    final schedule = Schedule(
      scheduleDate: model.scheduleDate,
      name: model.name,
      petName: model.petName,
      supplier: Supplier(id: model.supplierId),
      status: 'P',
      userId: model.userId,
      services: model.services
          .map(
            (s) => ScheduleSupplierService(
              service: SupplierService(id: s),
            ),
          )
          .toList(),
    );

    await repository.save(schedule);
  }
}
