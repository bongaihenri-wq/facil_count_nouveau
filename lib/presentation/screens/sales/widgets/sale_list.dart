import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/sale_model.dart';
import '../../../../data/repositories/lock_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/sale_provider.dart';
import '../../../providers/product_provider.dart';
import 'sale_card.dart';
import '../dialogs/edit_sale_dialog.dart';

class SaleList extends ConsumerWidget {
  final List<SaleModel> sales;

  const SaleList({super.key, required this.sales});

  bool _isAdmin(WidgetRef ref) {
    final role = ref.read(authProvider).currentUser?.role;
    return role == 'admin' || role == 'super_admin';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sales.isEmpty) {
      return const Center(
        child: Text(
          'Aucune vente trouvée pour cette période',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return SaleCard(
          sale: sale,
          onEdit: () => _showEditDialog(context, ref, sale),
          onDelete: () => _confirmDelete(context, ref, sale),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, SaleModel sale) {
    if (sale.locked) {
      _showLockedInfo(context, ref, sale);
      return;
    }
    showEditSaleDialog(context, sale);
  }

  void _showLockedInfo(BuildContext context, WidgetRef ref, SaleModel sale) {
    final isAdmin = _isAdmin(ref);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('Vente verrouillée'),
          ],
        ),
        content: Text(
          '${sale.quantity} x ${sale.productName ?? "Produit"} — ${sale.formattedAmount}\n\n'
          'Cette vente est protégée (point de contrôle).',
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
                      .toggleSingle(actionType: 'Ventes', id: sale.id, lock: false);
                  ref.invalidate(salesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🔓 Vente déverrouillée')));
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

  void _confirmDelete(BuildContext context, WidgetRef ref, SaleModel sale) {
    if (sale.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Impossible de supprimer une vente verrouillée'),
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
          'Voulez-vous vraiment supprimer cette vente ?\n\n'
          '${sale.quantity} x ${sale.productName ?? "Produit"}\n'
          'Montant: ${sale.formattedAmount}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(saleNotifierProvider.notifier).deleteSale(sale);
                ref.invalidate(salesProvider);
                ref.invalidate(productsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Vente supprimée'), backgroundColor: Colors.green),
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