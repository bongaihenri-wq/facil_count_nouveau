import 'package:facil_count_nouveau/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/sale_model.dart';
import '../../../providers/sale_provider.dart';
import 'sale_card.dart';
import '../dialogs/edit_sale_dialog.dart';
import '../../../providers/product_provider.dart';

final selectedPeriodProvider = StateProvider<String>((ref) => 'Mois');

class SaleList extends StatelessWidget {
  final List<SaleModel> sales;

  const SaleList({super.key, required this.sales});

  List<SaleModel> _filterByPeriod(List<SaleModel> sales, String period) {
    final now = DateTime.now();

    return sales.where((sale) {
      switch (period) {
        case 'Semaine':
          final weekAgo = now.subtract(const Duration(days: 7));
          return sale.saleDate.isAfter(weekAgo);
        case 'Mois':
          return sale.saleDate.month == now.month &&
              sale.saleDate.year == now.year;
        case 'Année':
          return sale.saleDate.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedPeriod = ref.watch(selectedPeriodProvider);
        final filteredSales = _filterByPeriod(sales, selectedPeriod);

        if (filteredSales.isEmpty) {
          return _buildEmptyState(context, ref);
        }

        final total = filteredSales.fold<double>(0, (sum, s) => sum + s.amount);

        return Column(
          children: [
            _buildTotalCard(total),
            _buildPeriodFilterChips(ref, selectedPeriod),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: filteredSales.length,
                itemBuilder: (context, index) {
                  final sale = filteredSales[index];
                  return SaleCard(
                    sale: sale,
                    onEdit: () => _showEditDialog(context, ref, sale),
                    onDelete: () => _confirmDelete(context, ref, sale),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Aucune vente pour cette période',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(selectedPeriodProvider.notifier).state = 'Tout';
            },
            icon: const Icon(Icons.clear),
            label: const Text('Voir toutes les ventes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total période',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              Formatters.formatCurrency(total),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilterChips(WidgetRef ref, String selectedPeriod) {
    final periods = ['Semaine', 'Mois', 'Année', 'Tout'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: periods.map((period) {
          final isSelected = selectedPeriod == period;
          return ChoiceChip(
            label: Text(period),
            selected: isSelected,
            selectedColor: Colors.green.shade100,
            onSelected: (_) {
              ref.read(selectedPeriodProvider.notifier).state = period;
            },
          );
        }).toList(),
      ),
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
