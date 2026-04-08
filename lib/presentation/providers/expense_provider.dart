import 'package:facil_count_nouveau/presentation/screens/home/widgets/dashboard_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/expense_model.dart';
import '../../core/utils/date_filter_helper.dart'; 
import '../../data/repositories/expense_repository.dart';
import '../../core/utils/business_helper.dart';

// --- INFRASTRUCTURE ---

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final businessHelper = ref.watch(businessHelperProvider);
  return ExpenseRepository(client, businessHelper);
});

// --- SECTION FILTRES & PÉRIODE (POUR L'ÉCRAN DÉPENSES) ---

/// Période pilotée par le sélecteur de l'écran "Liste des Dépenses"
final selectedExpensePeriodProvider = StateProvider<DateFilterRange>((ref) {
  final now = DateTime.now();
  return DateFilterRange(
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month + 1, 0), 
    label: 'Ce mois',
  );
});

final expenseFiltersProvider = StateProvider<ExpenseFilters>(
  (ref) => const ExpenseFilters(),
);

// --- SECTION DATA (LE MOTEUR) ---

/// 🟢 LE MOTEUR : Communique avec Supabase. 
/// Utilisé par TOUS les écrans (Dashboard, Liste, etc.) via .family
final expensesProvider = FutureProvider.family<List<ExpenseModel>, DateFilterRange>((ref, period) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getExpenses(
    startDate: period.start, 
    endDate: period.end,
  );
});

// --- SECTION USAGES SPÉCIFIQUES ---

/// 1️⃣ POUR L'ÉCRAN LISTE (Filtrage mémoire + Période écran)
final filteredExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final period = ref.watch(selectedExpensePeriodProvider);
  final allExpenses = ref.watch(expensesProvider(period)).valueOrNull ?? [];
  
  final filters = ref.watch(expenseFiltersProvider);
  if (filters.searchQuery == null || filters.searchQuery!.isEmpty) {
    return allExpenses;
  }

  final query = filters.searchQuery!.toLowerCase();
  return allExpenses.where((e) {
    return e.name.toLowerCase().contains(query) || 
           (e.recipient?.toLowerCase().contains(query) ?? false);
  }).toList();
});

/// 2️⃣ POUR LA DASHBOARD CARD (HOME)
/// Ce provider est indépendant pour ne pas casser le Dashboard Screen
final homeExpenseStatsProvider = Provider<List<ExpenseModel>>((ref) {
  // On regarde le mois sélectionné sur le Home (le petit sélecteur)
  // Remplacez 'selectedMonthProvider' par le nom exact de votre sélecteur de mois Home
  final selectedDate = ref.watch(selectedMonthProvider); 
  
  final range = DateFilterRange(
    start: DateTime(selectedDate.year, selectedDate.month, 1),
    end: DateTime(selectedDate.year, selectedDate.month + 1, 0),
    label: 'Stats Home',
  );

  return ref.watch(expensesProvider(range)).valueOrNull ?? [];
});

// --- STATS ET SUGGESTIONS ---

final expenseStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getMonthlyStats();
});

final expenseSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final repo = ref.watch(expenseRepositoryProvider);
    final names = await repo.getAllExpenseNames();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  } catch (e) {
    return [];
  }
});

// --- ACTIONS (NOTIFIER) ---

class ExpenseNotifier extends StateNotifier<AsyncValue<void>> {
  final ExpenseRepository _repo;
  final Ref ref;

  ExpenseNotifier(this._repo, {required this.ref}) : super(const AsyncValue.data(null));

  Future<void> _refresh() async {
    ref.invalidate(expensesProvider);
    ref.invalidate(expenseSuggestionsProvider);
    ref.invalidate(expenseStatsProvider);
  }

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
        name: name, amount: amount, recipient: recipient, 
        expensesDate: expensesDate, locked: locked,
      );
      _refresh();
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> updateExpense(String id, {
    required String name, required double amount, String? recipient,
    required DateTime expensesDate, required bool locked,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateExpense(
        id, name: name, amount: amount, recipient: recipient,
        expensesDate: expensesDate, locked: locked,
      );
      _refresh();
      state = const AsyncValue.data(null);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _repo.deleteExpense(id);
      _refresh();
    } catch (e) { rethrow; }
  }
}

final expenseNotifierProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<void>>((ref) {
  return ExpenseNotifier(ref.watch(expenseRepositoryProvider), ref: ref);
});

// --- CLASSES SUPPORTS ---

class ExpenseFilters {
  final String? searchQuery;
  const ExpenseFilters({this.searchQuery, DateTime? startDate, DateTime? endDate});

  ExpenseFilters copyWith({String? searchQuery}) => 
      ExpenseFilters(searchQuery: searchQuery ?? this.searchQuery);
}
final expenseTabProvider = StateProvider<int>((ref) => 0);
