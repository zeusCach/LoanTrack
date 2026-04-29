import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../clients/presentation/providers/client_provider.dart';
import '../../../loans/presentation/providers/loan_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import 'auth_provider.dart';
import 'client_dashboard_provider.dart';
import 'dashboard_provider.dart';

/// Cancela todos los streams que dependen del usuario autenticado y luego
/// ejecuta signOut. Sin esto, los listeners de Firestore siguen vivos un
/// instante después del logout y disparan PERMISSION_DENIED en bucle.
Future<void> performLogout(WidgetRef ref) async {
  ref.invalidate(clientLoansProvider);
  ref.invalidate(adminLoansProvider);
  ref.invalidate(loanPaymentsProvider);
  ref.invalidate(clientPaymentsProvider);
  ref.invalidate(clientsStreamProvider);
  ref.invalidate(unreadNotificationsProvider);
  ref.invalidate(dashboardStatsProvider);
  ref.invalidate(clientDashboardStatsProvider);

  await ref.read(authRepositoryProvider).logout();
}
