import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/purchase_provider.dart';
import 'dialogs/add_purchase_dialog.dart';
import 'dialogs/filter_purchase_dialog.dart';
import 'purchase_dashboard.dart';
import 'purchase_list.dart';

class PurchaseScreen extends ConsumerWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(purchaseTabProvider);
    final purchasesAsync = ref.watch(filteredPurchasesProvider);
    final filters = ref.watch(purchaseFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achats'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: filters.isActive
                  ? Colors.red
                  : Colors.transparent, // ✅ isActive
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: filters.isActive ? Colors.white : Colors.white70,
                size: filters.isActive ? 28 : 24,
              ),
              onPressed: () => _showFilterDialog(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddPurchaseDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔥 DESIGN IDENTIQUE À EXPENSE (couleur bleue)
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
            child: purchasesAsync.when(
              data: (purchases) => tabIndex == 0
                  ? PurchaseList(purchases: purchases)
                  : PurchaseDashboard(purchases: purchases),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddPurchaseDialog(context),
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
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

  void _showFilterDialog(BuildContext context) {
    showPurchaseFilterDialog(context);
  }
}
