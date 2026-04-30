import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../notifications/domain/entities/client_notification_entity.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/client_dashboard_provider.dart';

const _headerColor = Color(0xFF1A237E);

class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ConsumerState<ClientDashboardScreen> createState() =>
      _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen> {
  final Set<String> _shownNotificationIds = {};

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    ref.listen<AsyncValue<List<ClientNotificationEntity>>>(
      unreadNotificationsProvider,
      (_, next) {
        next.whenData((notifications) {
          for (final notif in notifications) {
            if (_shownNotificationIds.contains(notif.id)) continue;
            _shownNotificationIds.add(notif.id);
            ref
                .read(notificationRepositoryProvider)
                .markAsRead(notif.clientId, notif.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(notif.body),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      },
    );

    final statsAsync = ref.watch(clientDashboardStatsProvider(user.uid));
    final paymentsAsync = ref.watch(clientPaymentsProvider(user.uid));
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientPaymentsProvider(user.uid));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _Header(
              userName: user.name,
              statsAsync: statsAsync,
              currency: currency,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _NextPaymentCard(
                paymentsAsync: paymentsAsync,
                currency: currency,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Header con saludo + avatar + balance ──────────────────────────────────

class _Header extends StatelessWidget {
  final String userName;
  final AsyncValue<ClientDashboardStats> statsAsync;
  final NumberFormat currency;

  const _Header({
    required this.userName,
    required this.statsAsync,
    required this.currency,
  });

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _headerColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Configuración',
                onPressed: () => context.push('/client/settings'),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _BalanceCard(statsAsync: statsAsync, currency: currency),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final AsyncValue<ClientDashboardStats> statsAsync;
  final NumberFormat currency;

  const _BalanceCard({required this.statsAsync, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: statsAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        error: (e, _) => Text(
          'Error: $e',
          style: const TextStyle(color: Colors.white),
        ),
        data: (stats) {
          final paid = stats.paidInstallments;
          final total = stats.paidInstallments + stats.pendingInstallments;
          final progress = total == 0 ? 0.0 : paid / total;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo pendiente',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currency.format(stats.remainingBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.success),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cuotas pagadas $paid / $total',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Card de próximo pago ──────────────────────────────────────────────────

class _NextPaymentCard extends StatelessWidget {
  final AsyncValue<List<PaymentEntity>> paymentsAsync;
  final NumberFormat currency;

  const _NextPaymentCard({
    required this.paymentsAsync,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return paymentsAsync.when(
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Error: $e'),
      data: (payments) {
        final pending = payments
            .where((p) => p.status == PaymentStatus.pending)
            .toList()
          ..sort((a, b) => a.expectedDate.compareTo(b.expectedDate));

        if (pending.isEmpty) {
          return _UpToDateCard();
        }
        final next = pending.first;
        return _DuePaymentCard(payment: next, currency: currency);
      },
    );
  }
}

class _UpToDateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.success),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('¡Estás al día!',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success)),
                          SizedBox(height: 2),
                          Text(
                            'No tienes cuotas pendientes por pagar.',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuePaymentCard extends StatelessWidget {
  final PaymentEntity payment;
  final NumberFormat currency;

  const _DuePaymentCard({required this.payment, required this.currency});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final due = DateTime(payment.expectedDate.year, payment.expectedDate.month,
        payment.expectedDate.day);
    final daysLeft = due.difference(start).inDays;

    String label;
    if (daysLeft > 1) {
      label = 'Faltan $daysLeft días';
    } else if (daysLeft == 1) {
      label = 'Vence mañana';
    } else if (daysLeft == 0) {
      label = 'Vence hoy';
    } else {
      label = 'Atrasado ${daysLeft.abs()} día(s)';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.warning),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Próximo pago',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(payment.amount),
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vence: ${DateFormat('dd/MM/yyyy').format(payment.expectedDate)} · Cuota #${payment.paymentNumber}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
