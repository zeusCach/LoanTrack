import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionHeader('Apariencia'),
          _ThemeOption(
            label: 'Sistema',
            description: 'Sigue la configuración del dispositivo',
            mode: ThemeMode.system,
            current: themeMode,
            icon: Icons.brightness_auto_rounded,
            onSelect: (m) => ref.read(themeModeProvider.notifier).set(m),
          ),
          _ThemeOption(
            label: 'Claro',
            description: 'Tema predeterminado',
            mode: ThemeMode.light,
            current: themeMode,
            icon: Icons.light_mode_rounded,
            onSelect: (m) => ref.read(themeModeProvider.notifier).set(m),
          ),
          _ThemeOption(
            label: 'Oscuro',
            description: 'Reduce el brillo en ambientes oscuros',
            mode: ThemeMode.dark,
            current: themeMode,
            icon: Icons.dark_mode_rounded,
            onSelect: (m) => ref.read(themeModeProvider.notifier).set(m),
          ),
          const SizedBox(height: 8),
          const _SectionHeader('Mi perfil'),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Nombre'),
            subtitle: Text(user?.name ?? '—'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: user == null
                ? null
                : () => _editName(context, ref, user.uid, user.name),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Correo'),
            subtitle: Text(user?.email ?? '—'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset_rounded),
            title: const Text('Cambiar mi contraseña'),
            subtitle: const Text('Te enviaremos un correo para restablecerla'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: user == null
                ? null
                : () => _sendReset(context, ref, user.email),
          ),
          const SizedBox(height: 8),
          const _SectionHeader('Clientes'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(
              'Para editar el nombre o restablecer la contraseña de un cliente, '
              'abre su detalle desde la pestaña Clientes y usa el menú ⋮.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String uid,
    String currentName,
  ) async {
    final newName = await _showNameDialog(context, currentName);
    if (newName == null || newName == currentName) return;
    try {
      await ref
          .read(authRepositoryProvider)
          .updateUserName(uid: uid, name: newName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nombre actualizado'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _sendReset(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar correo'),
        content: Text(
          'Se enviará un enlace de restablecimiento a $email. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correo enviado a $email'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

Future<String?> _showNameDialog(
  BuildContext context,
  String initial,
) async {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Editar nombre'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nombre'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final String description;
  final ThemeMode mode;
  final ThemeMode current;
  final IconData icon;
  final ValueChanged<ThemeMode> onSelect;

  const _ThemeOption({
    required this.label,
    required this.description,
    required this.mode,
    required this.current,
    required this.icon,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: current,
      onChanged: (v) {
        if (v != null) onSelect(v);
      },
      title: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
      subtitle: Text(description),
      activeColor: AppColors.primary,
    );
  }
}
