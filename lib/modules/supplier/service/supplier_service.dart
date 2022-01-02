import 'package:cuidapet_api/dtos/supplier_near_by_me_dto.dart';
import 'package:cuidapet_api/modules/supplier/data/i_supplier_repository.dart';
import 'package:injectable/injectable.dart';

import './i_supplier_service.dart';

@LazySingleton(as: ISupplierService)
class SupplierService implements ISupplierService {
  final ISupplierRepository repository;
  static const distance = 5;

  SupplierService({required this.repository});

  @override
  Future<List<SupplierNearByMeDto>> findNearByMe(
    double latitude,
    double longitude,
  ) =>
      repository.findNearByPosition(latitude, longitude, distance);
}
