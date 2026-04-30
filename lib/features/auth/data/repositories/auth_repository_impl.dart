import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Stream<String?> get authStateChanges =>
      _dataSource.authStateChanges.map((user) => user?.uid);

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      return await _dataSource.login(email, password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final firebaseUser = _dataSource.authStateChanges.first;
      final user = await firebaseUser;
      if (user == null) return null;
      return await _dataSource.getCurrentUser(user.uid);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _dataSource.logout();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> updateUserName({
    required String uid,
    required String name,
  }) async {
    try {
      await _dataSource.updateUserName(uid: uid, name: name);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }
}
