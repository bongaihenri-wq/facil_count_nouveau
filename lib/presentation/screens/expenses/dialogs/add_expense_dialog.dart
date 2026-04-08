import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/expense_provider.dart';

void showAddExpenseDialog(BuildContext context) {
  showDialog(context: context, builder: (ctx) => const _AddExpenseDialog());
}

class _AddExpenseDialog extends ConsumerStatefulWidget {
  const _AddExpenseDialog();

  @override
  ConsumerState<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<_AddExpenseDialog> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();
  DateTime _expenseDate = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _recipientCtrl.dispose();
    _invoiceCtrl.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  final state = ref.watch(expenseNotifierProvider);

 // 1. On récupère les VRAIES suggestions du provider
 final suggestions = ref.watch(expenseSuggestionsProvider).maybeWhen(
        data: (list) => list,
        orElse: () => <String>[],
      );
  print("-----------------------------------------");
  print("🚀 DIALOGUE OUVERT - Suggestions : $suggestions");
  print("-----------------------------------------");

  return AlertDialog(
    title: const Text('Nouvelle dépense'),
    content: SizedBox( // On enveloppe pour donner une contrainte de largeur
      width: MediaQuery.of(context).size.width * 0.9,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- CHAMP NOM AVEC AUTOCOMPLÉTION AMÉLIORÉ ---
            LayoutBuilder(
              builder: (context, constraints) {
                return Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return suggestions;
                    return suggestions.where((option) => option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (selection) => _nameCtrl.text = selection,
                  
                  // Amélioration de l'affichage de la liste
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: constraints.maxWidth, // Largeur exacte du champ de texte
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(Icons.history, size: 18),
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la dépense *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit),
                      ),
                      onChanged: (value) => _nameCtrl.text = value,
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 16),

            // --- MONTANT ---
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant (CFA) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            
            const SizedBox(height: 16),

            // --- BÉNÉFICIAIRE ---
            TextField(
              controller: _recipientCtrl,
              decoration: const InputDecoration(
                labelText: 'Bénéficiaire (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            
            const SizedBox(height: 16),

            // --- FACTURE ---
            TextField(
              controller: _invoiceCtrl,
              decoration: const InputDecoration(
                labelText: 'N° Facture (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
            ),
            
            const SizedBox(height: 16),

            // --- DATE ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('dd/MM/yyyy').format(_expenseDate)),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      ElevatedButton(
        onPressed: state.isLoading ? null : _submit,
        child: state.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Enregistrer'),
      ),
    ],
  );
}

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    if (name.isEmpty || amount <= 0) {
      _showError('Nom et montant requis');
      return;
    }

    await ref.read(expenseNotifierProvider.notifier).addExpense(
          name: name,
          amount: amount,
          recipient: _recipientCtrl.text.trim().isEmpty
              ? null
              : _recipientCtrl.text.trim(),
          expensesDate: _expenseDate,
        );

    ref.invalidate(filteredExpensesProvider);
    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}