import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/expense_model.dart';
import '../../../providers/expense_provider.dart';
import '../../../../core/utils/date_filter_helper.dart'; // Assure-toi que l'import est correct

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

    // Récupération des suggestions réelles via le provider
    final suggestions = ref.watch(expenseSuggestionsProvider).maybeWhen(
          data: (list) => list,
          orElse: () => <String>[],
        );

    // Vue si la dépense est déjà verrouillée au chargement
    if (_locked) {
      return _buildLockedView();
    }

    return AlertDialog(
      title: const Text('Modifier dépense'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Verrouiller'),
                subtitle: const Text('Empêche toute modification future'),
                value: _locked,
                onChanged: (v) => setState(() => _locked = v),
              ),
              const Divider(),
              const SizedBox(height: 8),

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
                    onSelected: (selection) {
                      _nameCtrl.text = selection;
                      FocusScope.of(context).unfocus();
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 10.0,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: constraints.maxWidth,
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
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
                    fieldViewBuilder: (context, fieldTextController, focusNode, onFieldSubmitted) {
                      // Initialisation du controller interne avec la valeur existante
                      if (fieldTextController.text.isEmpty && _nameCtrl.text.isNotEmpty) {
                        fieldTextController.text = _nameCtrl.text;
                      }
                      return TextField(
                        controller: fieldTextController,
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
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
          Text('Nom: ${widget.expense.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Montant: ${widget.expense.amount} CFA'),
          const SizedBox(height: 4),
          Text('Date: ${DateFormat('dd/MM/yyyy').format(widget.expense.expensesDate)}'),
          const SizedBox(height: 16),
          const Text(
            "Cette dépense est verrouillée et ne peut plus être modifiée.",
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    final amount = double.tryParse(amountText) ?? 0;

    if (name.isEmpty || amount <= 0) {
      _showError('Nom et montant valides requis');
      return;
    }

    try {
      await ref.read(expenseNotifierProvider.notifier).updateExpense(
            widget.expense.id,
            name: name,
            amount: amount,
            recipient: _recipientCtrl.text.trim().isEmpty ? null : _recipientCtrl.text.trim(),
            expensesDate: _expenseDate,
            locked: _locked,
          );

      // On rafraîchit la liste globale (nécessaire si on change de date ou de montant)
      ref.invalidate(filteredExpensesProvider);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Erreur lors de la mise à jour : $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}
