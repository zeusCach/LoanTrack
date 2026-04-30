import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// Datasource
final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

// Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authDataSourceProvider));
});

// Estado de sesión — stream principal
final authStateProvider = StreamProvider<UserEntity?>((ref) async* {
  final repo = ref.read(authRepositoryProvider);
  final dataSource = ref.read(authDataSourceProvider);

  await for (final uid in repo.authStateChanges) {
    if (uid == null) {
      yield null;
    } else {
      try {
        final user = await dataSource.getCurrentUser(uid);
        yield user;
      } catch (_) {
        yield null;
      }
    }
  }
});
