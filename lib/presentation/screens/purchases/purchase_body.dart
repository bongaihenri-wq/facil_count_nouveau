import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/purchase_provider.dart';
import '../../../data/models/purchase_model.dart';
import '../purchases/purchase_list.dart';
import '../purchases/purchase_dashboard.dart';
import 'dialogs/add_purchase_dialog.dart';
import 'dialogs/filter_purchase_dialog.dart';

class PurchaseBody extends ConsumerWidget {
  const PurchaseBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final filteredPurchases = ref.watch(filteredPurchasesProvider);
    final selectedTab = ref.watch(purchaseTabProvider);
    final filters = ref.watch(purchaseFiltersProvider);

    return purchasesAsync.when(
      data: (_) => Column(
        children: [
          // TABS
          Container(
            color: Colors.blue.shade50,
            child: Row(
              children: [
                _buildTab(context, ref, 'Liste', 0),
                _buildTab(context, ref, 'Dashboard', 1),
              ],
            ),
          ),
          Expanded(
            child: selectedTab == 0
                ? _buildListContent(filteredPurchases, filters, ref, context)
                : _buildDashboardContent(filteredPurchases),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur: $err')),
    );
  }

  Widget _buildListContent(
    List<PurchaseModel> purchases,
    PurchaseFilters filters,
    WidgetRef ref,
    BuildContext context,
  ) {
    if (purchases.isEmpty && filters.isActive) {
      return _buildEmptyFilterState(filters, ref, context);
    }

    if (purchases.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: PurchaseList(purchases: purchases),
    );
  }

  Widget _buildDashboardContent(
    List<PurchaseModel> purchases,
  ) {
    if (purchases.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: PurchaseDashboard(purchases: purchases),
    );
  }

  Widget _buildEmptyFilterState(
    PurchaseFilters filters,
    WidgetRef ref,
    BuildContext context,
  ) {
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
          const SizedBox(height: 8),
          Text(
            'Période: ${_getPeriodLabel(filters.period)}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(purchaseFiltersProvider.notifier).clearFilters();
            },
            icon: const Icon(Icons.clear),
            label: const Text('Réinitialiser le filtre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showPurchaseFilterDialog(context),
            icon: const Icon(Icons.filter_list),
            label: const Text('Changer le filtre'),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(String? period) {
    switch (period) {
      case 'day':
        return 'Aujourd\'hui';
      case 'week':
        return 'Cette semaine';
      case 'month':
        return 'Ce mois';
      case 'year':
        return 'Cette année';
      default:
        return 'Sélectionnée';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun achat effectué',
            style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par enregistrer un achat',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    WidgetRef ref,
    String label,
    int index,
  ) {
    final currentTab = ref.watch(purchaseTabProvider);
    final isSelected = currentTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(purchaseTabProvider.notifier).state = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.blue.shade700 : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}