import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/logout.dart';

const _highlightBg = Color(0xFF1A237E);

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
              await performLogout(ref);
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
                          color: _highlightBg,
                          highlight: true,
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
                      rawAmount: stats.totalCollected,
                      onTap: () => _showTotalCollectedSheet(
                        context,
                        stats.totalCollected,
                        currencyFormat,
                      ),
                    ),
                  ],
                ),
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
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = highlight ? color : Colors.white;
    final iconBg = highlight
        ? Colors.white.withOpacity(0.18)
        : color.withOpacity(0.15);
    final iconColor = highlight ? Colors.white : color;
    final valueColor = highlight ? Colors.white : color;
    final labelColor =
        highlight ? Colors.white.withOpacity(0.85) : AppColors.textSecondary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: highlight
              ? null
              : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: highlight
                  ? color.withOpacity(0.25)
                  : Colors.black.withOpacity(0.04),
              blurRadius: highlight ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
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
  final double rawAmount;
  final VoidCallback onTap;

  const _TotalCard({
    required this.label,
    required this.value,
    required this.rawAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          onLongPress: () async {
            await Clipboard.setData(
                ClipboardData(text: rawAmount.toStringAsFixed(2)));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Monto copiado al portapapeles'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(width: 6),
                          const Icon(Icons.touch_app_rounded,
                              color: Colors.white54, size: 14),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(value,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Toca para ver detalles · Mantén para copiar',
                        style:
                            TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white54, size: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showTotalCollectedSheet(
  BuildContext context,
  double totalCollected,
  NumberFormat currencyFormat,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Total cobrado',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                currencyFormat.format(totalCollected),
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Suma de todos los pagos marcados como pagados.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _SheetAction(
                icon: Icons.bar_chart_rounded,
                label: 'Ver reportes',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/admin/reports');
                },
              ),
              const SizedBox(height: 10),
              _SheetAction(
                icon: Icons.payments_outlined,
                label: 'Ver pagos cobrados',
                color: AppColors.success,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/admin/payments');
                },
              ),
              const SizedBox(height: 10),
              _SheetAction(
                icon: Icons.copy_rounded,
                label: 'Copiar monto',
                color: AppColors.primary,
                onTap: () async {
                  await Clipboard.setData(
                      ClipboardData(text: totalCollected.toStringAsFixed(2)));
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Monto copiado al portapapeles'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

