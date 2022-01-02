import 'package:cuidapet_api/dtos/supplier_near_by_me_dto.dart';

abstract class ISupplierRepository {
  Future<List<SupplierNearByMeDto>> findNearByPosition(
    double latitude,
    double longitude,
    int distance,
  );
}
