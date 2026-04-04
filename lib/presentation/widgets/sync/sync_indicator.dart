import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facil_count_nouveau/presentation/providers/sync_provider.dart';
import 'package:facil_count_nouveau/presentation/screens/conflicts/conflict_resolution_screen.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final pendingCount = ref.watch(pendingCountProvider);
    final conflictCount = ref.watch(conflictCountProvider);

    return connectivity.when(
      data: (isOnline) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur connexion
            Icon(
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              size: 20,
              color: isOnline ? Colors.green : Colors.grey,
            ),
            
            // Badge conflits
            conflictCount.when(
              data: (count) {
                if (count == 0) return const SizedBox.shrink();
                return _Badge(
                  count: count,
                  color: Colors.red,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConflictResolutionScreen(),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Badge pending
            pendingCount.when(
              data: (count) {
                if (count == 0) return const SizedBox.shrink();
                return _Badge(
                  count: count,
                  color: Colors.orange,
                  onTap: () => _showPendingDialog(context, ref),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showPendingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Synchronisation'),
        content: const Text(
          'Des modifications sont en attente de synchronisation. '
          'Elles seront envoyées automatiquement quand vous serez connecté.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(syncStateProvider.notifier).sync();
              Navigator.pop(context);
            },
            child: const Text('Synchroniser maintenant'),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _Badge({
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}