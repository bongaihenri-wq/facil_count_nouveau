import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showEditPurchaseForm(
  BuildContext context, {
  required Map<String, dynamic> purchase,
  required List<Map<String, dynamic>> products,
  required VoidCallback onUpdated,
}) async {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? selectedProduct;
  final quantityCtrl = TextEditingController(
    text: purchase['quantity'].toString(),
  );
  final amountCtrl = TextEditingController(text: purchase['amount'].toString());
  final supplierCtrl = TextEditingController(text: purchase['supplier'] ?? '');
  final invoiceCtrl = TextEditingController(
    text: purchase['invoice_number'] ?? '',
  );
  DateTime purchaseDate =
      DateTime.tryParse(purchase['purchase_date'] ?? '') ?? DateTime.now();
  bool paid = purchase['paid'] ?? true;
  bool locked = purchase['locked'] ?? false;
  final oldQuantity = purchase['quantity'] as int;
  final oldProductId = purchase['product_id'];

  // Initialiser le produit actuel
  selectedProduct = products.firstWhere(
    (prod) => prod['id'] == oldProductId,
    orElse: () => {},
  );

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Modifier achat'),
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
                    // 1. Récupérer le stock actuel de l'ancien produit (si changement)
                    if (oldProductId != selectedProduct!['id']) {
                      final oldStockRes = await supabase
                          .rpc(
                            'get_current_stock',
                            params: {'p_id': oldProductId},
                          )
                          .single();
                      final oldStock =
                          oldStockRes['current_stock'] as int? ?? 0;
                      await supabase
                          .from('products')
                          .update({'current_stock': oldStock - oldQuantity})
                          .eq('id', oldProductId);

                      final newStockRes = await supabase
                          .rpc(
                            'get_current_stock',
                            params: {'p_id': selectedProduct!['id']},
                          )
                          .single();
                      final newStock =
                          newStockRes['current_stock'] as int? ?? 0;
                      await supabase
                          .from('products')
                          .update({'current_stock': newStock + qty})
                          .eq('id', selectedProduct!['id']);
                    } else {
                      // Même produit → ajuster la différence
                      final diff = qty - oldQuantity;
                      final currentStockRes = await supabase
                          .rpc(
                            'get_current_stock',
                            params: {'p_id': oldProductId},
                          )
                          .single();
                      final currentStock =
                          currentStockRes['current_stock'] as int? ?? 0;
                      await supabase
                          .from('products')
                          .update({'current_stock': currentStock + diff})
                          .eq('id', oldProductId);
                    }

                    // 2. Mettre à jour l'achat
                    await supabase
                        .from('purchases')
                        .update({
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
                        })
                        .eq('id', purchase['id']);

                    if (context.mounted) {
                      onUpdated();
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Achat modifié avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la modification : $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Valider'),
              ),
            ],
          );
        },
      );
    },
  );
}
