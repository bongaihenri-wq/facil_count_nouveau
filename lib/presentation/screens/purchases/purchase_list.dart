// lib/presentation/screens/purchases/widgets/purchase_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/purchase_model.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/product_provider.dart';
import 'purchase_card.dart'; // À créer sur le calque de sale_card.dart
import '../purchases/dialogs/edit_purchase_dialog.dart'; // À créer également

class PurchaseList extends ConsumerWidget {
  final List<PurchaseModel> purchases;

  const PurchaseList({super.key, required this.purchases});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si la liste fournie par l'écran parent est vide
    if (purchases.isEmpty) {
      return const Center(
        child: Text(
          'Aucun achat trouvé pour cette période',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // On retourne directement la liste pure
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
    showEditPurchaseDialog(context, purchase);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PurchaseModel purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer cet achat ?\n\n'
          '${purchase.quantity} x ${purchase.productName ?? "Produit"}\n'
          'Montant: ${purchase.formattedAmount}', // S'assurer que formattedAmount existe dans le modèle
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(purchaseNotifierProvider.notifier).deletePurchase(purchase);
                ref.invalidate(purchasesProvider);
                ref.invalidate(productsProvider);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Achat supprimé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
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
