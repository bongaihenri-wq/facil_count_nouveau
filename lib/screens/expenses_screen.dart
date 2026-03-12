import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart'; // ← IMPORT AJOUTÉ ICI

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  String _selectedPeriod = 'Mois';
  String _selectedTab = 'Liste';

  String descriptionFilter = '';
  DateTime? startDate;
  DateTime? endDate;

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
      final expensesRes = await supabase
          .from('expenses')
          .select()
          .order('created_at', ascending: false);

      final now = DateTime.now();
      final moisActuelStart = DateTime(now.year, now.month, 1);
      final moisActuelEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final moisPrecedentStart = DateTime(now.year, now.month - 1, 1);
      final moisPrecedentEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      _totalMoisActuel = await _getTotal('expenses', 'created_at', moisActuelStart, moisActuelEnd);
      _totalMoisPrecedent = await _getTotal('expenses', 'created_at', moisPrecedentStart, moisPrecedentEnd);
      _difference = _totalMoisActuel - _totalMoisPrecedent;

      if (mounted) {
        setState(() {
          _expenses = List<Map<String, dynamic>>.from(expensesRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement dépenses: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement : $e')),
        );
      }
    }
  }

  Future<double> _getTotal(String table, String dateColumn, DateTime start, DateTime end) async {
    try {
      final res = await supabase
          .from(table)
          .select('amount')
          .gte(dateColumn, start.toIso8601String())
          .lte(dateColumn, end.toIso8601String());

      return res.fold<double>(0.0, (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0.0));
    } catch (e) {
      print('Erreur _getTotal: $e');
      return 0.0;
    }
  }

  String formatCFA(num amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    final formatted = formatter.format(amount.abs());
    return '$formatted F CFA';
  }

  Color _getDiffColor(double diff) {
    if (diff > 0) return Colors.red.shade700;
    if (diff < 0) return Colors.green.shade700;
    return Colors.grey.shade700;
  }

  List<Map<String, dynamic>> get filteredExpenses {
    var list = List<Map<String, dynamic>>.from(_expenses);

    final now = DateTime.now();
    DateTime periodStart;
    DateTime periodEnd = now.add(const Duration(days: 1));

    if (_selectedPeriod == 'Semaine') {
      periodStart = now.subtract(Duration(days: now.weekday - 1));
    } else if (_selectedPeriod == 'Mois') {
      periodStart = DateTime(now.year, now.month, 1);
    } else {
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

    if (descriptionFilter.isNotEmpty) {
      final q = descriptionFilter.toLowerCase();
      list = list.where((e) => (e['description'] as String?)?.toLowerCase().contains(q) ?? false).toList();
    }

    if (startDate != null || endDate != null) {
      list = list.where((e) {
        final date = DateTime.tryParse(e['created_at'] ?? '');
        if (date == null) return false;
        if (startDate != null && date.isBefore(startDate!)) return false;
        if (endDate != null && date.isAfter(endDate!)) return false;
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

  num getTotalExpenses() => filteredExpenses.fold<num>(0, (sum, item) => sum + (item['amount'] as num? ?? 0));

  @override
  Widget build(BuildContext context) {
    final total = getTotalExpenses();
    final displayedList = filteredExpenses;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.shade100),
              child: Icon(Icons.filter_list, color: Colors.orange.shade800, size: 22),
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTabButton('Liste', _selectedTab == 'Liste'),
                      _buildTabButton('Dashboard annuel', _selectedTab == 'Dashboard annuel'),
                    ],
                  ),
                ),

                if (_selectedTab == 'Liste')
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total dépenses', style: TextStyle(fontSize: isSmall ? 15 : 17)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatCFA(total),
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
                  ),

                if (_selectedTab == 'Liste')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Semaine', 'Mois', 'Année'].map((p) {
                          final sel = p == _selectedPeriod;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(p, style: TextStyle(fontSize: 13)),
                              selected: sel,
                              onSelected: (v) {
                                if (v) setState(() => _selectedPeriod = p);
                              },
                              selectedColor: Colors.orange.shade700,
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                Expanded(
                  child: _selectedTab == 'Liste'
                      ? _buildExpensesList(displayedList)
                      : _buildCompactAnnualDashboard(),
                ),
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

  Widget _buildExpensesList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Aucune dépense trouvée'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final e = data[index];
        final desc = e['description'] as String? ?? 'Sans description';
        final amount = e['amount'] as num? ?? 0.0;
        final locked = e['locked'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rond orange avec quantité (1 par défaut pour dépenses)
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.orange.shade100,
                  child: Text(
                    '1', // Pas de quantité réelle → 1 fixe ou tu peux ajouter un champ quantité si besoin
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Description + date (petit, effilé)
                Expanded(
                  child: Column(
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
                  ),
                ),

                // Montant + boutons (alignés à droite)
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCFA(amount),
                        style:  TextStyle(
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      formatCFA(_totalMoisActuel),
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
                        _difference >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: _getDiffColor(_difference),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${formatCFA(_difference.abs())} vs mois préc.',
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
            final diffColor = _getDiffColor(diff.toDouble());

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                dense: true,
                title: Text(month, style: TextStyle(fontSize: 15)),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCFA(amount),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      diff > 0
                          ? '+${formatCFA(diff)} vs préc.'
                          : diff < 0
                              ? '${formatCFA(diff)} vs préc.'
                              : '0 vs préc.',
                      style: TextStyle(
                        fontSize: 12,
                        color: diffColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Map<String, Map<String, num>> _getMonthlyTotalsWithDiff() {
    final map = <String, Map<String, num>>{};
    final fmt = DateFormat('MMMM yyyy');

    for (var e in _expenses) {
      final dateStr = e['created_at'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final key = fmt.format(date);
      map.putIfAbsent(key, () => {'amount': 0, 'diff': 0});
      map[key]!['amount'] = (map[key]!['amount']! + (e['amount'] as num? ?? 0));
    }

    final sortedKeys = map.keys.toList()
      ..sort((a, b) => DateFormat('MMMM yyyy').parse(b).compareTo(DateFormat('MMMM yyyy').parse(a)));

    for (int i = 0; i < sortedKeys.length - 1; i++) {
      final current = map[sortedKeys[i]]!['amount']!;
      final previous = map[sortedKeys[i + 1]]!['amount']!;
      map[sortedKeys[i]]!['diff'] = current - previous;
    }

    return Map.fromEntries(sortedKeys.map((key) => MapEntry(key, map[key]!)));
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
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
                  const Text('Filtrer les dépenses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Description (contient)', border: OutlineInputBorder()),
                    onChanged: (val) {
                      setState(() => descriptionFilter = val.trim());
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null && mounted) {
                              setState(() => startDate = picked);
                              setModalState(() {});
                            }
                          },
                          child: Text(startDate == null ? 'Date début' : DateFormat('dd/MM/yyyy').format(startDate!)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null && mounted) {
                              setState(() => endDate = picked);
                              setModalState(() {});
                            }
                          },
                          child: Text(endDate == null ? 'Date fin' : DateFormat('dd/MM/yyyy').format(endDate!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                        onPressed: () {
                          setState(() {
                            descriptionFilter = '';
                            startDate = null;
                            endDate = null;
                          });
                          setModalState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('Réinitialiser'),
                      ),
                      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddExpenseForm() {
    final descriptionCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    DateTime expenseDate = DateTime.now();
    bool paid = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ajouter une dépense'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      onChanged: (value) {
                        final cleaned = value.replaceAll(',', '.');
                        if (cleaned != value) {
                          amountCtrl.value = amountCtrl.value.copyWith(
                            text: cleaned,
                            selection: TextSelection.collapsed(offset: cleaned.length),
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
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expenseDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => expenseDate = picked);
                        }
                      },
                      child: Text(DateFormat('dd/MM/yyyy').format(expenseDate)),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Payé (cash)'),
                      value: paid,
                      onChanged: (val) => setDialogState(() => paid = val),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                if (descriptionCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Description et montant obligatoires')),
                    );
                  }
                  return;
                }

                try {
                  final montantText = amountCtrl.text.trim().replaceAll(',', '.').replaceAll(' ', '');
                  final amount = double.tryParse(montantText) ?? 0.0;

                  if (amount <= 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Montant invalide (ex. 375000 ou 375.50)')),
                      );
                    }
                    return;
                  }

                  await supabase.from('expenses').insert({
                    'description': descriptionCtrl.text.trim(),
                    'amount': amount,
                    'category': categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim(),
                    'created_at': expenseDate.toIso8601String(),
                    'paid': paid,
                    'locked': false,
                  });

                  if (mounted) {
                    await _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dépense ajoutée avec succès')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur ajout dépense : $e')),
                    );
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showEditExpenseDialog(Map<String, dynamic> expense) {
    final descriptionCtrl = TextEditingController(text: expense['description'] ?? '');
    final amountCtrl = TextEditingController(text: expense['amount'].toString());
    final categoryCtrl = TextEditingController(text: expense['category'] ?? '');
    DateTime expenseDate = DateTime.tryParse(expense['created_at'] ?? '') ?? DateTime.now();
    bool paid = expense['paid'] ?? true;
    bool locked = expense['locked'] ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Modifier dépense'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      onChanged: (value) {
                        final cleaned = value.replaceAll(',', '.');
                        if (cleaned != value) {
                          amountCtrl.value = amountCtrl.value.copyWith(
                            text: cleaned,
                            selection: TextSelection.collapsed(offset: cleaned.length),
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
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expenseDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => expenseDate = picked);
                        }
                      },
                      child: Text(DateFormat('dd/MM/yyyy').format(expenseDate)),
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
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                if (descriptionCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Description et montant obligatoires')),
                    );
                  }
                  return;
                }

                try {
                  final montantText = amountCtrl.text.trim().replaceAll(',', '.').replaceAll(' ', '');
                  final amount = double.tryParse(montantText) ?? 0.0;

                  if (amount <= 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Montant invalide (ex. 375000 ou 375.50)')),
                      );
                    }
                    return;
                  }

                  await supabase.from('expenses').update({
                    'description': descriptionCtrl.text.trim(),
                    'amount': amount,
                    'category': categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim(),
                    'created_at': expenseDate.toIso8601String(),
                    'paid': paid,
                    'locked': locked,
                  }).eq('id', expense['id']);

                  if (mounted) {
                    await _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dépense modifiée avec succès')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur modification : $e')),
                    );
                  }
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer dépense ?'),
        content: Text('Voulez-vous supprimer cette dépense du ${expense['created_at']?.substring(0, 10) ?? 'date inconnue'} ?'),
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
      await supabase.from('expenses').delete().eq('id', expense['id']);
      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dépense supprimée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression : $e')));
      }
    }
  }
}