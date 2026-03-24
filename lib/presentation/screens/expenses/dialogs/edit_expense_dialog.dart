import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/expense_model.dart';
import '../../../providers/expense_provider.dart';

void showEditExpenseDialog(BuildContext context, ExpenseModel expense) {
  showDialog(
    context: context,
    builder: (ctx) => _EditExpenseDialog(expense: expense),
  );
}

class _EditExpenseDialog extends ConsumerStatefulWidget {
  final ExpenseModel expense;

  const _EditExpenseDialog({required this.expense});

  @override
  ConsumerState<_EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends ConsumerState<_EditExpenseDialog> {
  late final _nameCtrl = TextEditingController(text: widget.expense.name);
  late final _amountCtrl = TextEditingController(
    text: widget.expense.amount.toString(),
  );
  late final _recipientCtrl = TextEditingController(
    text: widget.expense.recipient ?? '',
  );
  late final _invoiceCtrl = TextEditingController(
    text: widget.expense.invoiceNumber ?? '',
  );
  late DateTime _expenseDate = widget.expense.expensesDate;
  late bool _locked = widget.expense.locked;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseNotifierProvider);

    if (_locked) {
      return _buildLockedView();
    }

    return AlertDialog(
      title: const Text('Modifier dépense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Verrouiller'),
              value: _locked,
              onChanged: (v) => setState(() => _locked = v),
            ),
            const Divider(),
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
                labelText: 'Bénéficiaire',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _invoiceCtrl,
              decoration: const InputDecoration(
                labelText: 'N° Facture',
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

  Widget _buildLockedView() {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock, color: Colors.orange),
          SizedBox(width: 8),
          Text('Dépense verrouillée'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nom: ${widget.expense.name}'),
          Text('Montant: ${widget.expense.formattedAmount}'),
          Text(
            'Date: ${DateFormat('dd/MM/yyyy').format(widget.expense.expensesDate)}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
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
        .updateExpense(
          widget.expense.id,
          name: name,
          amount: amount,
          recipient: _recipientCtrl.text.trim().isEmpty
              ? null
              : _recipientCtrl.text.trim(),
          expensesDate: _expenseDate,
          locked: _locked,
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
