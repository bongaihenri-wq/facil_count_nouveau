import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/product_provider.dart';

void showAddProductDialog(BuildContext context) {
  showDialog(context: context, builder: (ctx) => const _AddProductDialog());
}

class _AddProductDialog extends ConsumerStatefulWidget {
  const _AddProductDialog();

  @override
  ConsumerState<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<_AddProductDialog> {
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _thresholdCtrl = TextEditingController(text: '10');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _supplierCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productNotifierProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_box, color: Colors.purple),
          SizedBox(width: 8),
          Text('Nouveau produit'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nom
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du produit *',
                hintText: 'Ex: Coca Cola 33cl',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              autofocus: true,
            ),

            const SizedBox(height: 16),

            // Catégorie
            TextField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                labelText: 'Catégorie *',
                hintText: 'Ex: Boissons',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),

            const SizedBox(height: 16),

            // Fournisseur
            TextField(
              controller: _supplierCtrl,
              decoration: const InputDecoration(
                labelText: 'Fournisseur (optionnel)',
                hintText: 'Ex: Coca Cola Company',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),

            const SizedBox(height: 16),

            // Stock initial et Seuil
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stockCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Stock initial',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _thresholdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Seuil alerte',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade700,
            foregroundColor: Colors.white,
          ),
          child: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

// Dans la classe _AddProductDialogState, modifie la méthode _submit :

Future<void> _submit() async {
  // --- MODIFICATION : Normalisation du nom ---
  String rawName = _nameCtrl.text.trim();
  if (rawName.isEmpty) {
    _showError('Le nom est obligatoire');
    return;
  }
  
  // Met la 1ère lettre en Majuscule et le reste en minuscule (malta -> Malta)
  final name = rawName[0].toUpperCase() + rawName.substring(1).toLowerCase();
  // --------------------------------------------

  final category = _categoryCtrl.text.trim();

  if (category.isEmpty) {
    _showError('La catégorie est obligatoire');
    return;
  }

  final stock = int.tryParse(_stockCtrl.text) ?? 0;
  final threshold = int.tryParse(_thresholdCtrl.text) ?? 10;

  try { // Ajout du try/catch pour capturer l'erreur du Repository
    await ref
        .read(productNotifierProvider.notifier)
        .createProduct(
          name: name,
          category: category,
          supplier: _supplierCtrl.text.trim().isEmpty
              ? null
              : _supplierCtrl.text.trim(),
          initialStock: stock,
          lowStockThreshold: threshold,
        );

    ref.invalidate(productsProvider);
    if (mounted) Navigator.pop(context);
  } catch (e) {
    _showError(e.toString().replaceAll('Exception: ', ''));
  }
}

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
