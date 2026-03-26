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

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final category = _categoryCtrl.text.trim();

    if (name.isEmpty || category.isEmpty) {
      _showError('Nom et catégorie sont obligatoires');
      return;
    }

    final stock = int.tryParse(_stockCtrl.text) ?? 0;
    final threshold = int.tryParse(_thresholdCtrl.text) ?? 10;

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
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
