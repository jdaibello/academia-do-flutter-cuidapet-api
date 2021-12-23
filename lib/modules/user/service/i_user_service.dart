import 'package:cuidapet_api/entities/user.dart';
import 'package:cuidapet_api/modules/user/view_models/user_save_input_model.dart';

abstract class IUserService {
  Future<User> createUser(UserSaveInputModel user);
  Future<User> loginWithEmailAndPassword(
    String email,
    String password,
    bool supplierUser,
  );
  Future<User> loginWithSocial(
    String email,
    String avatar,
    String socialType,
    String socialKey,
  );
}
