import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '/../presentation/providers/cash_provider.dart';

void showAddTransactionDialog(BuildContext context, WidgetRef ref) {
  final formKey = GlobalKey<FormState>();
  String selectedType = 'bank_deposit';
  final amountCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();

  // Couleurs par type
  final Map<String, Color> typeColors = {
    'bank_deposit': Colors.blue,
    'withdrawal': Colors.orange,
    'owner_transfer': Colors.purple,
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final selectedColor = typeColors[selectedType]!;

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

                  // Type de transaction - BOUTONS COLORÉS
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildTypeChip(
                        label: 'Versement Banque',
                        icon: Icons.account_balance,
                        value: 'bank_deposit',
                        color: Colors.blue,
                        isSelected: selectedType == 'bank_deposit',
                        onTap: () =>
                            setState(() => selectedType = 'bank_deposit'),
                      ),
                      _buildTypeChip(
                        label: 'Retrait',
                        icon: Icons.payments,
                        value: 'withdrawal',
                        color: Colors.orange,
                        isSelected: selectedType == 'withdrawal',
                        onTap: () =>
                            setState(() => selectedType = 'withdrawal'),
                      ),
                      _buildTypeChip(
                        label: 'Remis Gérant',
                        icon: Icons.person,
                        value: 'owner_transfer',
                        color: Colors.purple,
                        isSelected: selectedType == 'owner_transfer',
                        onTap: () =>
                            setState(() => selectedType = 'owner_transfer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Montant avec couleur dynamique
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: selectedColor.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: selectedColor, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear, color: selectedColor),
                        onPressed: () => amountCtrl.clear(),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Champ requis';
                      if (double.tryParse(value) == null)
                        return 'Montant invalide';
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

                  // Date avec couleur
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

                  // Boutons d'action
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

                            await ref
                                .read(cashProvider.notifier)
                                .addTransaction(
                                  type: selectedType,
                                  amount: amount,
                                  description: descCtrl.text.isEmpty
                                      ? null
                                      : descCtrl.text,
                                  date: selectedDate,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Transaction enregistrée',
                                  ),
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

// Widget pour les chips de type avec couleurs distinctes
Widget _buildTypeChip({
  required String label,
  required IconData icon,
  required String value,
  required MaterialColor color,
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
