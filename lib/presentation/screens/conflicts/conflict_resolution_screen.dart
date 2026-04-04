import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:facil_count_nouveau/presentation/providers/sync_provider.dart';
import 'package:facil_count_nouveau/core/services/sync_service.dart';
import 'package:facil_count_nouveau/data/models/sync_models.dart';

class ConflictResolutionScreen extends ConsumerWidget {
  const ConflictResolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictsAsync = ref.watch(pendingConflictsProvider);
    final syncState = ref.watch(syncStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conflits à résoudre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.read(syncStateProvider.notifier).sync(),
          ),
        ],
      ),
      body: conflictsAsync.when(
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return const _EmptyState();
          }
          return _ConflictList(conflicts: conflicts);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun conflit',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Toutes les données sont synchronisées',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

class _ConflictList extends StatelessWidget {
  final List<Conflict> conflicts;

  const _ConflictList({required this.conflicts});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conflicts.length,
      itemBuilder: (context, index) {
        return _ConflictCard(conflict: conflicts[index]);
      },
    );
  }
}

class _ConflictCard extends ConsumerWidget {
  final Conflict conflict;

  const _ConflictCard({required this.conflict});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocalNewer = conflict.isLocalNewer;
    final fieldLabel = _getFieldLabel(conflict.field);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.entityName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Conflit sur: $fieldLabel',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Versions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Version locale
                Expanded(
                  child: _VersionBox(
                    title: 'VOTRE VERSION',
                    subtitle: _formatDate(conflict.localTime),
                    value: conflict.localValue?.toString() ?? '-',
                    isNewer: isLocalNewer,
                    color: Colors.blue,
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.compare_arrows, color: Colors.grey),
                ),

                // Version distante
                Expanded(
                  child: _VersionBox(
                    title: 'VERSION SERVEUR',
                    subtitle: _formatDate(conflict.remoteTime),
                    value: conflict.remoteValue?.toString() ?? '-',
                    isNewer: !isLocalNewer,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _resolve(context, ref, ConflictResolution.keepLocal),
                        icon: const Icon(Icons.phone_android),
                        label: const Text('Garder la mienne'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _resolve(context, ref, ConflictResolution.keepRemote),
                        icon: const Icon(Icons.cloud),
                        label: const Text('Prendre serveur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (conflict.field == 'description') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showMergeDialog(context, ref),
                    icon: const Icon(Icons.edit),
                    label: const Text('Fusionner manuellement'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'name':
        return 'Nom du produit';
      case 'description':
        return 'Description';
      default:
        return field;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref, ConflictResolution resolution) async {
    final notifier = ref.read(syncStateProvider.notifier);
    
    await notifier.resolveConflict(
      conflictId: conflict.id,
      resolution: resolution,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conflit résolu')),
      );
    }
  }

  Future<void> _showMergeDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: '${conflict.localValue}\n\n---\n\n${conflict.remoteValue}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fusion manuelle'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Saisissez la description fusionnée...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await ref.read(syncStateProvider.notifier).resolveConflict(
        conflictId: conflict.id,
        resolution: ConflictResolution.merge,
        mergedValue: result,
      );
    }
  }
}

class _VersionBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final bool isNewer;
  final Color color;

  const _VersionBox({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isNewer,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isNewer) ...[
                const SizedBox(width: 4),
                Icon(Icons.new_releases, size: 14, color: Colors.green[700]),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}