import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/client_entity.dart';

class ClientCard extends StatelessWidget {
  final ClientEntity client;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;

  const ClientCard({
    super.key,
    required this.client,
    required this.onTap,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              client.isActive ? AppColors.primary : AppColors.secondary,
          child: Text(
            client.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(client.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(client.phone,
            style: const TextStyle(color: AppColors.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: client.isActive
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                client.isActive ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  color: client.isActive ? AppColors.success : AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}
