// lib/presentation/screens/purchases/dialogs/add_purchase_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/purchase_provider.dart';
import '../../../providers/product_provider.dart';
import '../../sales/widgets/product_selector.dart';

void showAddPurchaseDialog(BuildContext context) {
  showDialog(context: context, builder: (ctx) => const _AddPurchaseDialog());
}

class _AddPurchaseDialog extends ConsumerStatefulWidget {
  const _AddPurchaseDialog();

  @override
  ConsumerState<_AddPurchaseDialog> createState() => _AddPurchaseDialogState();
}

class _AddPurchaseDialogState extends ConsumerState<_AddPurchaseDialog> {
  final _quantityCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  ProductModel? _selectedProduct;
  DateTime _purchaseDate = DateTime.now();
  bool _paid = true;
  String? _quantityError;

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _amountCtrl.dispose();
    _supplierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.blue), // 🔥 BLEU
          SizedBox(width: 8),
          Text('Nouvel achat'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aucun produit disponible. Ajoutez d\'abord des produits.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ProductSelector(
                  products: products,
                  selectedProduct: _selectedProduct,
                  allowOutOfStock: true,
                  onChanged: (ProductModel? p) {
                    setState(() {
                      _selectedProduct = p;
                      _quantityError = null;
                    });
                  },
                );
              },
              loading: () => const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Chargement des produits...'),
                  ],
                ),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$err',
                      style: TextStyle(color: Colors.red[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_selectedProduct != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedProduct!.stockColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _selectedProduct!.stockColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: _selectedProduct!.stockColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock actuel: ${_selectedProduct!.currentStock} unités',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedProduct!.stockColor,
                            ),
                          ),
                          Text(
                            'Après achat: ${_selectedProduct!.currentStock + (int.tryParse(_quantityCtrl.text) ?? 0)} unités',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            TextField(
              controller: _quantityCtrl,
              decoration: InputDecoration(
                labelText: 'Quantité *',
                hintText: 'Nombre d\'unités à acheter',
                border: const OutlineInputBorder(),
                errorText: _quantityError,
                prefixIcon: const Icon(Icons.format_list_numbered),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final qty = int.tryParse(value) ?? 0;
                  if (qty <= 0) {
                    setState(() => _quantityError = 'Quantité doit être > 0');
                  } else {
                    setState(() => _quantityError = null);
                  }
                }
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant total (CFA) *',
                hintText: 'Prix total de l\'achat',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _supplierCtrl,
              decoration: const InputDecoration(
                labelText: 'Fournisseur (optionnel)',
                hintText: 'Nom du fournisseur',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(_purchaseDate)}',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Payé (comptant)'),
              subtitle: Text(
                _paid ? 'Paiement immédiat' : 'Paiement différé',
                style: TextStyle(
                  fontSize: 12,
                  color: _paid ? Colors.green : Colors.orange,
                ),
              ),
              value: _paid,
              onChanged: (v) => setState(() => _paid = v),
              secondary: Icon(
                _paid ? Icons.payments : Icons.pending,
                color: _paid ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _quantityError != null || _selectedProduct == null
              ? null
              : _submit,
          icon: const Icon(Icons.save),
          label: const Text('Enregistrer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // 🔥 BLEU
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700, // 🔥 BLEU
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedProduct == null) {
      _showError('Veuillez sélectionner un produit');
      return;
    }

    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    if (quantity <= 0) {
      _showError('La quantité doit être supérieure à 0');
      return;
    }

    if (amount <= 0) {
      _showError('Le montant doit être supérieur à 0');
      return;
    }

    try {
      await ref.read(purchaseNotifierProvider.notifier).createPurchase(
        productId: _selectedProduct!.id,
        quantity: quantity,
        amount: amount,
        supplier: _supplierCtrl.text.trim().isEmpty
            ? null
            : _supplierCtrl.text.trim(),
        purchaseDate: _purchaseDate,
      );

      ref.invalidate(purchasesProvider);
      ref.invalidate(productsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Achat enregistré: $quantity x ${_selectedProduct!.name}'),
            backgroundColor: Colors.blue, // 🔥 BLEU
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de l\'enregistrement: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}