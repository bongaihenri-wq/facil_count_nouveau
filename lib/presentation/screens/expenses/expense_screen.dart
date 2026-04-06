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

// 🎯 Le provider d'état pour la période
final selectedPeriodProvider = StateProvider<DateFilterRange>((ref) {
  return DateFilterHelper.defaultRange();
});

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(expenseTabProvider);
    final currentPeriod = ref.watch(selectedPeriodProvider);
    final expensesAsync = ref.watch(filteredExpensesProvider(currentPeriod));

    return Scaffold(
      // 🏷️ 1. APP BAR
      appBar: AppBar(
        title: const Text('Dépenses'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddExpenseDialog(context),
          ),
        ],
      ),
      body: Column(
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

          // 🗂️ 3. SÉLECTION LISTE / DASHBOARD (Juste après le filtre)
          Container(
            color: Colors.red.shade50,
            child: Row(
              children: [
                _buildTab(context, ref, 'Liste', 0),
                _buildTab(context, ref, 'Dashboard', 1),
              ],
            ),
          ),

          // 💰 4. TOTAL DÉPENSES NOUVEAU (Juste au-dessus de la liste)
          expensesAsync.when(
            data: (expenses) {
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
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 📝 5. CONTENU (Liste ou Dashboard)
          Expanded(
            child: expensesAsync.when(
              data: (expenses) => tabIndex == 0
                  ? ExpenseList(expenses: expenses)
                  : ExpenseDashboard(expenses: expenses),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur: $err')),
            ),
          ),
        ],
      ),
    );
  }

  // Les méthodes _showPeriodPicker et _buildTab restent identiques
  void _showPeriodPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PeriodPickerBottomSheet(
        onPeriodSelected: (newRange) {
          ref.read(selectedPeriodProvider.notifier).state = newRange;
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
