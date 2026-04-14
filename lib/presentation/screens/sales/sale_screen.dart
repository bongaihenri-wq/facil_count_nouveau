import 'package:facil_count_nouveau/presentation/providers/auth_provider.dart';
import 'package:facil_count_nouveau/presentation/widgets/subscription_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_filter_helper.dart';
import '../../../core/utils/period_picker_bottom_sheet.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/sale_provider.dart';
import '../../../data/models/sale_model.dart';
import 'widgets/sale_list.dart';
import 'widgets/sale_dashboard.dart';
import '../sales/dialogs/add_sale_dialog.dart';
import 'dialogs/filter_dialog.dart';

// 🎯 Le provider d'état pour la période (par défaut : mois en cours)
// On l'appelle différemment pour ne pas entrer en conflit avec celui des dépenses
final selectedSalePeriodProvider = StateProvider<DateFilterRange>((ref) {
  return DateFilterHelper.defaultRange();
});

class SaleScreen extends ConsumerWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final currentSalePeriod = ref.watch(selectedSalePeriodProvider);
    final salesAsync = ref.watch(salesProvider(currentSalePeriod));
    final filteredSales = ref.watch(filteredSalesProvider);
    final selectedTab = ref.watch(saleTabProvider);
    final filters = ref.watch(saleFiltersProvider);
    
    // 🛡️ On récupère la période actuelle
    final currentPeriod = ref.watch(selectedSalePeriodProvider);
     
    if (!auth.canAccessApp) 
    return const SubscriptionOverlay();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      
      // 🏷️ 1. APP BAR
      appBar: AppBar(
        title: const Text('Ventes'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: filters.isActive ? Colors.red : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: filters.isActive ? Colors.white : Colors.white70,
                size: filters.isActive ? 28 : 24,
              ),
              onPressed: () => showSaleFilterDialog(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAddSaleDialog(context),
          ),
        ],
      ),
      
      body: salesAsync.when(
        data: (_) => Column(
          children: [
            // 📅 2. FILTRE PÉRIODE (Juste en dessous de l'app bar)
            GestureDetector(
              onTap: () => _showPeriodPicker(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month, size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      currentPeriod.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 20, color: Colors.green.shade700),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // 🗂️ 3. SÉLECTION LISTE / DASHBOARD (Les onglets)
            Container(
              color: Colors.green.shade50,
              child: Row(
                children: [
                  _buildTab(context, ref, 'Liste', 0),
                  _buildTab(context, ref, 'Dashboard', 1),
                ],
              ),
            ),

            // 💰 4. TOTAL VENTES ÉPURÉ (Juste au-dessus du contenu)
            _buildTotalCard(filteredSales),

            // 📝 5. CONTENU
            Expanded(
              child: selectedTab == 0
                  ? _buildListContent(filteredSales)
                  : _buildDashboardContent(filteredSales),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSaleDialog(context),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // Widget épuré pour le montant total
  Widget _buildTotalCard(List<SaleModel> sales) {
    if (sales.isEmpty) return const SizedBox.shrink();
    
    // Calcul de la somme totale des ventes filtrées
    final double totalAmount = sales.fold(0, (sum, item) => sum + item.amount);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total ventes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${Formatters.formatCurrency(totalAmount)} FCFA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showPeriodPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PeriodPickerBottomSheet(
        onPeriodSelected: (newRange) {
          ref.read(selectedSalePeriodProvider.notifier).state = newRange;
        },
      ),
    );
  }

  void _openAddSaleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddSaleDialog(),
    );
  }

  Widget _buildListContent(List<SaleModel> sales) {
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
      padding: const EdgeInsets.only(bottom: 20),
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
            'Aucune vente pour cette période',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.green.shade700,
      unselectedItemColor: Colors.grey[400],
      currentIndex: 2,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/purchases');
            break;
          case 2:
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/more');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Achats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale_outlined),
          activeIcon: Icon(Icons.point_of_sale),
          label: 'Ventes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.apps_outlined),
          activeIcon: Icon(Icons.apps),
          label: 'Plus',
        ),
      ],
    );
  }
}