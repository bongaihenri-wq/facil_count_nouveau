import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/utils/business_helper.dart';
import '../../core/utils/date_filter_helper.dart'; // 🟢 Pour le type DateFilter
import '/presentation/screens/dashboard/providers/dashboard_provider.dart';
import '../screens/expenses/expense_screen.dart'; 

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final client = Supabase.instance.client;
  final businessHelper = ref.watch(businessHelperProvider);
  return ExpenseRepository(client, businessHelper);
});

// Filtres textuels (Mise en mémoire)
final expenseFiltersProvider = StateProvider<ExpenseFilters>(
  (ref) => const ExpenseFilters(),
);

// 🟢 Provider des dépenses (Devenu indépendant avec .family !)
// Il prend un objet DateFilter en paramètre.
final filteredExpensesProvider = FutureProvider.family<List<ExpenseModel>, DateFilterRange>((ref, period) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final filters = ref.watch(expenseFiltersProvider);
  
  print('🛰️ Provider Dépenses - Récupération autonome via .family');
  print('📅 Dates envoyées à Supabase : ${period.start} au ${period.end}');

  // On injecte les dates issues directement du paramètre 'period' !
  return repo.getExpenses(
    startDate: period.start, 
    endDate: period.end,    
    searchQuery: filters.searchQuery,
  );
});

final expenseStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getMonthlyStats();
});

// Actions
class ExpenseNotifier extends StateNotifier<AsyncValue<void>> {
  final ExpenseRepository _repo;

  ExpenseNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> addExpense({
    required String name,
    required double amount,
    String? recipient,
    required DateTime expensesDate,
    bool locked = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addExpense(
        name: name,
        amount: amount,
        recipient: recipient,
        expensesDate: expensesDate,
        locked: locked,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateExpense(
    String id, {
    required String name,
    required double amount,
    String? recipient,
    required DateTime expensesDate,
    required bool locked,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateExpense(
        id,
        name: name,
        amount: amount,
        recipient: recipient,
        expensesDate: expensesDate,
        locked: locked,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _repo.deleteExpense(id);
    } catch (e) {
      rethrow;
    }
  }
}

final expenseNotifierProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<void>>((ref) {
      return ExpenseNotifier(ref.watch(expenseRepositoryProvider));
    });

// Filtres classe
class ExpenseFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  const ExpenseFilters({this.startDate, this.endDate, this.searchQuery});

  ExpenseFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) => ExpenseFilters(
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

// Tab state simple
final expenseTabProvider = StateProvider<int>((ref) => 0);
