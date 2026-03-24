import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sale_provider.dart';
import 'widgets/sale_list.dart';
import 'widgets/sale_dashboard.dart';
import 'dialogs/add_sale_dialog.dart';
import 'package:facil_count_nouveau/presentation/screens/sales/dialogs/filter_dialog.dart';

class SaleScreen extends ConsumerWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesProvider);
    final selectedTab = ref.watch(saleTabProvider);
    final filters = ref.watch(saleFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventes'),
        backgroundColor: Colors.green.shade700,
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
              onPressed: () => showSaleFilterDialog(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddSaleDialog(context),
          ),
        ],
      ),
      body: salesAsync.when(
        data: (sales) => Column(
          children: [
            _buildTabBar(context, ref),
            Expanded(
              child: selectedTab == 0
                  ? SaleList(sales: sales)
                  : SaleDashboard(sales: sales), // ← Passer les sales ici
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        onPressed: () => showAddSaleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(saleTabProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TabButton(
            label: 'Liste',
            selected: selectedTab == 0,
            onTap: () => ref.read(saleTabProvider.notifier).state = 0,
            color: Colors.green.shade700,
          ),
          _TabButton(
            label: 'Dashboard',
            selected: selectedTab == 1,
            onTap: () => ref.read(saleTabProvider.notifier).state = 1,
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
