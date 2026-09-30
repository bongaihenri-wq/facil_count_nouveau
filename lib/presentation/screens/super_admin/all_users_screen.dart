import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/super_admin_provider.dart';

class AllUsersScreen extends ConsumerWidget {
  const AllUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tous les utilisateurs')),
      body: users.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final u = list[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: u.role == 'super_admin'
                      ? Colors.deepPurple
                      : (u.role == 'admin' ? Colors.blue : Colors.grey),
                  child: Text(u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text('${u.firstName} ${u.lastName}'.trim()),
                subtitle: Text('${u.phoneNumber}\n${u.email ?? ''}'),
                isThreeLine: true,
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (u.role == 'super_admin' ? Colors.deepPurple : Colors.blue).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(u.role, style: const TextStyle(fontSize: 11)),
                  ),
                  Text(u.isActive ? '✅ Actif' : '❌ Inactif', style: const TextStyle(fontSize: 11)),
                ]),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}