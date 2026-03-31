// lib/presentation/screens/purchases/purchase_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/purchase_model.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/product_provider.dart';
import 'purchase_card.dart';
import '../purchases/dialogs/edit_purchase_dialog.dart';
import 'package:facil_count_nouveau/core/utils/formatters.dart';

final selectedPeriodProvider = StateProvider<String>((ref) => 'Mois');

class PurchaseList extends StatelessWidget {
  final List<PurchaseModel> purchases;

  const PurchaseList({super.key, required this.purchases});

  List<PurchaseModel> _filterByPeriod(List<PurchaseModel> purchases, String period) {
    final now = DateTime.now();

    return purchases.where((purchase) {
      switch (period) {
        case 'Semaine':
          final weekAgo = now.subtract(const Duration(days: 7));
          return purchase.purchaseDate.isAfter(weekAgo);
        case 'Mois':
          return purchase.purchaseDate.month == now.month &&
              purchase.purchaseDate.year == now.year;
        case 'Année':
          return purchase.purchaseDate.year == now.year;
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
        final filteredPurchases = _filterByPeriod(purchases, selectedPeriod);

        if (filteredPurchases.isEmpty) {
          return _buildEmptyState(context, ref);
        }

        final total = filteredPurchases.fold<double>(0, (sum, p) => sum + p.amount);

        return Column(
          children: [
            _buildTotalCard(total),
            _buildPeriodFilterChips(ref, selectedPeriod),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: filteredPurchases.length,
                itemBuilder: (context, index) => PurchaseCard(
                  purchase: filteredPurchases[index],
                  onEdit: () => _showEditDialog(context, ref, filteredPurchases[index]),
                  onDelete: () => _confirmDelete(context, ref, filteredPurchases[index]),
                ),
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
            'Aucun achat pour cette période',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(selectedPeriodProvider.notifier).state = 'Tout';
            },
            icon: const Icon(Icons.clear),
            label: const Text('Voir tous les achats'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700, // 🔥 BLEU
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
                color: Colors.blue.shade700, // 🔥 BLEU
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
            selectedColor: Colors.blue.shade100, // 🔥 BLEU
            onSelected: (_) {
              ref.read(selectedPeriodProvider.notifier).state = period;
            },
          );
        }).toList(),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, PurchaseModel purchase) {
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

 void _confirmDelete(BuildContext context, WidgetRef ref, PurchaseModel purchase) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmer la suppression'),
      content: const Text('Voulez-vous vraiment supprimer cet achat ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            await ref.read(purchaseNotifierProvider.notifier).deletePurchase(purchase);  // ← CORRIGÉ
            ref.invalidate(purchasesProvider);
            ref.invalidate(productsProvider);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
}
