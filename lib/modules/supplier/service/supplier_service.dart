import 'package:cuidapet_api/dtos/supplier_near_by_me_dto.dart';
import 'package:cuidapet_api/entities/supplier.dart';
import 'package:cuidapet_api/entities/supplier_service.dart' as entity;
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

  @override
  Future<Supplier?> findById(int id) => repository.findById(id);

  @override
  Future<List<entity.SupplierService>> findServicesBySupplier(int supplierId) =>
      repository.findServicesBySupplierId(supplierId);

  @override
  Future<bool> checkUserEmailExists(String email) =>
      repository.checkUserEmailExists(email);
}
