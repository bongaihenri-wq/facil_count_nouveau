import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/sale_model.dart';
import '../../../providers/sale_provider.dart';
import '../../sales/widgets/product_selector.dart';
import '../../../providers/product_provider.dart';

void showEditSaleDialog(BuildContext context, SaleModel sale) {
  showDialog(
    context: context,
    builder: (ctx) => _EditSaleDialog(sale: sale),
  );
}

class _EditSaleDialog extends ConsumerStatefulWidget {
  final SaleModel sale;

  const _EditSaleDialog({required this.sale});

  @override
  ConsumerState<_EditSaleDialog> createState() => _EditSaleDialogState();
}

class _EditSaleDialogState extends ConsumerState<_EditSaleDialog> {
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _customerCtrl;
  ProductModel? _selectedProduct;
  late DateTime _saleDate;
  late bool _paid;
  late bool _locked;
  bool _isLoadingProduct = true;

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController(
      text: widget.sale.quantity.toString(),
    );
    _amountCtrl = TextEditingController(text: widget.sale.amount.toString());
    _customerCtrl = TextEditingController(text: widget.sale.customer ?? '');
    _saleDate = widget.sale.saleDate;
    _paid = widget.sale.paid;
    _locked = widget.sale.locked;
    _loadProduct();
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _amountCtrl.dispose();
    _customerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final products = await ref.read(productsProvider.future);
      final product = products.firstWhere(
        (p) => p.id == widget.sale.productId,
        orElse: () => ProductModel(
          id: widget.sale.productId,
          name: widget.sale.productName ?? 'Produit inconnu',
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
    final state = ref.watch(saleNotifierProvider);

    // Si verrouillé, afficher mode lecture seule
    if (_locked) {
      return _buildLockedView();
    }

    return AlertDialog(
      title: const Text('Modifier vente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle Verrouiller
            SwitchListTile(
              title: const Text('Verrouiller cette vente'),
              subtitle: const Text('Empêche toute modification future'),
              value: _locked,
              onChanged: (v) => setState(() => _locked = v),
              activeColor: Colors.orange,
            ),

            const Divider(),

            // Sélecteur produit
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

            // Client
            TextField(
              controller: _customerCtrl,
              decoration: const InputDecoration(
                labelText: 'Client (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Date
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('dd/MM/yyyy').format(_saleDate)),
            ),

            const SizedBox(height: 8),

            // Payé
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
          onPressed: state.isLoading || _isLoadingProduct ? null : _submit,
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

  Widget _buildLockedView() {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Vente verrouillée'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Produit', widget.sale.productName ?? 'Inconnu'),
          _buildInfoRow('Quantité', '${widget.sale.quantity}'),
          _buildInfoRow(
            'Montant',
            '${widget.sale.amount.toStringAsFixed(0)} CFA',
          ),
          _buildInfoRow('Client', widget.sale.customer ?? '-'),
          _buildInfoRow(
            'Date',
            DateFormat('dd/MM/yyyy').format(widget.sale.saleDate),
          ),
          _buildInfoRow('Statut', widget.sale.paid ? 'Payé' : 'Non payé'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cette vente est verrouillée et ne peut pas être modifiée.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        // Option déverrouiller (avec confirmation)
        TextButton(
          onPressed: _showUnlockConfirm,
          child: const Text(
            'Déverrouiller',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label :',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _saleDate = picked);
    }
  }

  Future<void> _showUnlockConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déverrouiller ?'),
        content: const Text(
          'Êtes-vous sûr de vouloir déverrouiller cette vente ? '
          'Elle pourra être modifiée ou supprimée.',
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
      // Relancer le build pour afficher le formulaire d'édition
    }
  }

  // Dans _submit() de edit_sale_dialog.dart

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

  // 🔥 VÉRIFICATION STOCK (si changement de quantité)
  final oldQuantity = widget.sale.quantity;
  final quantityDiff = quantity - oldQuantity;
  
  if (quantityDiff > 0 && quantityDiff > _selectedProduct!.currentStock) {
    _showError(
      'Stock insuffisant pour augmenter la quantité.\n'
      'Stock disponible: ${_selectedProduct!.currentStock}\n'
      'Augmentation demandée: +$quantityDiff'
    );
    return;
  }

  try {
    print('🔥 Mise à jour vente: ${widget.sale.id}');
    print('  Produit: ${_selectedProduct!.id}');
    print('  Quantité: $quantity (avant: $oldQuantity)');
    print('  Montant: $amount'); print('🔥 TENTATIVE MISE À JOUR');
    print('  ID vente: ${widget.sale.id}');
    print('  ID produit: ${_selectedProduct!.id}');
    print('  Quantité: $quantity');
    print('  Montant: $amount');
    print('  Date: $_saleDate');
    print('  Payé: $_paid');
    print('  Verrouillé: $_locked');
    
    await ref.read(saleNotifierProvider.notifier).updateSale(
      id: widget.sale.id,
      productId: _selectedProduct!.id,
      quantity: quantity,
      amount: amount,
      customer: _customerCtrl.text.trim().isEmpty
          ? null
          : _customerCtrl.text.trim(),
      saleDate: _saleDate,
      paid: _paid,
      locked: _locked,
    );

     print('✅ updateSale terminé sans erreur');

    // 🔥 VÉRIFICATION IMMÉDIATE
    final sales = await ref.read(salesProvider.future);
    final updatedSale = sales.firstWhere(
      (s) => s.id == widget.sale.id,
      orElse: () => throw Exception('Vente non trouvée après maj'),
    );
    print('🔍 VÉRIFICATION:');
    print('  Quantité en base: ${updatedSale.quantity}');
    print('  Montant en base: ${updatedSale.amount}');

    ref.invalidate(salesProvider);
    ref.invalidate(productsProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vente modifiée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e, stack) {
    print('❌ ERREUR: $e');
    print(stack);
    _showError('Erreur: $e');
  }
}

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
