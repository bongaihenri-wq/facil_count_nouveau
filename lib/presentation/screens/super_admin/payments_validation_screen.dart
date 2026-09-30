import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../data/repositories/super_admin_repository.dart';
import '../../providers/super_admin_provider.dart';

class PaymentsValidationScreen extends ConsumerWidget {
  const PaymentsValidationScreen({super.key});

  Future<void> _validate(BuildContext context, WidgetRef ref, String paymentId) async {
    final validatorId = await SecureStorageService.getUserId();
    if (validatorId == null) return;
    try {
      await ref.read(superAdminRepositoryProvider).validatePayment(paymentId, validatorId);
      ref.invalidate(pendingPaymentsProvider);
      ref.invalidate(superAdminStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Paiement validé — compte réactivé automatiquement')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String paymentId) async {
    final validatorId = await SecureStorageService.getUserId();
    if (validatorId == null) return;
    await ref.read(superAdminRepositoryProvider).rejectPayment(paymentId, validatorId);
    ref.invalidate(pendingPaymentsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(pendingPaymentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements en attente')),
      body: payments.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('Aucun paiement en attente 🎉'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${p.planType.toUpperCase()} — ${p.amount.toStringAsFixed(0)} ${p.currency}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Méthode: ${p.paymentMethod ?? 'manuel'}  •  Tél: ${p.phoneNumber ?? '-'}'),
                        if (p.reference != null) Text('Réf: ${p.reference}'),
                        Text('Le: ${p.createdAt.toLocal().toString().substring(0, 16)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text('Valider', style: TextStyle(color: Colors.white)),
                              onPressed: () => _validate(context, ref, p.id),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                              onPressed: () => _reject(context, ref, p.id),
                            ),
                          ),
                        ]),
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