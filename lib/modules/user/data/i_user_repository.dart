import 'package:cuidapet_api/entities/user.dart';

abstract class IUserRepository {
  Future<User> createUser(User user);
  Future<User> loginWithEmailAndPassword(
    String email,
    String password,
    bool supplierUser,
  );
  Future<User> loginByEmailAndSocialKey(
    String email,
    String socialKey,
    String socialType,
  );
  Future<void> updateUserDeviceTokenAndRefreshToken(User user);
  Future<void> updateRefreshToken(User user);
}
