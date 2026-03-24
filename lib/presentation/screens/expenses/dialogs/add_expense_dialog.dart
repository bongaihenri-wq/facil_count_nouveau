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
  Widget build(BuildContext context) {
    final state = ref.watch(expenseNotifierProvider);

    return AlertDialog(
      title: const Text('Nouvelle dépense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la dépense *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant (CFA) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recipientCtrl,
              decoration: const InputDecoration(
                labelText: 'Bénéficiaire (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _invoiceCtrl,
              decoration: const InputDecoration(
                labelText: 'N° Facture (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('dd/MM/yyyy').format(_expenseDate)),
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
              ? const CircularProgressIndicator()
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

    await ref
        .read(expenseNotifierProvider.notifier)
        .addExpense(
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
