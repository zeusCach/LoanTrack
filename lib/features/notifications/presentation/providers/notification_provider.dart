import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/notification_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/client_notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationDataSourceProvider = Provider<NotificationDataSource>((ref) {
  return NotificationDataSourceImpl(firestore: ref.watch(firestoreProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(notificationDataSourceProvider));
});

/// Stream de notificaciones no leídas del cliente autenticado.
/// Solo activo cuando el usuario es cliente (no admin).
final unreadNotificationsProvider =
    StreamProvider<List<ClientNotificationEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null || user.isAdmin) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).watchUnread(user.uid);
});
