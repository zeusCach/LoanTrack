import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository _repository;
  const LogoutUseCase(this._repository);

  @override
  Future<void> call(NoParams params) {
    return _repository.logout();
  }
}
