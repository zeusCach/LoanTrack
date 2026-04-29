import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardStats {
  final int totalClients;
  final int activeLoans;
  final int loansInDefault;
  final double totalCollected;
  final int pendingPaymentsToday;

  const DashboardStats({
    required this.totalClients,
    required this.activeLoans,
    required this.loansInDefault,
    required this.totalCollected,
    required this.pendingPaymentsToday,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final user = ref.read(authStateProvider).value;
  if (user == null)
    return const DashboardStats(
      totalClients: 0,
      activeLoans: 0,
      loansInDefault: 0,
      totalCollected: 0,
      pendingPaymentsToday: 0,
    );

  final firestore = ref.read(firestoreProvider);
  final adminId = user.uid;
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  // Clientes
  final clientsSnap = await firestore
      .collection('users')
      .where('adminId', isEqualTo: adminId)
      .where('role', isEqualTo: 'client')
      .get();

  // Préstamos activos
  final activeLoansSnap = await firestore
      .collection('loans')
      .where('adminId', isEqualTo: adminId)
      .where('status', isEqualTo: 'active')
      .get();

  // Préstamos en mora
  final defaultLoansSnap = await firestore
      .collection('loans')
      .where('adminId', isEqualTo: adminId)
      .where('status', isEqualTo: 'defaulted')
      .get();

  // Pagos cobrados (paid, early y late — todos los que ya se cobraron)
  final paymentsSnap = await firestore
      .collection('payments')
      .where('adminId', isEqualTo: adminId)
      .where('status', whereIn: ['paid', 'early', 'late']).get();

  final totalCollected = paymentsSnap.docs.fold<double>(
    0,
    (sum, doc) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final penalty = (data['penaltyAmount'] as num?)?.toDouble() ?? 0;
      return sum + amount + penalty;
    },
  );

  // Pagos pendientes de hoy
  final todayPendingSnap = await firestore
      .collection('payments')
      .where('adminId', isEqualTo: adminId)
      .where('status', isEqualTo: 'pending')
      .where('expectedDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('expectedDate', isLessThan: Timestamp.fromDate(endOfDay))
      .get();

  return DashboardStats(
    totalClients: clientsSnap.docs.length,
    activeLoans: activeLoansSnap.docs.length,
    loansInDefault: defaultLoansSnap.docs.length,
    totalCollected: totalCollected,
    pendingPaymentsToday: todayPendingSnap.docs.length,
  );
});
