import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/client_model.dart';

abstract class ClientRemoteDataSource {
  Stream<List<ClientModel>> getClients(String adminId);
  Future<ClientModel> createClient({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String adminId,
  });
  Future<void> updateClient(ClientModel client);
  Future<void> toggleClientStatus(String clientId, bool isActive);
}

class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ClientRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  @override
  Stream<List<ClientModel>> getClients(String adminId) {
    return _firestore
        .collection('users')
        .where('adminId', isEqualTo: adminId)
        .where('role', isEqualTo: 'client')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ClientModel.fromFirestore(doc)).toList());
  }

  @override
  Future<ClientModel> createClient({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String adminId,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // Instancia secundaria para no cerrar sesión del admin
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: _auth.app.options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      await secondaryAuth.signOut();

      final client = ClientModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        adminId: adminId,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection('users').doc(uid).set(client.toFirestore());
      return client;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AuthException('Este correo ya está registrado');
      }
      throw AuthException('Error al crear cliente: ${e.message}');
    } finally {
      await secondaryApp?.delete();
    }
  }

  @override
  Future<void> updateClient(ClientModel client) async {
    await _firestore.collection('users').doc(client.uid).update({
      'name': client.name,
      'phone': client.phone,
    });
  }

  @override
  Future<void> toggleClientStatus(String clientId, bool isActive) async {
    await _firestore.collection('users').doc(clientId).update({
      'isActive': isActive,
    });
  }
}
