import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/sale_provider.dart';
import '../widgets/product_selector.dart';
import '../../../providers/product_provider.dart';

void showAddSaleDialog(BuildContext context) {
  showDialog(context: context, builder: (ctx) => const _AddSaleDialog());
}

class _AddSaleDialog extends ConsumerStatefulWidget {
  const _AddSaleDialog();

  @override
  ConsumerState<_AddSaleDialog> createState() => _AddSaleDialogState();
}

class _AddSaleDialogState extends ConsumerState<_AddSaleDialog> {
  final _quantityCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  ProductModel? _selectedProduct;
  DateTime _saleDate = DateTime.now();
  bool _paid = true;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final state = ref.watch(saleNotifierProvider);

    return AlertDialog(
      title: const Text('Nouvelle vente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Affichage debug si erreur
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Text('⚠️ Aucun produit chargé');
                }
                return ProductSelector(
                  products: products,
                  selectedProduct: _selectedProduct,
                  onChanged: (ProductModel? p) {
                    setState(() {
                      _selectedProduct = p;
                      print(
                        'Dans setState: ${_selectedProduct?.name}',
                      ); // Debug
                    });
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Column(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  Text(
                    'Erreur: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                  Text('Stack: $stack', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _quantityCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantité *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant total (CFA) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _customerCtrl,
              decoration: const InputDecoration(
                labelText: 'Client (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: _pickDate,
              child: Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(_saleDate)}',
              ),
            ),

            SwitchListTile(
              title: const Text('Payé (cash)'),
              value: _paid,
              onChanged: (v) => setState(() => _paid = v),
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
          onPressed: () {
            print('Produit avant submit: ${_selectedProduct?.name}');
            print('ID: ${_selectedProduct?.id}');
            _submit();
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

    if (quantity <= 0 || amount <= 0) {
      _showError('Quantité et montant doivent être > 0');
      return;
    }

    if (quantity > (_selectedProduct!.currentStock)) {
      _showError(
        'Stock insuffisant. Disponible: ${_selectedProduct!.currentStock}',
      );
      return;
    }

    await ref
        .read(saleNotifierProvider.notifier)
        .createSale(
          productId: _selectedProduct!.id,
          quantity: quantity,
          amount: amount,
          customer: _customerCtrl.text.trim().isEmpty
              ? null
              : _customerCtrl.text.trim(),
          saleDate: _saleDate,
        );

    ref.invalidate(salesProvider);
    ref.invalidate(productsProvider);

    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
