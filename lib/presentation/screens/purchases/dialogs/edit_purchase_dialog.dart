import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/purchase_model.dart';
import '../../../providers/purchase_provider.dart';
import '../../sales/widgets/product_selector.dart';
import '../../../providers/product_provider.dart';

void showEditPurchaseDialog(BuildContext context, PurchaseModel purchase) {
  showDialog(
    context: context,
    builder: (ctx) => _EditPurchaseDialog(purchase: purchase),
  );
}

class _EditPurchaseDialog extends ConsumerStatefulWidget {
  final PurchaseModel purchase;

  const _EditPurchaseDialog({required this.purchase});

  @override
  ConsumerState<_EditPurchaseDialog> createState() =>
      _EditPurchaseDialogState();
}

class _EditPurchaseDialogState extends ConsumerState<_EditPurchaseDialog> {
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _supplierCtrl;
  ProductModel? _selectedProduct;
  late DateTime _purchaseDate;
  late bool _paid;
  late bool _locked;
  bool _isLoadingProduct = true;

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController(
      text: widget.purchase.quantity.toString(),
    );
    _amountCtrl = TextEditingController(
      text: widget.purchase.amount.toString(),
    );
    _supplierCtrl = TextEditingController(text: widget.purchase.supplier ?? ''); // 👈 Corrigé
    _purchaseDate = widget.purchase.purchaseDate;
    _paid = widget.purchase.paid;
    _locked = widget.purchase.locked;
    _loadProduct();
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _amountCtrl.dispose();
    _supplierCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final products = await ref.read(productsProvider.future);
      final product = products.firstWhere(
        (p) => p.id == widget.purchase.productId,
        orElse: () => ProductModel(
          id: widget.purchase.productId,
          name: widget.purchase.productName ?? 'Produit inconnu',
          category: 'Autre',
          createdAt: DateTime.now(),
       
        ),
      );
      setState(() {
        _selectedProduct = product;
        _isLoadingProduct = false;
      });
    } catch (e) {
      setState(() => _isLoadingProduct = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final state = ref.watch(purchaseNotifierProvider);
    final themeColor = Colors.blue.shade700; // Couleur harmonisée

    if (_locked) {
      return _buildLockedView();
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: themeColor),
          const SizedBox(width: 8),
          const Text('Modifier achat'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Verrouiller
            SwitchListTile(
              title: const Text('Verrouiller cet achat'),
              subtitle: const Text('Empêche toute modification future'),
              value: _locked,
              onChanged: (v) => setState(() => _locked = v),
              activeColor: themeColor,
            ),

            const Divider(),

            // Produit
            if (_isLoadingProduct)
              const Center(child: CircularProgressIndicator())
            else
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
                prefixIcon: Icon(Icons.format_list_numbered),
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
                prefixIcon: Icon(Icons.attach_money),
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
                prefixIcon: Icon(Icons.business),
              ),
            ),

            const SizedBox(height: 16),

            // Date
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('dd/MM/yyyy').format(_purchaseDate)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 8),

            // Payé
            SwitchListTile(
              title: const Text('Payé'),
              value: _paid,
              activeColor: Colors.green,
              onChanged: (v) => setState(() => _paid = v),
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
          onPressed: state.isLoading || _isLoadingProduct ? null : _submit,
          icon: const Icon(Icons.save),
          label: const Text('Enregistrer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildLockedView() {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Achat verrouillé'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produit: ${widget.purchase.productName ?? 'Inconnu'}'),
          Text('Quantité: ${widget.purchase.quantity}'),
          Text('Montant: ${widget.purchase.formattedAmount}'),
          Text(
            'Date: ${DateFormat('dd/MM/yyyy').format(widget.purchase.purchaseDate)}',
          ),
          const SizedBox(height: 16),
          const Text(
            'Cet achat est verrouillé et ne peut pas être modifié.',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        TextButton.icon(
          onPressed: _showUnlockConfirm,
          icon: const Icon(Icons.lock_open, color: Colors.red, size: 18),
          label: const Text(
            'Déverrouiller',
            style: TextStyle(color: Colors.red),
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
              primary: Colors.orange.shade800,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _showUnlockConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déverrouiller ?'),
        content: const Text(
          'Êtes-vous sûr de vouloir déverrouiller cet achat ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, déverrouiller'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _locked = false);
    }
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

    try {
      await ref
          .read(purchaseNotifierProvider.notifier)
          .updatePurchase(
            id: widget.purchase.id,
            productId: _selectedProduct!.id,
            quantity: quantity,
            amount: amount,
            supplierId: _supplierCtrl.text.trim().isEmpty // 👈 CORRIGÉ ICI
                ? null
                : _supplierCtrl.text.trim(),
            purchaseDate: _purchaseDate,
            paid: _paid,
            locked: _locked,
          );

      ref.invalidate(purchasesProvider);
      ref.invalidate(productsProvider);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Erreur lors de la modification : $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
