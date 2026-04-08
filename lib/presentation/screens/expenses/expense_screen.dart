import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_filter_helper.dart';
import '../../../core/utils/period_picker_bottom_sheet.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/expense_model.dart';
import '../../providers/expense_provider.dart';
import 'dialogs/add_expense_dialog.dart';
import 'dialogs/filter_dialog.dart';
import 'widgets/expense_dashboard.dart';
import 'widgets/expense_list.dart';

// 🎯 Le provider d'état pour la période (utilisé localement par cet écran)
final selectedPeriodProvider = StateProvider<DateFilterRange>((ref) {
  return DateFilterHelper.defaultRange();
});

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

 @override
Widget build(BuildContext context, WidgetRef ref) {
  // 🟢 Lecture des états
  final tabIndex = ref.watch(expenseTabProvider);
  final currentPeriod = ref.watch(selectedPeriodProvider);
  final filters = ref.watch(expenseFiltersProvider);
  
  // 🧐 Détection d'un filtre actif (Recherche textuelle)
  final bool hasActiveFilters = filters.searchQuery != null && filters.searchQuery!.isNotEmpty;
  
  // 🟢 Récupération de la liste filtrée
  final expenses = ref.watch(filteredExpensesProvider);

  return Scaffold(
    appBar: AppBar(
      title: const Text('Dépenses'),
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
      actions: [
        // --- 🔍 BOUTON FILTRE DYNAMIQUE ---
        IconButton(
          onPressed: () => _showFilterDialog(context, ref),
          icon: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.filter_list,
                // L'icône devient jaune si un filtre est actif, sinon reste blanche
                color: hasActiveFilters ? Colors.yellowAccent : Colors.white,
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.shade700, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // --- ➕ BOUTON AJOUT ---
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => showAddExpenseDialog(context),
        ),
      ],
    ),
    body: Column(
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
                Icon(Icons.calendar_month, size: 18, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  currentPeriod.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 20, color: Colors.red.shade700),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // 🗂️ ONGLETS LISTE / DASHBOARD
        Container(
          color: Colors.red.shade50,
          child: Row(
            children: [
              _buildTab(context, ref, 'Liste', 0),
              _buildTab(context, ref, 'Dashboard', 1),
            ],
          ),
        ),

        // 💰 BANDEAU TOTAL (Utilise le Formatter avec séparateur de milliers)
        _buildTotalBanner(expenses),

        // 📝 CONTENU DYNAMIQUE
        Expanded(
          child: expenses.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      hasActiveFilters 
                        ? "Aucun résultat pour cette recherche" 
                        : "Aucune dépense sur cette période",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            : (tabIndex == 0
                ? ExpenseList(expenses: expenses)
                : ExpenseDashboard(expenses: expenses)),
        ),
      ],
    ),
  );
}

  // Widget helper pour le bandeau du total
  Widget _buildTotalBanner(List<ExpenseModel> expenses) {
    final double totalAmount = expenses.fold(0, (sum, item) => sum + item.amount);
    
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
            'Total dépenses',
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
              color: Colors.red.shade700,
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
          // Met à jour la période de l'écran
          ref.read(selectedPeriodProvider.notifier).state = newRange;
          // Synchronise aussi le provider global pour que Supabase recharge les datas
          ref.read(selectedExpensePeriodProvider.notifier).state = newRange;
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showExpenseFilterDialog(context);
  }

  Widget _buildTab(BuildContext context, WidgetRef ref, String label, int index) {
    final currentTab = ref.watch(expenseTabProvider);
    final isSelected = currentTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(expenseTabProvider.notifier).state = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.red.shade700 : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.red.shade700 : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
