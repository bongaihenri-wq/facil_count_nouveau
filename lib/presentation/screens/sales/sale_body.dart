import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sale_provider.dart';
import '../../../data/models/sale_model.dart';
import 'widgets/sale_list.dart';
import 'widgets/sale_dashboard.dart';
import 'dialogs/add_sale_dialog.dart';
import 'dialogs/filter_dialog.dart';

class SaleBody extends ConsumerWidget {
  const SaleBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesProvider);
    final filteredSales = ref.watch(filteredSalesProvider);
    final selectedTab = ref.watch(saleTabProvider);
    final filters = ref.watch(saleFiltersProvider);

    return salesAsync.when(
      data: (_) => Column(
        children: [
          // TABS
          Container(
            color: Colors.green.shade50,
            child: Row(
              children: [
                _buildTab(context, ref, 'Liste', 0),
                _buildTab(context, ref, 'Dashboard', 1),
              ],
            ),
          ),
          Expanded(
            child: selectedTab == 0
                ? _buildListContent(filteredSales, filters, ref, context)
                : _buildDashboardContent(filteredSales),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur: $err')),
    );
  }

  Widget _buildListContent(
    List<SaleModel> sales,
    SaleFilters filters,
    WidgetRef ref,
    BuildContext context,
  ) {
    if (sales.isEmpty && filters.isActive) {
      return _buildEmptyFilterState(filters, ref, context);
    }

    if (sales.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SaleList(sales: sales),
    );
  }

  Widget _buildDashboardContent(
    List<SaleModel> sales,
  ) {
    if (sales.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: SaleDashboard(sales: sales),
    );
  }

  Widget _buildEmptyFilterState(
    SaleFilters filters,
    WidgetRef ref,
    BuildContext context,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucune vente pour cette période',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Période: ${_getPeriodLabel(filters.period)}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(saleFiltersProvider.notifier).state = SaleFilters();
            },
            icon: const Icon(Icons.clear),
            label: const Text('Réinitialiser le filtre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showSaleFilterDialog(context),
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
            Icons.point_of_sale_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune vente',
            style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par enregistrer une vente',
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
    final currentTab = ref.watch(saleTabProvider);
    final isSelected = currentTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(saleTabProvider.notifier).state = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.green.shade700 : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.green.shade700 : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}