import '../entities/client_entity.dart';

abstract class ClientRepository {
  Stream<List<ClientEntity>> getClients(String adminId);
  Future<ClientEntity> createClient({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String adminId,
  });
  Future<void> updateClient(ClientEntity client);
  Future<void> toggleClientStatus(String clientId, bool isActive);
}
