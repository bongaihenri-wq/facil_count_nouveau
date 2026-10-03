import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/super_admin_provider.dart';

class AllUsersScreen extends ConsumerStatefulWidget {
  const AllUsersScreen({super.key});

  @override
  ConsumerState<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends ConsumerState<AllUsersScreen> {
  Map<String, DateTime> _activity = {};

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    final map =
        await ref.read(superAdminRepositoryProvider).getUsersLastActivity();
    if (mounted) setState(() => _activity = map);
  }

  String _activityText(String userId) {
    final dt = _activity[userId];
    if (dt == null) return 'Aucune activité';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Actif il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Actif il y a ${diff.inHours} h';
    if (diff.inDays < 30) return 'Actif il y a ${diff.inDays} j';
    return 'Dernière activité: ${dt.toLocal().toString().substring(0, 10)}';
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tous les utilisateurs')),
      body: users.when(
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allUsersProvider);
            await _loadActivity();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final u = list[i];
              final roleColor = u.role == 'super_admin'
                  ? Colors.deepPurple
                  : (u.role == 'admin' ? Colors.blue : Colors.grey);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: roleColor,
                    child: Text(
                      u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text('${u.firstName} ${u.lastName}'.trim()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${u.phoneNumber}\n${u.email ?? ''}'),
                      // 🆕 ACTIVITÉ
                      Text(_activityText(u.id),
                          style: TextStyle(
                            fontSize: 11,
                            color: _activity.containsKey(u.id)
                                ? Colors.green.shade700
                                : Colors.grey,
                            fontStyle: FontStyle.italic)),
                    ]),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                        child: Text(u.role, style: const TextStyle(fontSize: 11)),
                      ),
                      Text(u.isActive ? '✅ Actif' : '❌ Inactif',
                          style: const TextStyle(fontSize: 11)),
                    ]),
                ),
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}