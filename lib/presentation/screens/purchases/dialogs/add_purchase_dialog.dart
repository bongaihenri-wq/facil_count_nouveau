import 'package:facil_count_nouveau/presentation/providers/sale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/purchase_provider.dart';
import '../../../providers/expense_provider.dart'; // Pour productsProvider
import '../../../widgets/product_selector.dart'; // ✅ CHEMIN CORRIGÉ
import '../../../providers/product_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final state = ref.watch(purchaseNotifierProvider);

    return AlertDialog(
      title: const Text('Nouvel achat'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sélecteur produit
            productsAsync.when(
              data: (products) => ProductSelector(
                products: products,
                selectedProduct: _selectedProduct,
                onChanged: (p) => setState(() => _selectedProduct = p),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Erreur chargement produits'),
            ),

            const SizedBox(height: 16),

            // Quantité
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

            // Montant
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

            // Fournisseur
            TextField(
              controller: _supplierCtrl,
              decoration: const InputDecoration(
                labelText: 'Fournisseur (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Date
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('dd/MM/yyyy').format(_purchaseDate)),
            ),

            const SizedBox(height: 8),

            // Payé
            SwitchListTile(
              title: const Text('Payé'),
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
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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

    if (quantity <= 0 || amount <= 0) {
      _showError('Quantité et montant doivent être > 0');
      return;
    }

    await ref
        .read(purchaseNotifierProvider.notifier)
        .createPurchase(
          productId: _selectedProduct!.id,
          quantity: quantity,
          amount: amount,
          supplier: _supplierCtrl.text.trim().isEmpty
              ? null
              : _supplierCtrl.text.trim(),
          purchaseDate: _purchaseDate,
          paid: _paid,
        );

    ref.invalidate(purchasesProvider);
    ref.invalidate(productsProvider);

    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
