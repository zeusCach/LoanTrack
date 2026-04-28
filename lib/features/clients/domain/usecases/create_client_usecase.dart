import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

class CreateClientParams {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String adminId;

  const CreateClientParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.adminId,
  });
}

class CreateClientUseCase {
  final ClientRepository _repository;
  const CreateClientUseCase(this._repository);

  Future<ClientEntity> call(CreateClientParams params) {
    return _repository.createClient(
      name: params.name,
      email: params.email,
      phone: params.phone,
      password: params.password,
      adminId: params.adminId,
    );
  }
}
