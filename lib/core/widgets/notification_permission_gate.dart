import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/local_notifications_service.dart';

/// Envuelve el árbol de la app y, una sola vez tras montar, verifica si las
/// notificaciones están habilitadas a nivel sistema. Si no lo están, muestra
/// un diálogo que lleva al usuario a los ajustes de la app.
class NotificationPermissionGate extends StatefulWidget {
  final Widget child;
  const NotificationPermissionGate({super.key, required this.child});

  @override
  State<NotificationPermissionGate> createState() =>
      _NotificationPermissionGateState();
}

class _NotificationPermissionGateState
    extends State<NotificationPermissionGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (_checked) return;
    _checked = true;

    await LocalNotificationsService.instance.initialize();
    final enabled =
        await LocalNotificationsService.instance.areNotificationsEnabled();
    if (enabled) return;
    if (!mounted) return;

    final goToSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Notificaciones desactivadas'),
        content: const Text(
          'Para recibir avisos de pagos, sanciones y vencimientos, '
          'activa las notificaciones de LoanTrack en los ajustes del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );

    if (goToSettings == true) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
