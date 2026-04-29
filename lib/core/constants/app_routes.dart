import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/admin_dashboard_screen.dart';
import '../../features/auth/presentation/screens/client_dashboard_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/clients/presentation/screens/clients_screen.dart';
import '../../features/loans/presentation/screens/admin_loans_screen.dart';
import '../../features/loans/presentation/screens/client_loans_status_screen.dart';
import '../../features/payments/presentation/screens/admin_payments_screen.dart';
import '../../features/payments/presentation/screens/client_payments_screen.dart';
import '../../features/reports/presentation/screens/admin_reports_screen.dart';
import '../widgets/entity_loaders.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final user = authState.value;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) {
        return user.isAdmin ? '/admin/dashboard' : '/client/dashboard';
      }

      if (isLoggedIn) {
        final isAdminRoute = state.matchedLocation.startsWith('/admin');
        final isClientRoute = state.matchedLocation.startsWith('/client');

        if (isAdminRoute && !user.isAdmin) return '/client/dashboard';
        if (isClientRoute && user.isAdmin) return '/admin/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // Admin
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/clients',
        builder: (_, __) => const ClientsScreen(),
      ),
      GoRoute(
        path: '/admin/clients/:clientId',
        builder: (_, s) =>
            ClientDetailRoute(clientId: s.pathParameters['clientId']!),
      ),
      GoRoute(
        path: '/admin/loans',
        builder: (_, __) => const AdminLoansScreen(),
      ),
      GoRoute(
        path: '/admin/payments',
        builder: (_, __) => const AdminPaymentsScreen(),
      ),
      GoRoute(
        path: '/admin/loans/new',
        builder: (_, __) => const CreateLoanRoute(),
      ),
      GoRoute(
        path: '/admin/loans/:loanId',
        builder: (_, s) =>
            LoanDetailRoute(loanId: s.pathParameters['loanId']!),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (_, __) => const AdminReportsScreen(),
      ),

      // Client
      GoRoute(
        path: '/client/dashboard',
        builder: (_, __) => const ClientDashboardScreen(),
      ),
      GoRoute(
        path: '/client/payments',
        builder: (_, __) => const ClientPaymentsScreen(),
      ),
      GoRoute(
        path: '/client/history',
        builder: (_, __) => const ClientLoansStatusScreen(),
      ),
    ],
  );
});
