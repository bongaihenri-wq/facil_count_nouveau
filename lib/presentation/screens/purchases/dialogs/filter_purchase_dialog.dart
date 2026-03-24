import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/purchase_provider.dart';

void showPurchaseFilterDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _FilterPurchaseDialogContent(),
  );
}

class _FilterPurchaseDialogContent extends ConsumerStatefulWidget {
  const _FilterPurchaseDialogContent();

  @override
  ConsumerState<_FilterPurchaseDialogContent> createState() =>
      _FilterPurchaseDialogContentState();
}

class _FilterPurchaseDialogContentState
    extends ConsumerState<_FilterPurchaseDialogContent> {
  ProductModel? _selectedProduct;
  final _supplierCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _supplierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 25;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrer les achats',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Produit
          productsAsync.when(
            data: (products) => DropdownButtonFormField<ProductModel?>(
              value: _selectedProduct,
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tous les produits'),
                ),
                ...products.map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                ),
              ],
              onChanged: (v) => setState(() => _selectedProduct = v),
              decoration: const InputDecoration(
                labelText: 'Produit',
                border: OutlineInputBorder(),
              ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Erreur chargement produits'),
          ),

          const SizedBox(height: 12),

          // Fournisseur
          TextField(
            controller: _supplierCtrl,
            decoration: const InputDecoration(
              labelText: 'Fournisseur',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          // Dates
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  label: Text(
                    _startDate == null
                        ? 'Du'
                        : DateFormat('dd/MM/yyyy').format(_startDate!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                  label: Text(
                    _endDate == null
                        ? 'Au'
                        : DateFormat('dd/MM/yyyy').format(_endDate!),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Boutons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  ref.read(purchaseFiltersProvider.notifier).clearFilters();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Réinitialiser'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(purchaseFiltersProvider.notifier)
                      .setFilters(
                        productId: _selectedProduct?.id,
                        supplier: _supplierCtrl.text.trim().isEmpty
                            ? null
                            : _supplierCtrl.text.trim(),
                        startDate: _startDate,
                        endDate: _endDate,
                      );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Appliquer'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
