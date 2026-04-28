import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LoanTrack',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Hola, ${user?.name ?? 'Admin'}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fecha
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Stats cards
              statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (stats) => Column(
                  children: [
                    // Fila 1
                    Row(
                      children: [
                        _StatCard(
                          label: 'Clientes',
                          value: '${stats.totalClients}',
                          icon: Icons.people_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Préstamos activos',
                          value: '${stats.activeLoans}',
                          icon: Icons.account_balance_rounded,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Fila 2
                    Row(
                      children: [
                        _StatCard(
                          label: 'En mora',
                          value: '${stats.loansInDefault}',
                          icon: Icons.warning_rounded,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Pagos hoy',
                          value: '${stats.pendingPaymentsToday}',
                          icon: Icons.today_rounded,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Total cobrado — full width
                    _TotalCard(
                      label: 'Total cobrado',
                      value: currencyFormat.format(stats.totalCollected),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Acciones rápidas
              const Text('Acciones rápidas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _ActionCard(
                    label: 'Clientes',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.primary,
                    onTap: () => context.push('/admin/clients'),
                  ),
                  _ActionCard(
                    label: 'Préstamos',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.success,
                    onTap: () => context.push('/admin/loans'),
                  ),
                  _ActionCard(
                    label: 'Pagos',
                    icon: Icons.payments_outlined,
                    color: AppColors.warning,
                    onTap: () => context.push('/admin/payments'),
                  ),
                  _ActionCard(
                    label: 'Reportes',
                    icon: Icons.bar_chart_rounded,
                    color: AppColors.secondary,
                    onTap: () => context.push('/admin/reports'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Widgets internos ---

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final String value;

  const _TotalCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white54, size: 40),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
