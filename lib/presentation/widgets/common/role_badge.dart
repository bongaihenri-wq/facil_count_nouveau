import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.orange.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? Colors.orange : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            size: 12,
            color: isAdmin ? Colors.orange.shade800 : Colors.blue.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            isAdmin ? 'Admin' : 'Utilisateur',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isAdmin ? Colors.orange.shade800 : Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
