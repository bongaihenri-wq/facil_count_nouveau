// lib/presentation/screens/sales/dialogs/add_sale_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/sale_provider.dart'; // 🟢 Pointera vers ton sale provider
import '../../../providers/product_provider.dart';
import '../widgets/product_selector.dart';

void showAddSaleDialog(BuildContext context) {
  showDialog(context: context, builder: (ctx) => const AddSaleDialog());
}

class AddSaleDialog extends ConsumerStatefulWidget {
  const AddSaleDialog();

  @override
  ConsumerState<AddSaleDialog> createState() => _AddSaleDialogState();
}

class _AddSaleDialogState extends ConsumerState<AddSaleDialog> {
  final _quantityCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _customerCtrl = TextEditingController(); // 🟢 Remplacé fournisseur par client
  ProductModel? _selectedProduct;
  DateTime _saleDate = DateTime.now();
  bool _paid = true;
  String? _quantityError;

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _amountCtrl.dispose();
    _customerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.point_of_sale, color: Colors.green), // 🟢 VERT pour la vente
          SizedBox(width: 8),
          Text('Nouvelle vente'),
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
                  allowOutOfStock: false, // 🟢 Bloque la sélection si 0 stock en rayons !
                  onChanged: (ProductModel? p) {
                    setState(() {
                      _selectedProduct = p;
                      _quantityError = null;
                      _quantityCtrl.clear(); // Clear pour forcer le recalcul
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
                            'Stock disponible: ${_selectedProduct!.currentStock} unités',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedProduct!.stockColor,
                            ),
                          ),
                          Text(
                            'Après vente: ${_selectedProduct!.currentStock - (int.tryParse(_quantityCtrl.text) ?? 0)} unités',
                            style: TextStyle(
                              fontSize: 12,
                              color: (_selectedProduct!.currentStock - (int.tryParse(_quantityCtrl.text) ?? 0)) >= 0 
                                  ? Colors.green[700] 
                                  : Colors.red[700],
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
                hintText: 'Nombre d\'unités à vendre',
                border: const OutlineInputBorder(),
                errorText: _quantityError,
                prefixIcon: const Icon(Icons.format_list_numbered),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                if (value.isNotEmpty && _selectedProduct != null) {
                  final qty = int.tryParse(value) ?? 0;
                  if (qty <= 0) {
                    setState(() => _quantityError = 'Quantité doit être > 0');
                  } else if (qty > _selectedProduct!.currentStock) {
                    setState(() => _quantityError = 'Stock insuffisant (${_selectedProduct!.currentStock} max)');
                  } else {
                    setState(() => _quantityError = null);
                  }
                } else {
                  setState(() => _quantityError = null);
                }
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant total (CFA) *',
                hintText: 'Prix total de la vente',
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
              controller: _customerCtrl,
              decoration: const InputDecoration(
                labelText: 'Client (optionnel)',
                hintText: 'Nom du client',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(_saleDate)}',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Payé (comptant)'),
              subtitle: Text(
                _paid ? 'Paiement immédiat' : 'Vente à crédit',
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
            backgroundColor: Colors.green, // 🟢 VERT pour la vente
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
          ),
        ),
      ]);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700, // 🟢 VERT
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _saleDate = picked);
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
      // 🌐 APPEL DU PROVIDER DES VENTES
      await ref.read(saleNotifierProvider.notifier).createSale(
        productId: _selectedProduct!.id,
        quantity: quantity,
        amount: amount,
        clientId: _customerCtrl.text.trim().isEmpty
            ? null
            : _customerCtrl.text.trim(),
        saleDate: _saleDate,
        isPaid: _paid,
      );

      ref.invalidate(salesProvider);
      ref.invalidate(productsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Vente enregistrée: $quantity x ${_selectedProduct!.name}'),
            backgroundColor: Colors.green, // 🟢 VERT
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
