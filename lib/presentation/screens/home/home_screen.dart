import 'package:flutter/material.dart';
import 'widgets/home_content.dart';
import 'widgets/more_menu.dart';
import '../purchases/purchase_screen.dart';
import '../sales/sale_screen.dart';
import 'widgets/quick_add_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(), // ← Doit être modifié pour retirer les stats
    const PurchaseScreen(),
    const SaleScreen(),
    const MoreMenu(),
  ];

  final List<String> _titles = ['Accueil', 'Achats', 'Ventes', 'Plus'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]), // ← Titre dynamique selon l'onglet
        backgroundColor: _getAppBarColor(),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              // ← Extended pour plus d'espace
              backgroundColor: Colors.green[700],
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Ajouter',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => _showQuickAddSheet(context),
            )
          : null,
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
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Color _getAppBarColor() {
    switch (_currentIndex) {
      case 0:
        return Colors.blue[700]!;
      case 1:
        return Colors.orange[700]!; // ← Orange pour Achats (différenciation)
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
      isScrollControlled: true, // ← Permet le scroll si contenu long
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const QuickAddSheet(),
    );
  }
}
