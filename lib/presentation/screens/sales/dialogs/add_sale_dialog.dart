import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/product_model.dart'; // ← AJOUTER
import '../../../providers/sale_provider.dart';
import '../widgets/product_selector.dart';

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
  ProductModel? _selectedProduct; // ← TYPO EXPLICITE, PAS 'var'
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
            productsAsync.when(
              data: (products) => ProductSelector(
                products: products,
                selectedProduct: _selectedProduct,
                onChanged: (ProductModel? p) {
                  // ← TYPO EXPLICITE
                  setState(() => _selectedProduct = p);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Erreur: $err'),
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
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
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

    if (quantity > _selectedProduct!.currentStock) {
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
