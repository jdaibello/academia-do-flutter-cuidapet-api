import 'package:cuidapet_api/dtos/supplier_near_by_me_dto.dart';
import 'package:cuidapet_api/entities/supplier.dart';

abstract class ISupplierService {
  Future<List<SupplierNearByMeDto>> findNearByMe(
    double latitude,
    double longitude,
  );
  Future<Supplier?> findById(int id);
}
