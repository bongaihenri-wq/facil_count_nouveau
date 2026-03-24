import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showAddPurchaseForm(
  BuildContext context, {
  required List<Map<String, dynamic>> products,
  required VoidCallback onAdded,
}) async {
  Map<String, dynamic>? selectedProduct;
  final quantityCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final supplierCtrl = TextEditingController();
  final invoiceCtrl = TextEditingController();
  DateTime purchaseDate = DateTime.now();
  bool paid = true;
  bool locked = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ajouter un achat'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: selectedProduct,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Produit *',
                      border: OutlineInputBorder(),
                    ),
                    items: products.map((prod) {
                      final stock = prod['current_stock'] ?? 0;
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: prod,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(prod['name'] ?? 'Sans nom')),
                            Text(
                              'Stock: $stock',
                              style: TextStyle(
                                color: stock > 0 ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedProduct = value),
                    hint: const Text('Sélectionnez un produit'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quantité *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Montant total *',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: 375000 ou 375.50',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: supplierCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Fournisseur (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: invoiceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Numéro facture (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: purchaseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => purchaseDate = picked);
                    },
                    child: Text(DateFormat('dd/MM/yyyy').format(purchaseDate)),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Payé'),
                    value: paid,
                    onChanged: (val) => setState(() => paid = val),
                  ),
                  SwitchListTile(
                    title: const Text('Verrouillé'),
                    value: locked,
                    onChanged: (val) => setState(() => locked = val),
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
                onPressed: () async {
                  final qty = int.tryParse(quantityCtrl.text.trim()) ?? 0;
                  final amtText = amountCtrl.text.trim().replaceAll(',', '.');
                  final amt = double.tryParse(amtText) ?? 0.0;

                  if (selectedProduct == null || qty <= 0 || amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Remplissez tous les champs obligatoires',
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    await Supabase.instance.client.from('purchases').insert({
                      'product_id': selectedProduct!['id'],
                      'quantity': qty,
                      'amount': amt,
                      'purchase_date': purchaseDate.toIso8601String(),
                      'supplier': supplierCtrl.text.trim().isEmpty
                          ? null
                          : supplierCtrl.text.trim(),
                      'invoice_number': invoiceCtrl.text.trim().isEmpty
                          ? null
                          : invoiceCtrl.text.trim(),
                      'paid': paid,
                      'locked': locked,
                    });

                    onAdded();
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Achat ajouté'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur ajout : $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      );
    },
  );
}
