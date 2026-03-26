import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart'; // ← Ajouté pour futures saisies numériques

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _cashTransactions =
      []; // Versements banque, retraits, remis gérant
  bool _isLoading = true;

  String _selectedPeriod = 'Jour';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      DateTime start, end;
      switch (_selectedPeriod) {
        case 'Jour':
          start = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          );
          end = start.add(const Duration(days: 1));
          break;
        case 'Semaine':
          start = _selectedDate.subtract(
            Duration(days: _selectedDate.weekday - 1),
          );
          end = start.add(const Duration(days: 7));
          break;
        case 'Mois':
          start = DateTime(_selectedDate.year, _selectedDate.month, 1);
          end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
          break;
        case 'Année':
          start = DateTime(_selectedDate.year, 1, 1);
          end = DateTime(_selectedDate.year, 12, 31);
          break;
        default:
          start = DateTime.now();
          end = start.add(const Duration(days: 1));
      }

      // Chargement achats
      _purchases = await supabase
          .from('purchases')
          .select()
          .gte('purchase_date', start.toIso8601String())
          .lt('purchase_date', end.toIso8601String());

      // Chargement ventes
      _sales = await supabase
          .from('sales')
          .select()
          .gte('sale_date', start.toIso8601String())
          .lt('sale_date', end.toIso8601String());

      // Chargement dépenses
      _expenses = await supabase
          .from('expenses')
          .select()
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String());

      // Chargement transactions caisse (suppose table cash_transactions)
      _cashTransactions = await supabase
          .from('cash_transactions')
          .select()
          .gte('transaction_date', start.toIso8601String())
          .lt('transaction_date', end.toIso8601String());

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur chargement caisse : $e')));
    }
  }

  // Calculs sécurisés
  double getCashPurchases() => _purchases.fold(
    0.0,
    (sum, p) =>
        sum + (p['paid'] == true ? (p['amount'] as num).toDouble() : 0.0),
  );

  double getCreditPurchases() => _purchases.fold(
    0.0,
    (sum, p) =>
        sum + (p['paid'] == true ? 0.0 : (p['amount'] as num).toDouble()),
  );

  double getCashSales() => _sales.fold(
    0.0,
    (sum, s) =>
        sum + (s['paid'] == true ? (s['amount'] as num).toDouble() : 0.0),
  );

  double getCreditSales() => _sales.fold(
    0.0,
    (sum, s) =>
        sum + (s['paid'] == true ? 0.0 : (s['amount'] as num).toDouble()),
  );

  double getExpenses() => _expenses.fold(
    0.0,
    (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0),
  );

  double getBankDeposits() => _cashTransactions.fold(
    0.0,
    (sum, t) =>
        sum +
        (t['type'] == 'bank_deposit' ? (t['amount'] as num).toDouble() : 0.0),
  );

  double getWithdrawals() => _cashTransactions.fold(
    0.0,
    (sum, t) =>
        sum +
        (t['type'] == 'withdrawal' ? (t['amount'] as num).toDouble() : 0.0),
  );

  double getOwnerTransfers() => _cashTransactions.fold(
    0.0,
    (sum, t) =>
        sum +
        (t['type'] == 'owner_transfer' ? (t['amount'] as num).toDouble() : 0.0),
  );

  double getNetCashFlow() =>
      getCashSales() -
      (getCashPurchases() +
          getExpenses() +
          getBankDeposits() +
          getOwnerTransfers() +
          getWithdrawals());

  @override
  Widget build(BuildContext context) {
    final netFlow = getNetCashFlow();

    return Scaffold(
      appBar: AppBar(title: const Text('Caisse')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélecteur période + date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        items: ['Jour', 'Semaine', 'Mois', 'Année'].map((p) {
                          return DropdownMenuItem<String>(
                            value: p,
                            child: Text(p),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedPeriod = val!);
                          _loadData();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _loadData();
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Solde net caisse (carte principale)
                  Card(
                    elevation: 4,
                    color: netFlow >= 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Solde net de caisse',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            formatCFA(netFlow),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: netFlow >= 0
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Entrées / Sorties détaillées
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Entrées',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCashRow('Ventes cash', getCashSales()),
                          _buildCashRow('Créances clients', getCreditSales()),
                          const Divider(),
                          const Text(
                            'Sorties',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCashRow('Achats cash', getCashPurchases()),
                          _buildCashRow(
                            'Crédit fournisseurs',
                            getCreditPurchases(),
                          ),
                          _buildCashRow('Dépenses', getExpenses()),
                          _buildCashRow('Versements banque', getBankDeposits()),
                          _buildCashRow('Retraits', getWithdrawals()),
                          _buildCashRow('Remis au gérant', getOwnerTransfers()),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton flottant pour ajouter transaction caisse
                  FloatingActionButton.extended(
                    onPressed: _showAddCashTransaction,
                    label: const Text('Nouvelle transaction'),
                    icon: const Icon(Icons.add),
                    backgroundColor: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCashRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(
            formatCFA(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: value >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCashTransaction() {
    final typeCtrl =
        TextEditingController(); // ex: "bank_deposit", "withdrawal", "owner_transfer"
    final amountCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    DateTime transactionDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle transaction caisse'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: null,
                  decoration: const InputDecoration(
                    labelText: 'Type de transaction',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'bank_deposit',
                      child: Text('Versement banque'),
                    ),
                    DropdownMenuItem(
                      value: 'withdrawal',
                      child: Text('Retrait'),
                    ),
                    DropdownMenuItem(
                      value: 'owner_transfer',
                      child: Text('Remis au gérant'),
                    ),
                  ],
                  onChanged: (val) => typeCtrl.text = val ?? '',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: 50000',
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
                  controller: descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: transactionDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => transactionDate = picked);
                    }
                  },
                  child: Text(DateFormat('dd/MM/yyyy').format(transactionDate)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final montantText = amountCtrl.text
                    .trim()
                    .replaceAll(',', '.')
                    .replaceAll(' ', '');
                final amount = double.tryParse(montantText) ?? 0.0;

                if (typeCtrl.text.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Type et montant obligatoires'),
                    ),
                  );
                  return;
                }

                try {
                  await supabase.from('cash_transactions').insert({
                    'type': typeCtrl.text,
                    'amount': amount,
                    'description': descriptionCtrl.text.trim().isEmpty
                        ? null
                        : descriptionCtrl.text.trim(),
                    'transaction_date': transactionDate.toIso8601String(),
                  });

                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction ajoutée')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}

String formatCFA(num amount) {
  final formatter = NumberFormat('#,###', 'fr_FR');
  return '${formatter.format(amount.abs())} F CFA';
}
