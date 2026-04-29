import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/clients/presentation/providers/client_provider.dart';
import '../../features/clients/presentation/screens/create_client_screen.dart';
import '../../features/loans/presentation/providers/loan_provider.dart';
import '../../features/loans/presentation/screens/client_detail_screen.dart';
import '../../features/loans/presentation/screens/create_loan_screen.dart';
import '../../features/loans/presentation/screens/loan_detail_screen.dart';
import '../constants/app_colors.dart';

/// Resuelve un `ClientEntity` por id desde `clientsStreamProvider` y muestra
/// `ClientDetailScreen`. Existe para que GoRouter pueda enlazar
/// `/admin/clients/:clientId` con la pantalla ya construida que recibe la
/// entidad por constructor.
class ClientDetailRoute extends ConsumerWidget {
  final String clientId;
  const ClientDetailRoute({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsStreamProvider);
    return clientsAsync.when(
      loading: () => const _Loading(title: 'Cliente'),
      error: (e, _) => _Error(title: 'Cliente', message: '$e'),
      data: (clients) {
        final client = clients.where((c) => c.uid == clientId).firstOrNull;
        if (client == null) {
          return const _Error(
            title: 'Cliente',
            message: 'No se encontró el cliente',
          );
        }
        return ClientDetailScreen(client: client);
      },
    );
  }
}

/// Resuelve un `LoanEntity` por id desde `adminLoansProvider` y muestra
/// `LoanDetailScreen`.
class LoanDetailRoute extends ConsumerWidget {
  final String loanId;
  const LoanDetailRoute({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(adminLoansProvider);
    return loansAsync.when(
      loading: () => const _Loading(title: 'Préstamo'),
      error: (e, _) => _Error(title: 'Préstamo', message: '$e'),
      data: (loans) {
        final loan = loans.where((l) => l.id == loanId).firstOrNull;
        if (loan == null) {
          return const _Error(
            title: 'Préstamo',
            message: 'No se encontró el préstamo',
          );
        }
        return LoanDetailScreen(loan: loan);
      },
    );
  }
}

/// `/admin/loans/new` — al ser un préstamo necesariamente asociado a un
/// cliente, primero pide elegirlo de la lista y luego abre `CreateLoanScreen`.
class CreateLoanRoute extends ConsumerWidget {
  const CreateLoanRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Selecciona cliente'),
      ),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (clients) {
          final active = clients.where((c) => c.isActive).toList();
          if (active.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined,
                        size: 56, color: AppColors.secondary),
                    const SizedBox(height: 12),
                    const Text(
                      'No tienes clientes activos para crear un préstamo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const CreateClientScreen(),
                      ),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Crear cliente'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: active.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = active[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                title: Text(c.name),
                subtitle: Text(c.phone.isNotEmpty ? c.phone : c.email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => CreateLoanScreen(
                      clientId: c.uid,
                      clientName: c.name,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  final String title;
  const _Loading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _Error extends StatelessWidget {
  final String title;
  final String message;
  const _Error({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
