import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
}

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  @override
  Future<UserEntity> call(LoginParams params) {
    return _repository.login(params.email, params.password);
  }
}
