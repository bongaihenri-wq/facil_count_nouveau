import 'package:facil_count_nouveau/presentation/providers/purchase_provider.dart';
import 'package:facil_count_nouveau/presentation/providers/sale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/home_content.dart';
import 'widgets/more_menu.dart';
import '../purchases/purchase_body.dart';
import '../sales/sale_body.dart';
import 'widgets/quick_add_sheet.dart';
// ✅ IMPORTS VENTES (Sales)
import '../sales/dialogs/filter_dialog.dart' as sale_dialogs;
import '../sales/dialogs/add_sale_dialog.dart' as sale_dialogs;
// ✅ IMPORTS ACHATS (Purchases)
import '../purchases/dialogs/filter_purchase_dialog.dart' as purchase_dialogs;
import '../purchases/dialogs/add_purchase_dialog.dart' as purchase_dialogs;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const PurchaseBody(),
    const SaleBody(),
    const MoreMenu(),
  ];

  final List<String> _titles = ['Accueil', 'Achats', 'Ventes', 'Plus'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: _getAppBarColor(),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: _buildAppBarActions(),
      ),
      body: _screens[_currentIndex],
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
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
        currentIndex: _currentIndex,
        selectedItemColor: _getSelectedColor(),
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    switch (_currentIndex) {
      case 1: // Achats
        return [
          Consumer(builder: (context, ref, child) {
            final filters = ref.watch(purchaseFiltersProvider);
            return AnimatedContainer(
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
                // ✅ CONFIRMÉ : showPurchaseFilterDialog
                onPressed: () => purchase_dialogs.showPurchaseFilterDialog(context),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.add),
            // ✅ CONFIRMÉ : showAddPurchaseDialog
            onPressed: () => purchase_dialogs.showAddPurchaseDialog(context),
          ),
        ];
      case 2: // Ventes
        return [
          Consumer(builder: (context, ref, child) {
            final filters = ref.watch(saleFiltersProvider);
            return AnimatedContainer(
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
                // ✅ CONFIRMÉ : showSaleFilterDialog
                onPressed: () => sale_dialogs.showSaleFilterDialog(context),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.add),
            // ✅ CONFIRMÉ : showAddSaleDialog
            onPressed: () => sale_dialogs.showAddSaleDialog(context),
          ),
        ];
      default:
        return [];
    }
  }

  Widget? _buildFloatingActionButton() {
    if (_currentIndex == 0) {
      return FloatingActionButton.extended(
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ajouter',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () => _showQuickAddSheet(context),
      );
    } else if (_currentIndex == 1) {
      return FloatingActionButton(
        backgroundColor: Colors.blue[700],
        // ✅ CONFIRMÉ : showAddPurchaseDialog
        onPressed: () => purchase_dialogs.showAddPurchaseDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      );
    } else if (_currentIndex == 2) {
      return FloatingActionButton(
        backgroundColor: Colors.green[700],
        // ✅ CONFIRMÉ : showAddSaleDialog
        onPressed: () => sale_dialogs.showAddSaleDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
    return null;
  }

  Color _getAppBarColor() {
    switch (_currentIndex) {
      case 0:
        return Colors.blue[700]!;
      case 1:
        return Colors.orange[700]!;
      case 2:
        return Colors.green[700]!;
      case 3:
        return Colors.purple[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  Color _getSelectedColor() {
    switch (_currentIndex) {
      case 0:
        return Colors.blue[700]!;
      case 1:
        return Colors.orange[700]!;
      case 2:
        return Colors.green[700]!;
      case 3:
        return Colors.purple[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const QuickAddSheet(),
    );
  }
}