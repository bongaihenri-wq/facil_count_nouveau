import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/sale_model.dart';
import '../../providers/sale_provider.dart';
import '../sales/widgets/sale_list.dart';
import '../sales/widgets/sale_dashboard.dart';
import '../../screens/sales/sale_screen.dart'; // Nécessaire pour selectedSalePeriodProvider

class SaleBody extends ConsumerWidget {
  const SaleBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. On récupère la période sélectionnée pour l'écran des ventes 🟢
    final currentSalePeriod = ref.watch(selectedSalePeriodProvider);

    // 2. On passe cette période au provider (Fini le cast sauvage !) 🟢
    final salesAsync = ref.watch(salesProvider(currentSalePeriod));
    
    final selectedTab = ref.watch(saleTabProvider);
    final filters = ref.watch(saleFiltersProvider);

    return salesAsync.when(
      data: (allSales) {
        // 🟢 Filtrage sécurisé en mémoire sans passer par des IDs externes
        final filteredSales = !filters.isActive 
            ? allSales 
            : allSales.where((sale) {
                if (filters.productId != null && sale.productId != filters.productId) return false;
                if (filters.clientId != null && !(sale.customer?.toLowerCase().contains(filters.clientId!.toLowerCase()) ?? false)) return false;
                return true;
              }).toList();

        return Column(
          children: [
            // Onglets Liste / Dashboard
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
      error: (err, _) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildListContent(
    List<SaleModel> sales,
    SaleFilters filters,
    WidgetRef ref,
    BuildContext context,
  ) {
    if (sales.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SaleList(sales: sales),
    );
  }

  Widget _buildDashboardContent(List<SaleModel> sales) {
    if (sales.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: SaleDashboard(sales: sales),
    );
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
            'Aucune vente effectuée',
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

  Widget _buildTab(BuildContext context, WidgetRef ref, String label, int index) {
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