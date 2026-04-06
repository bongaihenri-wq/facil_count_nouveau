import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_filter_helper.dart';
import '../../../core/utils/period_picker_bottom_sheet.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/purchase_provider.dart';
import '../../../data/models/purchase_model.dart';
import '../purchases/purchase_list.dart';
import '/presentation/screens/purchases/purchase_dashboard.dart'; 
import '../purchases/dialogs/add_purchase_dialog.dart'; 

// 🎯 Le provider d'état pour la période des achats (par défaut : mois en cours)
final selectedPurchasePeriodProvider = StateProvider<DateFilterRange>((ref) {
  return DateFilterHelper.defaultRange();
});

class PurchaseScreen extends ConsumerWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. On écoute d'abord la période sélectionnée 🟢
    final currentPurchasePeriod = ref.watch(selectedPurchasePeriodProvider);
    
    // 2. On passe cette période au provider pour l'état asynchrone 🟢
    final purchasesAsync = ref.watch(purchasesProvider(currentPurchasePeriod));
    
    final selectedTab = ref.watch(purchaseTabProvider);
    final filters = ref.watch(purchaseFiltersProvider);

    // Couleur thématique passée en bleu comme convenu pour les achats
    final themeColor = Colors.blue.shade700;  

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      
      // 🏷️ APP BAR
      appBar: AppBar(
        title: const Text('Achats'),
        backgroundColor: themeColor,
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
              onPressed: () {
                // TODO: Implémenter showPurchaseFilterDialog(context) si nécessaire
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAddPurchaseDialog(context),
          ),
        ],
      ),
      
      // 🛠️ CORPS DE L'ÉCRAN (Branché sur les états Supabase)
      body: purchasesAsync.when(
        // Cas 1 : Données chargées avec succès !
        data: (allPurchases) {
          // 🟢 On applique les filtres secondaires ici à la volée sur la liste brute
          final purchases = !filters.isActive 
              ? allPurchases 
              : allPurchases.where((purchase) {
                  if (filters.productId != null && purchase.productId != filters.productId) return false;
                  if (filters.supplierId != null && !(purchase.supplier?.toLowerCase().contains(filters.supplierId!.toLowerCase()) ?? false)) return false;
                  return true;
                }).toList();

          return Column(
            children: [
              // 📅 FILTRE PÉRIODE
              GestureDetector(
                onTap: () => _showPeriodPicker(context, ref),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, size: 18, color: themeColor),
                      const SizedBox(width: 8),
                      Text(
                        currentPurchasePeriod.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 20, color: themeColor),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // 🗂️ SÉLECTION LISTE / DASHBOARD
              Container(
                color: Colors.blue.shade50, 
                child: Row(
                  children: [
                    _buildTab(context, ref, 'Liste', 0, themeColor),
                    _buildTab(context, ref, 'Dashboard', 1, themeColor),
                  ],
                ),
              ),

              // 💰 TOTAL ACHATS ÉPURÉ
              _buildTotalCard(purchases, themeColor),

              // 📝 CONTENU DYNAMIQUE SELON L'ONGLET
              Expanded(
                child: selectedTab == 0
                    ? _buildListContent(purchases)
                    : PurchaseDashboard(purchases: purchases), 
              ),
            ],
          );
        },
        
        // Cas 2 : C'est en train de charger depuis Supabase
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
        
        // Cas 3 : Il y a eu une erreur de connexion
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Erreur de chargement des achats : $err',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddPurchaseDialog(context),
        backgroundColor: themeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildTotalCard(List<PurchaseModel> purchases, Color themeColor) {
    if (purchases.isEmpty) return const SizedBox.shrink();
    
    final double totalAmount = purchases.fold(0, (sum, item) => sum + item.amount);
    
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
            'Total achats',
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
              color: themeColor,
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
          ref.read(selectedPurchasePeriodProvider.notifier).state = newRange;
        },
      ),
    );
  }

  void _openAddPurchaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddPurchaseDialog(),
    );
  }

  Widget _buildListContent(List<PurchaseModel> purchases) {
    if (purchases.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: PurchaseList(purchases: purchases),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_checkout_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun achat pour cette période',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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

  Widget _buildTab(BuildContext context, WidgetRef ref, String label, int index, Color themeColor) {
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
                color: isSelected ? themeColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? themeColor : Colors.grey,
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
      selectedItemColor: Colors.orange.shade800, 
      unselectedItemColor: Colors.grey[400],
      currentIndex: 1, 
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/');
            break;
          case 1:
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/sales');
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
