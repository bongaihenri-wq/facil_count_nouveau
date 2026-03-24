import 'package:facil_count_nouveau/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/sale_model.dart';
import '../../../providers/sale_provider.dart';
import 'sale_card.dart';
import '../dialogs/edit_sale_dialog.dart';
import '../../../providers/product_provider.dart';

// Provider pour la période sélectionnée
final selectedPeriodProvider = StateProvider<String>((ref) => 'Mois');

class SaleList extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final allSales = ref.watch(filteredSalesProvider);
    final filteredSales = _filterByPeriod(allSales, selectedPeriod);

    if (filteredSales.isEmpty) {
      return const Center(child: Text('Aucune vente trouvée'));
    }

    final total = filteredSales.fold<double>(0, (sum, s) => sum + s.amount);

    return Column(
      children: [
        // Carte Total
        _buildTotalCard(total),
        // Filtres période
        _buildPeriodFilterChips(ref, selectedPeriod),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: filteredSales.length,
            itemBuilder: (context, index) => SaleCard(
              sale: filteredSales[index],
              onEdit: () => _showEditDialog(context, ref, filteredSales[index]),
              onDelete: () =>
                  _confirmDelete(context, ref, filteredSales[index]),
            ),
          ),
        ),
      ],
    );
  }

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
                  // ✅ CORRIGÉ : Un seul argument
                  Formatters.formatCurrency(total),
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

  // Filtres période
  Widget _buildPeriodFilterChips(WidgetRef ref, String selectedPeriod) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Semaine', 'Mois', 'Année'].map((period) {
            final isSelected = period == selectedPeriod;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(period, style: const TextStyle(fontSize: 13)),
                selected: isSelected,
                onSelected: (_) =>
                    ref.read(selectedPeriodProvider.notifier).state = period,
                selectedColor: Colors.green.shade700,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, SaleModel sale) {
    if (sale.locked) {
      // Afficher dialogue verrouillé directement
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Vente verrouillée'),
            ],
          ),
          content: const Text(
            'Cette vente est verrouillée et ne peut pas être modifiée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } else {
      // Édition normale
      showEditSaleDialog(context, sale);
    }
  }
}

void _confirmDelete(BuildContext context, WidgetRef ref, SaleModel sale) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Supprimer ?'),
      content: Text('${sale.productName} - ${sale.formattedAmount}'),
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
