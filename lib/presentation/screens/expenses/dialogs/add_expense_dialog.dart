import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '/presentation/providers/expense_provider.dart';

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
  DateTime _date = DateTime.now();
  bool _locked = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseNotifierProvider);

    return AlertDialog(
      title: const Text('Ajouter une dépense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant *',
                border: OutlineInputBorder(),
                suffixText: 'CFA',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recipientCtrl,
              decoration: const InputDecoration(
                labelText: 'Destinataire',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pickDate,
              child: Text('Date: ${DateFormat('dd/MM/yyyy').format(_date)}'),
            ),
            SwitchListTile(
              title: const Text('Verrouiller'),
              value: _locked,
              onChanged: (v) => setState(() => _locked = v),
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
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et montant obligatoires')),
      );
      return;
    }

    await ref
        .read(expenseNotifierProvider.notifier)
        .addExpense(
          name: name,
          amount: amount,
          recipient: _recipientCtrl.text.trim().isEmpty
              ? null
              : _recipientCtrl.text.trim(),
          expensesDate: _date,
          locked: _locked,
        );

    ref.invalidate(filteredExpensesProvider);
    if (mounted) Navigator.pop(context);
  }
}
