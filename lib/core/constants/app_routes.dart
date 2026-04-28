import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/clients/presentation/screens/clients_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/admin_dashboard_screen.dart';
import '../../features/loans/presentation/screens/loan_detail_screen.dart';

class _PlaceholderScreen extends StatelessWidget {
  final String name;
  const _PlaceholderScreen(this.name);
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(name)));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final user = authState.value;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) {
        return user.isAdmin ? '/admin/dashboard' : '/client/dashboard';
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
              _PlaceholderScreen('Cliente ${s.pathParameters['clientId']}')),
      GoRoute(
          path: '/admin/loans/new',
          builder: (_, __) => _PlaceholderScreen('Nuevo Préstamo')),

      // Agrega provider para obtener loan por id
      // Por ahora pasamos el objeto via Navigator, actualiza el placeholder:
      GoRoute(
        path: '/admin/loans/:loanId',
        builder: (_, __) => const _PlaceholderScreen('Loan Detail'),
      ),

      GoRoute(
          path: '/admin/reports',
          builder: (_, __) => _PlaceholderScreen('Reportes')),

      // Client
      GoRoute(
          path: '/client/dashboard',
          builder: (_, __) => _PlaceholderScreen('Client Dashboard')),
      GoRoute(
          path: '/client/payments',
          builder: (_, __) => _PlaceholderScreen('Mis Pagos')),
      GoRoute(
          path: '/client/history',
          builder: (_, __) => _PlaceholderScreen('Historial')),
    ],
  );
});
