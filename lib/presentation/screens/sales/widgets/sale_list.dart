import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/sale_model.dart';
import '/presentation/providers/sale_provider.dart';
import 'sale_card.dart';

class SaleList extends ConsumerWidget {
  final List<SaleModel> sales;

  const SaleList({super.key, required this.sales});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sales.isEmpty) {
      return const Center(child: Text('Aucune vente trouvée'));
    }

    final total = sales.fold<double>(0, (sum, s) => sum + s.amount);

    return Column(
      children: [
        // CARTE TOTAL IDENTIQUE À DÉPENSES
        _buildTotalCard(total),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: sales.length,
            itemBuilder: (context, index) => SaleCard(
              sale: sales[index],
              onEdit: () => _showEditDialog(context, ref, sales[index]),
              onDelete: () => _confirmDelete(context, ref, sales[index]),
            ),
          ),
        ),
      ],
    );
  }

  // IDENTIQUE À EXPENSES
  Widget _buildTotalCard(double total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Total ventes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${total.toStringAsFixed(0)} CFA',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, SaleModel sale) {
    // TODO: Implémenter édition
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier (à implémenter)'),
        content: Text(sale.productName ?? 'Vente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SaleModel sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer vente ?'),
        content: Text(
          '${sale.productName} - ${sale.formattedAmount}\n'
          'Le stock sera réapprovisionné.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(saleNotifierProvider.notifier).deleteSale(sale);
              ref.invalidate(salesProvider);
              ref.invalidate(productsProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
