import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:facil_count_nouveau/core/constants/app_colors.dart';
import 'package:facil_count_nouveau/core/services/supabase_service.dart';
import 'package:facil_count_nouveau/core/widgets/compact_card.dart';
import 'package:facil_count_nouveau/core/utils/format.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // --- 1. Initialisation ---
  final _api = SupabaseService();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _expenses = [];
  String _selectedPeriod = 'Mois';
  String _selectedTab = 'Liste';
  String _descriptionFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  double _totalMoisActuel = 0;
  double _totalMoisPrecedent = 0;
  double _difference = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Chargement des dépenses
      final expensesRes = await _api.getExpenses();
      setState(() => _expenses = expensesRes);

      // Calcul des totaux mensuels
      await _calculateMonthlyTotals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateMonthlyTotals() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final firstDayOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayOfPreviousMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

    // Utilisation de _getTotalLocal pour éviter les erreurs d'API
    _totalMoisActuel = await _getTotalLocal(firstDayOfMonth, lastDayOfMonth);
    _totalMoisPrecedent = await _getTotalLocal(
      firstDayOfPreviousMonth,
      lastDayOfPreviousMonth,
    );
    _difference = _totalMoisActuel - _totalMoisPrecedent;
  }

  // Méthode locale pour calculer les totaux (remplace _api.getTotalExpensesByPeriod)
  Future<double> _getTotalLocal(DateTime start, DateTime end) async {
    try {
      final res = await _supabase
          .from('expenses')
          .select('amount')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      return res.fold<double>(
        0.0,
        (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0.0),
      );
    } catch (e) {
      return 0.0;
    }
  }

  // --- 2. Logique de filtrage ---
  List<Map<String, dynamic>> get _filteredExpenses {
    var list = List<Map<String, dynamic>>.from(_expenses);
    final now = DateTime.now();
    DateTime periodStart;
    DateTime periodEnd = now.add(const Duration(days: 1));

    switch (_selectedPeriod) {
      case 'Semaine':
        periodStart = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Mois':
        periodStart = DateTime(now.year, now.month, 1);
        break;
      default: // Année
        periodStart = DateTime(now.year, 1, 1);
    }

    list = list.where((e) {
      final dateStr = e['created_at'] as String?;
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      return date != null &&
          date.isAfter(periodStart.subtract(const Duration(days: 1))) &&
          date.isBefore(periodEnd);
    }).toList();

    if (_descriptionFilter.isNotEmpty) {
      final q = _descriptionFilter.toLowerCase();
      list = list
          .where(
            (e) =>
                (e['description'] as String?)?.toLowerCase().contains(q) ??
                false,
          )
          .toList();
    }

    if (_startDate != null || _endDate != null) {
      list = list.where((e) {
        final date = DateTime.tryParse(e['created_at'] ?? '');
        if (date == null) return false;
        if (_startDate != null && date.isBefore(_startDate!)) return false;
        if (_endDate != null && date.isAfter(_endDate!)) return false;
        return true;
      }).toList();
    }

    list.sort((a, b) {
      final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    return list;
  }

  // --- 3. UI Helpers ---
  String _formatCFA(num amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.abs())} F CFA';
  }

  Color _getDiffColor(double diff) {
    if (diff > 0) return Colors.red.shade700;
    if (diff < 0) return Colors.green.shade700;
    return Colors.grey.shade700;
  }

  Map<String, Map<String, num>> _getMonthlyTotalsWithDiff() {
    final map = <String, Map<String, num>>{};
    final fmt = DateFormat('MMMM yyyy', 'fr_FR');

    for (var e in _expenses) {
      final dateStr = e['created_at'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final key = fmt.format(date);
      map.putIfAbsent(key, () => {'amount': 0, 'diff': 0});
      map[key]!['amount'] =
          (map[key]!['amount']! + (e['amount'] as num? ?? 0)) as num;
    }

    final sortedKeys = map.keys.toList()
      ..sort((a, b) => fmt.parse(b).compareTo(fmt.parse(a)));

    for (int i = 0; i < sortedKeys.length - 1; i++) {
      final current = map[sortedKeys[i]]!['amount']! as num;
      final previous = map[sortedKeys[i + 1]]!['amount']! as num;
      map[sortedKeys[i]]!['diff'] = (current - previous) as num;
    }

    return Map.fromEntries(sortedKeys.map((key) => MapEntry(key, map[key]!)));
  }

  // --- 4. UI Build ---
  @override
  Widget build(BuildContext context) {
    final total = _filteredExpenses.fold<num>(
      0,
      (sum, item) => sum + (item['amount'] as num? ?? 0),
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.shade100,
              ),
              child: Icon(
                Icons.filter_list,
                color: Colors.orange.shade800,
                size: 22,
              ),
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Onglets
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTabButton('Liste', _selectedTab == 'Liste'),
                      _buildTabButton(
                        'Dashboard annuel',
                        _selectedTab == 'Dashboard annuel',
                      ),
                    ],
                  ),
                ),
                // Contenu selon l'onglet
                if (_selectedTab == 'Liste') ...[
                  _buildTotalCard(total, isSmall),
                  _buildPeriodFilterChips(),
                  Expanded(child: _buildExpensesList()),
                ] else ...[
                  Expanded(child: _buildCompactAnnualDashboard()),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        mini: isSmall,
        backgroundColor: Colors.orange.shade700,
        child: const Icon(Icons.add),
        onPressed: _showAddExpenseForm,
      ),
    );
  }

  // --- Widgets UI ---
  Widget _buildTabButton(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.shade700 : Colors.transparent,
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

  Widget _buildTotalCard(num total, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total dépenses',
                style: TextStyle(fontSize: isSmall ? 15 : 17),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatCFA(total),
                  style: TextStyle(
                    fontSize: isSmall ? 17 : 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Semaine', 'Mois', 'Année'].map((p) {
            final sel = p == _selectedPeriod;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(p, style: const TextStyle(fontSize: 13)),
                selected: sel,
                onSelected: (v) => setState(() => _selectedPeriod = p),
                selectedColor: Colors.orange.shade700,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : Colors.black87,
                ),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    final displayedList = _filteredExpenses;
    if (displayedList.isEmpty) {
      return const Center(child: Text('Aucune dépense trouvée'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: displayedList.length,
      itemBuilder: (context, index) {
        final e = displayedList[index];
        final desc = e['description'] as String? ?? 'Sans description';
        final amount = e['amount'] as num? ?? 0.0;
        final locked = e['locked'] == true;
        return _buildExpenseCard(e, desc, amount, locked);
      },
    );
  }

  Widget _buildExpenseCard(
    Map<String, dynamic> e,
    String desc,
    num amount,
    bool locked,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.orange.shade100,
              child: Text(
                '1',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildExpenseInfo(e, desc)),
            SizedBox(
              width: 140,
              child: _buildExpenseActions(e, amount, locked),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseInfo(Map<String, dynamic> e, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          desc,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          e['created_at']?.substring(0, 10) ?? '',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildExpenseActions(Map<String, dynamic> e, num amount, bool locked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatCFA(amount),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 18,
              color: locked ? Colors.yellow.shade800 : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.edit, size: 20),
              color: Colors.blue.shade700,
              onPressed: () => _showEditExpenseDialog(e),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete, size: 20),
              color: Colors.red.shade700,
              onPressed: () => _deleteExpense(e),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactAnnualDashboard() {
    final monthlyTotals = _getMonthlyTotalsWithDiff();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Dépenses du mois',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatCFA(_totalMoisActuel),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _difference >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: _getDiffColor(_difference),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatCFA(_difference.abs())} vs mois préc.',
                        style: TextStyle(
                          fontSize: 15,
                          color: _getDiffColor(_difference),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          ...monthlyTotals.entries.map((entry) {
            final month = entry.key;
            final amount = entry.value['amount'] as num;
            final diff = entry.value['diff'] as num;
            final isIncrease = diff >= 0;
            final diffColor = _getDiffColor(diff.toDouble());

            return AnnualDashboardCard(
              month: month.toUpperCase(),
              amount: amount.toDouble(),
              previousAmount: (amount - diff).toDouble(),
              isIncrease: isIncrease,
              amountColor: diffColor,
              backgroundColor: const Color(0xFFE3F2FD),
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- Dialogues ---
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterBottomSheetContent(context),
    );
  }

  Widget _buildFilterBottomSheetContent(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrer les dépenses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Description (contient)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() => _descriptionFilter = val.trim());
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePickerButton(
                      context: context,
                      label: _startDate == null
                          ? 'Date début'
                          : DateFormat('dd/MM/yyyy').format(_startDate!),
                      onDateSelected: (picked) {
                        setState(() => _startDate = picked);
                        setModalState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDatePickerButton(
                      context: context,
                      label: _endDate == null
                          ? 'Date fin'
                          : DateFormat('dd/MM/yyyy').format(_endDate!),
                      onDateSelected: (picked) {
                        setState(() => _endDate = picked);
                        setModalState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    onPressed: () {
                      setState(() {
                        _descriptionFilter = '';
                        _startDate = null;
                        _endDate = null;
                      });
                      setModalState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Réinitialiser'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatePickerButton({
    required BuildContext context,
    required String label,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Text(label),
    );
  }

  // --- Méthodes pour les dialogues d'ajout/modification/suppression ---
  Future<void> _showAddExpenseForm() async {
    final descriptionCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    DateTime expenseDate = DateTime.now();
    bool paid = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter une dépense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Montant *',
                        border: OutlineInputBorder(),
                        hintText: 'Exemple : 375000 ou 375.50',
                        helperText: 'Utilisez le point (.) pour les décimales',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (value) {
                        final cleaned = value.replaceAll(',', '.');
                        if (cleaned != value) {
                          amountCtrl.value = amountCtrl.value.copyWith(
                            text: cleaned,
                            selection: TextSelection.collapsed(
                              offset: cleaned.length,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerButton(
                      context: context,
                      label: DateFormat('dd/MM/yyyy').format(expenseDate),
                      onDateSelected: (picked) =>
                          setDialogState(() => expenseDate = picked),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Payé (cash)'),
                      value: paid,
                      onChanged: (val) => setDialogState(() => paid = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => _handleAddExpenseSubmit(
                    dialogContext: dialogContext,
                    descriptionCtrl: descriptionCtrl,
                    amountCtrl: amountCtrl,
                    categoryCtrl: categoryCtrl,
                    expenseDate: expenseDate,
                    paid: paid,
                  ),
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditExpenseDialog(Map<String, dynamic> expense) async {
    final descriptionCtrl = TextEditingController(
      text: expense['description'] ?? '',
    );
    final amountCtrl = TextEditingController(
      text: expense['amount'].toString(),
    );
    final categoryCtrl = TextEditingController(text: expense['category'] ?? '');
    DateTime expenseDate =
        DateTime.tryParse(expense['created_at'] ?? '') ?? DateTime.now();
    bool paid = expense['paid'] ?? true;
    bool locked = expense['locked'] ?? false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier dépense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Montant *',
                        border: OutlineInputBorder(),
                        hintText: 'Exemple : 375000 ou 375.50',
                        helperText: 'Utilisez le point (.) pour les décimales',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (value) {
                        final cleaned = value.replaceAll(',', '.');
                        if (cleaned != value) {
                          amountCtrl.value = amountCtrl.value.copyWith(
                            text: cleaned,
                            selection: TextSelection.collapsed(
                              offset: cleaned.length,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerButton(
                      context: context,
                      label: DateFormat('dd/MM/yyyy').format(expenseDate),
                      onDateSelected: (picked) =>
                          setDialogState(() => expenseDate = picked),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Payé (cash)'),
                      value: paid,
                      onChanged: (val) => setDialogState(() => paid = val),
                    ),
                    SwitchListTile(
                      title: const Text('Verrouillé'),
                      value: locked,
                      onChanged: (val) => setDialogState(() => locked = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => _handleEditExpenseSubmit(
                    dialogContext: dialogContext,
                    expense: expense,
                    descriptionCtrl: descriptionCtrl,
                    amountCtrl: amountCtrl,
                    categoryCtrl: categoryCtrl,
                    expenseDate: expenseDate,
                    paid: paid,
                    locked: locked,
                  ),
                  child: const Text('Modifier'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer dépense ?'),
        content: Text(
          'Voulez-vous supprimer cette dépense du ${expense['created_at']?.substring(0, 10) ?? 'date inconnue'} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('expenses').delete().eq('id', expense['id']);
      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dépense supprimée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression : ${e.toString()}')),
        );
      }
    }
  }

  // --- Logique de soumission ---
  Future<void> _handleAddExpenseSubmit({
    required BuildContext dialogContext,
    required TextEditingController descriptionCtrl,
    required TextEditingController amountCtrl,
    required TextEditingController categoryCtrl,
    required DateTime expenseDate,
    required bool paid,
  }) async {
    if (descriptionCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description et montant obligatoires')),
        );
      }
      return;
    }

    try {
      final montantText = amountCtrl.text
          .trim()
          .replaceAll(',', '.')
          .replaceAll(' ', '');
      final amount = double.tryParse(montantText) ?? 0.0;

      if (amount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Montant invalide (ex. 375000 ou 375.50)'),
            ),
          );
        }
        return;
      }

      await _supabase.from('expenses').insert({
        'description': descriptionCtrl.text.trim(),
        'amount': amount,
        'category': categoryCtrl.text.trim().isEmpty
            ? null
            : categoryCtrl.text.trim(),
        'created_at': expenseDate.toIso8601String(),
        'paid': paid,
        'locked': false,
      });

      if (mounted) {
        await _loadData();
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dépense ajoutée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur ajout : ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleEditExpenseSubmit({
    required BuildContext dialogContext,
    required Map<String, dynamic> expense,
    required TextEditingController descriptionCtrl,
    required TextEditingController amountCtrl,
    required TextEditingController categoryCtrl,
    required DateTime expenseDate,
    required bool paid,
    required bool locked,
  }) async {
    if (descriptionCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description et montant obligatoires')),
        );
      }
      return;
    }

    try {
      final montantText = amountCtrl.text
          .trim()
          .replaceAll(',', '.')
          .replaceAll(' ', '');
      final amount = double.tryParse(montantText) ?? 0.0;

      if (amount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Montant invalide (ex. 375000 ou 375.50)'),
            ),
          );
        }
        return;
      }

      await _supabase
          .from('expenses')
          .update({
            'description': descriptionCtrl.text.trim(),
            'amount': amount,
            'category': categoryCtrl.text.trim().isEmpty
                ? null
                : categoryCtrl.text.trim(),
            'created_at': expenseDate.toIso8601String(),
            'paid': paid,
            'locked': locked,
          })
          .eq('id', expense['id']);

      if (mounted) {
        await _loadData();
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dépense modifiée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur modification : ${e.toString()}')),
        );
      }
    }
  }
}
