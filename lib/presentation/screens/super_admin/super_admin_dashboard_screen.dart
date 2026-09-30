import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/super_admin_provider.dart';
import 'payments_validation_screen.dart';
import 'reset_requests_screen.dart';
import 'all_users_screen.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(superAdminStatsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(superAdminStatsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(superAdminStatsProvider),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          stats.when(
            data: (s) => Row(children: [
              _statCard('Utilisateurs', '${s['totalUsers'] ?? 0}', Colors.blue),
              _statCard('Paiements en attente', '${s['pendingPayments'] ?? 0}', Colors.orange),
              _statCard('Reset en attente', '${s['pendingResets'] ?? 0}', Colors.red),
            ]),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e'),
          ),
          const SizedBox(height: 24),
          _menuTile(context, Icons.payments, 'Valider les paiements',
              const PaymentsValidationScreen(), Colors.green),
          _menuTile(context, Icons.lock_reset, 'Demandes reset mot de passe',
              const ResetRequestsScreen(), Colors.orange),
          _menuTile(context, Icons.people, 'Tous les utilisateurs',
              const AllUsersScreen(), Colors.blue),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) => Expanded(
        child: Card(
          color: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ),
      );

  Widget _menuTile(BuildContext context, IconData icon, String title,
          Widget screen, Color color) =>
      Card(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        ),
      );
}