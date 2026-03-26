import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/product_provider.dart';

void showEditProductDialog(BuildContext context, ProductModel product) {
  showDialog(
    context: context,
    builder: (ctx) => _EditProductDialog(product: product),
  );
}

class _EditProductDialog extends ConsumerStatefulWidget {
  final ProductModel product;

  const _EditProductDialog({required this.product});

  @override
  ConsumerState<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<_EditProductDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _supplierCtrl;
  late final TextEditingController _thresholdCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _categoryCtrl = TextEditingController(text: widget.product.category);
    _supplierCtrl = TextEditingController(text: widget.product.supplier ?? '');
    _thresholdCtrl = TextEditingController(
      text: widget.product.lowStockThreshold.toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _supplierCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productNotifierProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit, color: Colors.purple),
          const SizedBox(width: 8),
          Text('Modifier ${widget.product.name}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info stock actuel (lecture seule)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Stock actuel: ${widget.product.currentStock}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nom
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du produit *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
            ),

            const SizedBox(height: 16),

            // Catégorie
            TextField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                labelText: 'Catégorie *',
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
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),

            const SizedBox(height: 16),

            // Seuil alerte
            TextField(
              controller: _thresholdCtrl,
              decoration: const InputDecoration(
                labelText: 'Seuil alerte stock bas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning),
                helperText: 'Alerte quand stock ≤ ce seuil',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

    final threshold = int.tryParse(_thresholdCtrl.text) ?? 10;

    await ref
        .read(productNotifierProvider.notifier)
        .updateProduct(
          id: widget.product.id,
          name: name,
          category: category,
          supplier: _supplierCtrl.text.trim().isEmpty
              ? null
              : _supplierCtrl.text.trim(),
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
