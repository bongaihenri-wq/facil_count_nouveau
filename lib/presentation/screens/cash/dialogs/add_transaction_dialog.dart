// lib/presentation/screens/cash/dialogs/add_transaction_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../providers/cash_provider.dart';
import '../../../../data/models/cash_models.dart';

void showAddTransactionDialog(BuildContext context, WidgetRef ref) {
  final formKey = GlobalKey<FormState>();
  TransactionType selectedType = TransactionType.sale;
  final amountCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> types = [
    {'type': TransactionType.sale, 'label': 'Vente', 'icon': Icons.point_of_sale, 'color': Colors.green},
    {'type': TransactionType.purchase, 'label': 'Achat', 'icon': Icons.shopping_cart, 'color': Colors.orange},
    {'type': TransactionType.expense, 'label': 'Dépense', 'icon': Icons.receipt_long, 'color': Colors.red},
    {'type': TransactionType.contribution, 'label': 'Apport', 'icon': Icons.add_circle, 'color': Colors.blue},
    {'type': TransactionType.bankDeposit, 'label': 'Versement Banque', 'icon': Icons.account_balance, 'color': Colors.indigo},
    {'type': TransactionType.withdrawal, 'label': 'Retrait', 'icon': Icons.payments, 'color': Colors.purple},
    {'type': TransactionType.ownerTransfer, 'label': 'Remis Gérant', 'icon': Icons.person, 'color': Colors.teal},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final selectedColor = selectedType.color;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Nouvelle Transaction',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Types de transaction - GRID 2 colonnes
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: types.map((t) => _buildTypeChip(
                      label: t['label'],
                      icon: t['icon'],
                      type: t['type'],
                      color: t['color'],
                      isSelected: selectedType == t['type'],
                      onTap: () => setState(() => selectedType = t['type']),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Montant
                  TextFormField(
                    controller: amountCtrl,
                    decoration: InputDecoration(
                      labelText: 'Montant',
                      labelStyle: TextStyle(color: selectedColor),
                      prefixText: 'FCFA ',
                      prefixStyle: TextStyle(
                        color: selectedColor,
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: selectedColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: selectedColor, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Champ requis';
                      if (double.tryParse(value) == null) return 'Montant invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnel)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Date
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: selectedColor),
                    title: const Text('Date'),
                    subtitle: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                    trailing: Icon(Icons.chevron_right, color: selectedColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: selectedColor.withOpacity(0.3)),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final amount = double.parse(amountCtrl.text);

                            await ref.read(cashProvider.notifier).addTransaction(
                              type: selectedType,
                              amount: amount,
                              description: descCtrl.text.isEmpty ? null : descCtrl.text,
                              date: selectedDate,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${selectedType.label} enregistrée'),
                                  backgroundColor: selectedColor,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildTypeChip({
  required String label,
  required IconData icon,
  required TransactionType type,
  required Color color,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return ChoiceChip(
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: isSelected ? Colors.white : color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    ),
    selected: isSelected,
    onSelected: (_) => onTap(),
    selectedColor: color,
    backgroundColor: color.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: isSelected ? color : color.withOpacity(0.3),
        width: isSelected ? 2 : 1,
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}