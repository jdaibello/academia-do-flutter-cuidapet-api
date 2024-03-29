import 'package:cuidapet_api/dtos/supplier_near_by_me_dto.dart';
import 'package:cuidapet_api/entities/category.dart';
import 'package:cuidapet_api/entities/supplier.dart';
import 'package:cuidapet_api/entities/supplier_service.dart' as entity;
import 'package:cuidapet_api/modules/supplier/data/i_supplier_repository.dart';
import 'package:cuidapet_api/modules/supplier/view_models/create_supplier_user_view_model.dart';
import 'package:cuidapet_api/modules/supplier/view_models/supplier_update_input_model.dart';
import 'package:cuidapet_api/modules/user/service/i_user_service.dart';
import 'package:cuidapet_api/modules/user/view_models/user_save_input_model.dart';
import 'package:injectable/injectable.dart';

import './i_supplier_service.dart';

@LazySingleton(as: ISupplierService)
class SupplierService implements ISupplierService {
  final ISupplierRepository repository;
  final IUserService userService;

  static const distance = 5;

  SupplierService({required this.repository, required this.userService});

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

  @override
  Future<void> createUserSupplier(CreateSupplierUserViewModel model) async {
    final supplierEntity = Supplier(
      name: model.supplierName,
      category: Category(id: model.category),
    );

    final supplierId = await repository.saveSupplier(supplierEntity);

    final userInputModel = UserSaveInputModel(
      email: model.email,
      password: model.password,
      supplierId: supplierId,
    );

    await userService.createUser(userInputModel);
  }

  @override
  Future<Supplier> update(SupplierUpdateInputModel model) async {
    var supplier = Supplier(
      id: model.supplierId,
      name: model.name,
      logo: model.logo,
      address: model.address,
      phone: model.phone,
      latitude: model.latitude,
      longitude: model.longitude,
      category: Category(id: model.categoryId),
    );

    return await repository.update(supplier);
  }
}
