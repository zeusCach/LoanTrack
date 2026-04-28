import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_remote_datasource.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientRemoteDataSource _dataSource;
  ClientRepositoryImpl(this._dataSource);

  @override
  Stream<List<ClientEntity>> getClients(String adminId) {
    return _dataSource
        .getClients(adminId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<ClientEntity> createClient({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String adminId,
  }) async {
    final model = await _dataSource.createClient(
      name: name,
      email: email,
      phone: phone,
      password: password,
      adminId: adminId,
    );
    return model.toEntity();
  }

  @override
  Future<void> updateClient(ClientEntity client) {
    final model = ClientModel(
      uid: client.uid,
      name: client.name,
      email: client.email,
      phone: client.phone,
      adminId: client.adminId,
      createdAt: client.createdAt,
      isActive: client.isActive,
    );
    return _dataSource.updateClient(model);
  }

  @override
  Future<void> toggleClientStatus(String clientId, bool isActive) {
    return _dataSource.toggleClientStatus(clientId, isActive);
  }
}
