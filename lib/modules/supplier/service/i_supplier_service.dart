import 'package:cuidapet_api/dtos/supplier_near_by_me_dto.dart';

abstract class ISupplierService {
  Future<List<SupplierNearByMeDto>> findNearByMe(
    double latitude,
    double longitude,
  );
}
