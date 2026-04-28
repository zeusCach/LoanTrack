import 'package:firebase_auth/firebase_auth.dart';
import 'package:loantrack/features/auth/data/datasources/auth_remote_datasource.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

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
}
