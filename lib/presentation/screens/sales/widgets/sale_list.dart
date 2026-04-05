import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/sale_model.dart';
import '../../../providers/sale_provider.dart';
import '../../../providers/product_provider.dart';
import 'sale_card.dart';
import '../dialogs/edit_sale_dialog.dart';

class SaleList extends ConsumerWidget {
  final List<SaleModel> sales;

  const SaleList({super.key, required this.sales});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si la liste fournie par l'écran parent est vide
    if (sales.isEmpty) {
      return const Center(
        child: Text(
          'Aucune vente trouvée pour cette période',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // On retourne directement la liste pure
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
    showEditSaleDialog(context, sale);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SaleModel sale) {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(saleNotifierProvider.notifier).deleteSale(sale);
                ref.invalidate(salesProvider);
                ref.invalidate(productsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Vente supprimée'),
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
