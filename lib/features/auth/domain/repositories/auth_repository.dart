import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity?> getCurrentUser();
  Future<void> logout();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updateUserName({required String uid, required String name});
  Stream<String?> get authStateChanges;
}
