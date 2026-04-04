import 'package:facil_count_nouveau/presentation/providers/purchase_provider.dart';
import 'package:facil_count_nouveau/presentation/providers/sale_provider.dart';
import 'package:facil_count_nouveau/presentation/providers/sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/home_content.dart';
import 'widgets/more_menu.dart';
import '../purchases/purchase_body.dart';
import '../sales/sale_body.dart';
import 'widgets/quick_add_sheet.dart';
import '../../widgets/sync/sync_indicator.dart';

// 🔥 CORRECTION DES IMPORTS : On n'utilise plus de "as alias" pour éviter les conflits
import '../sales/dialogs/filter_dialog.dart';
import '../sales/dialogs/add_sale_dialog.dart';
import '../purchases/dialogs/filter_purchase_dialog.dart';
import '../purchases/dialogs/add_purchase_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
        actions: [
          const SyncIndicator(), 
          ..._buildAppBarActions(), 
        ],
      ),
      body: _screens[_currentIndex],
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.home_outlined, 0),
            activeIcon: const Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.shopping_cart_outlined, 1),
            activeIcon: const Icon(Icons.shopping_cart),
            label: 'Achats',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.point_of_sale_outlined, 2),
            activeIcon: const Icon(Icons.point_of_sale),
            label: 'Ventes',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.apps_outlined, 3),
            activeIcon: const Icon(Icons.apps),
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

  Widget _buildNavIcon(IconData icon, int index) {
    if (index == 3) {
      return Consumer(
        builder: (context, ref, child) {
          final conflictCount = ref.watch(conflictCountProvider);
          return conflictCount.when(
            data: (count) => count > 0
                ? Badge(
                    label: Text(count.toString()),
                    backgroundColor: Colors.red,
                    child: Icon(icon),
                  )
                : Icon(icon),
            loading: () => Icon(icon),
            error: (_, __) => Icon(icon),
          );
        },
      );
    }
    return Icon(icon);
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
                // 🔥 MODIFIÉ : Appel direct sans alias
                onPressed: () => showPurchaseFilterDialog(context),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.add),
            // 🔥 MODIFIÉ : Utilisation directe de showDialog
            onPressed: () => _openAddPurchaseDialog(),
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
                // 🔥 MODIFIÉ : Appel direct sans alias
                onPressed: () => showSaleFilterDialog(context),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.add),
            // 🔥 MODIFIÉ : Utilisation directe de showDialog
            onPressed: () => _openAddSaleDialog(),
          ),
        ];
      default:
        return [
          if (_currentIndex == 0 || _currentIndex == 3)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'conflicts') {
                  Navigator.pushNamed(context, '/conflicts');
                } else if (value == 'sync') {
                  _manualSync();
                } else if (value == 'settings') {
                  Navigator.pushNamed(context, '/settings');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'sync',
                  child: Row(
                    children: [
                      Icon(Icons.sync, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Synchroniser'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'conflicts',
                  child: Consumer(
                    builder: (context, ref, child) {
                      final conflictCount = ref.watch(conflictCountProvider);
                      return Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Conflits'),
                          const Spacer(),
                          conflictCount.when(
                            data: (count) => count > 0
                                ? CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.red,
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Paramètres'),
                    ],
                  ),
                ),
              ],
            ),
        ];
    }
  }

  void _manualSync() {
    ref.read(syncStateProvider.notifier).sync();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Synchronisation...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );
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
        // 🔥 MODIFIÉ : Utilisation directe de showDialog
        onPressed: () => _openAddPurchaseDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      );
    } else if (_currentIndex == 2) {
      return FloatingActionButton(
        backgroundColor: Colors.green[700],
        // 🔥 MODIFIÉ : Utilisation directe de showDialog
        onPressed: () => _openAddSaleDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
    return null;
  }

  // 🔥 NOUVELLE MÉTHODE : Pour ouvrir la boîte des ventes
  void _openAddSaleDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddSaleDialog(),
    );
  }

  // 🔥 NOUVELLE MÉTHODE : Pour ouvrir la boîte des achats
  void _openAddPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddPurchaseDialog(), // Ajuste si le widget s'appelle autrement
    );
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