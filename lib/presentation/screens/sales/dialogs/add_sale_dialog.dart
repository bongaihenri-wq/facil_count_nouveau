// lib/presentation/screens/sales/dialogs/add_sale_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/sale_provider.dart';
import '../../sales/widgets/product_selector.dart';
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
  String? _quantityError; // 🔥 NOUVEAU: erreur de validation quantité

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
          Icon(Icons.point_of_sale, color: Colors.green),
          SizedBox(width: 8),
          Text('Nouvelle vente'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 SÉLECTEUR DE PRODUIT AVEC STOCK
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aucun produit disponible. Veuillez d\'abord ajouter des produits.',
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
                  allowOutOfStock: false, // 🔥 Interdit pour les ventes
                  onChanged: (ProductModel? p) {
                    setState(() {
                      _selectedProduct = p;
                      _quantityError = null; // 🔥 Reset erreur quand changement
                      print('Produit sélectionné: ${p?.name} | Stock: ${p?.currentStock}');
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$err',
                      style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 AFFICHAGE DU STOCK SÉLECTIONNÉ
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
                          if (_selectedProduct!.isLowStock)
                            Text(
                              '⚠️ Stock bas (seuil: ${_selectedProduct!.lowStockThreshold})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 🔥 QUANTITÉ AVEC VALIDATION VISUELLE
            TextField(
              controller: _quantityCtrl,
              decoration: InputDecoration(
                labelText: 'Quantité *',
                hintText: _selectedProduct != null 
                    ? 'Max: ${_selectedProduct!.currentStock}' 
                    : 'Entrez la quantité',
                border: const OutlineInputBorder(),
                errorText: _quantityError, // 🔥 Affiche l'erreur
                prefixIcon: const Icon(Icons.format_list_numbered),
                suffixIcon: _selectedProduct != null
                    ? Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Max: ${_selectedProduct!.currentStock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                // 🔥 VALIDATION EN TEMPS RÉEL
                if (_selectedProduct != null && value.isNotEmpty) {
                  final qty = int.tryParse(value) ?? 0;
                  if (qty > _selectedProduct!.currentStock) {
                    setState(() {
                      _quantityError = 'Stock insuffisant! Max: ${_selectedProduct!.currentStock}';
                    });
                  } else if (qty <= 0) {
                    setState(() {
                      _quantityError = 'Quantité doit être > 0';
                    });
                  } else {
                    setState(() {
                      _quantityError = null;
                    });
                  }
                }
              },
            ),

            const SizedBox(height: 16),

            // MONTANT
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

            // CLIENT
            TextField(
              controller: _customerCtrl,
              decoration: const InputDecoration(
                labelText: 'Client (optionnel)',
                hintText: 'Nom du client',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 16),

            // DATE
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

            // PAIEMENT
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
              ? null  // 🔥 Désactivé si erreur ou pas de produit
              : _submit,
          icon: const Icon(Icons.save),
          label: const Text('Enregistrer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _saleDate = picked);
  }

  Future<void> _submit() async {
    // 🔥 VALIDATIONS FINALES
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

    // 🔥 VÉRIFICATION STOCK (double sécurité)
    if (quantity > _selectedProduct!.currentStock) {
      _showError(
        'Stock insuffisant!\n'
        'Disponible: ${_selectedProduct!.currentStock}\n'
        'Demandé: $quantity',
      );
      return;
    }

    // 🔥 CONFIRMATION SI STOCK BAS APRÈS VENTE
    final remainingStock = _selectedProduct!.currentStock - quantity;
    if (remainingStock <= 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('Confirmation'),
            ],
          ),
          content: Text(
            'Cette vente videra complètement le stock de ${_selectedProduct!.name}.\n\n'
            'Stock après vente: 0 unité(s)\n\n'
            'Êtes-vous sûr de vouloir continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      await ref.read(saleNotifierProvider.notifier).createSale(
        productId: _selectedProduct!.id,
        quantity: quantity,
        amount: amount,
        clientId: _customerCtrl.text.trim().isEmpty ? null : _customerCtrl.text.trim(),
        saleDate: _saleDate,
      );

      ref.invalidate(salesProvider);
      ref.invalidate(productsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Vente enregistrée: $quantity x ${_selectedProduct!.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
