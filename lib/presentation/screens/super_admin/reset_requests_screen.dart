import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../providers/super_admin_provider.dart';

class ResetRequestsScreen extends ConsumerWidget {
  const ResetRequestsScreen({super.key});

  Future<void> _validate(BuildContext context, WidgetRef ref, String id) async {
    final validatorId = await SecureStorageService.getUserId();
    if (validatorId == null) return;
    try {
      final tempPassword =
          await ref.read(superAdminRepositoryProvider).validateResetRequest(id, validatorId);
      ref.invalidate(pendingResetRequestsProvider);
      ref.invalidate(superAdminStatsProvider);
      if (context.mounted) {
        // 🆕 Affiche le MDP temporaire à communiquer au client
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('✅ Demande validée'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Mot de passe temporaire à communiquer au client :',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SelectableText(
                tempPassword,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Le client devra le changer dès sa prochaine connexion.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ]),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copier'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: tempPassword));
                  Navigator.pop(context);
                },
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String id) async {
    final validatorId = await SecureStorageService.getUserId();
    if (validatorId == null) return;
    await ref.read(superAdminRepositoryProvider).rejectResetRequest(id, validatorId);
    ref.invalidate(pendingResetRequestsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingResetRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset mot de passe')),
      body: requests.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('Aucune demande en attente'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final r = list[i];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(r.phoneNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text('Le: ${r.createdAt.toLocal().toString().substring(0, 16)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green, size: 30),
                          onPressed: () => _validate(context, ref, r.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                          onPressed: () => _reject(context, ref, r.id),
                        ),
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