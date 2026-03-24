import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/purchase_model.dart';
import '../../providers/purchase_provider.dart';
import 'dialogs/edit_purchase_dialog.dart';
import 'purchase_card.dart';
import 'package:facil_count_nouveau/core/utils/formatters.dart';

final selectedPeriodProvider = StateProvider<String>((ref) => 'Mois');

class PurchaseList extends ConsumerWidget {
  final List<PurchaseModel> purchases;

  const PurchaseList({super.key, required this.purchases});

  List<PurchaseModel> _filterByPeriod(
    List<PurchaseModel> purchases,
    String period,
  ) {
    final now = DateTime.now();
    return purchases.where((p) {
      switch (period) {
        case 'Semaine':
          return p.purchaseDate.isAfter(now.subtract(const Duration(days: 7)));
        case 'Mois':
          return p.purchaseDate.month == now.month &&
              p.purchaseDate.year == now.year;
        case 'Année':
          return p.purchaseDate.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final filtered = _filterByPeriod(purchases, selectedPeriod);

    if (filtered.isEmpty) {
      return const Center(child: Text('Aucun achat trouvé'));
    }

    final total = filtered.fold<double>(0, (sum, p) => sum + p.amount);

    return Column(
      children: [
        _buildTotalCard(total),
        _buildPeriodFilterChips(ref, selectedPeriod),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filtered.length,
            itemBuilder: (context, index) => PurchaseCard(
              purchase: filtered[index],
              onEdit: () => _showEditDialog(context, ref, filtered[index]),
              onDelete: () => _confirmDelete(context, ref, filtered[index]),
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
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Total achats',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                Formatters.formatCurrency(total), // ← SÉPARATEUR DE MILLIERS
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                label: Text(period),
                selected: isSelected,
                onSelected: (_) =>
                    ref.read(selectedPeriodProvider.notifier).state = period,
                selectedColor: Colors.blue.shade700,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    PurchaseModel purchase,
  ) {
    if (purchase.locked) {
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
          content: const Text(
            'Cet achat est verrouillé et ne peut pas être modifié.',
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
      showEditPurchaseDialog(context, purchase);
    }
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PurchaseModel purchase,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('${purchase.productName} - ${purchase.formattedAmount}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(purchaseNotifierProvider.notifier)
                  .deletePurchase(purchase.id);
              ref.invalidate(purchasesProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
