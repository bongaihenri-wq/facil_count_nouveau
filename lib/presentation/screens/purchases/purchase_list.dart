import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/purchase_model.dart';
import '../../../../data/repositories/lock_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/product_provider.dart';
import 'purchase_card.dart';
import '../purchases/dialogs/edit_purchase_dialog.dart';

class PurchaseList extends ConsumerWidget {
  final List<PurchaseModel> purchases;

  const PurchaseList({super.key, required this.purchases});

  bool _isAdmin(WidgetRef ref) {
    final role = ref.read(authProvider).currentUser?.role;
    return role == 'admin' || role == 'super_admin';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (purchases.isEmpty) {
      return const Center(
        child: Text(
          'Aucun achat trouvé pour cette période',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        return PurchaseCard(
          purchase: purchase,
          onEdit: () => _showEditDialog(context, ref, purchase),
          onDelete: () => _confirmDelete(context, ref, purchase),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, PurchaseModel purchase) {
    if (purchase.locked) {
      _showLockedInfo(context, ref, purchase);
      return;
    }
    showEditPurchaseDialog(context, purchase);
  }

  void _showLockedInfo(BuildContext context, WidgetRef ref, PurchaseModel purchase) {
    final isAdmin = _isAdmin(ref);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('Achat verrouillé'),
          ],
        ),
        content: Text(
          '${purchase.quantity} x ${purchase.productName ?? "Produit"} — ${purchase.formattedAmount}\n\n'
          'Cet achat est protégé (point de contrôle).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          if (isAdmin)
            TextButton.icon(
              icon: const Icon(Icons.lock_open, color: Colors.red, size: 18),
              label: const Text('Déverrouiller', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await LockRepository()
                      .toggleSingle(actionType: 'Achats', id: purchase.id, lock: false);
                  ref.invalidate(purchasesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🔓 Achat déverrouillé')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: Colors.red));
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PurchaseModel purchase) {
    if (purchase.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Impossible de supprimer un achat verrouillé'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer cet achat ?\n\n'
          '${purchase.quantity} x ${purchase.productName ?? "Produit"}\n'
          'Montant: ${purchase.formattedAmount}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(purchaseNotifierProvider.notifier).deletePurchase(purchase);
                ref.invalidate(purchasesProvider);
                ref.invalidate(productsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Achat supprimé'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}