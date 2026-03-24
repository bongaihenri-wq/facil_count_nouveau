import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/sale_provider.dart';
import '../../../providers/product_provider.dart';

void showSaleFilterDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _FilterDialogContent(),
  );
}

class _FilterDialogContent extends ConsumerStatefulWidget {
  const _FilterDialogContent();

  @override
  ConsumerState<_FilterDialogContent> createState() =>
      _FilterDialogContentState();
}

class _FilterDialogContentState extends ConsumerState<_FilterDialogContent> {
  ProductModel? _selectedProduct;
  DateTime? _startDate;
  DateTime? _endDate;
  final _minQtyCtrl = TextEditingController();
  final _maxQtyCtrl = TextEditingController();

  @override
  void dispose() {
    _minQtyCtrl.dispose();
    _maxQtyCtrl.dispose();
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
            'Filtrer les ventes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Produit
          productsAsync.when(
            data: (products) => DropdownButtonFormField<ProductModel?>(
              isExpanded: true, // ← AJOUTER CECI
              value: _selectedProduct,
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous')),
                ...products.map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      p.name,
                      overflow: TextOverflow.ellipsis, // ← AJOUTER CECI
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedProduct = v),
              decoration: const InputDecoration(
                labelText: 'Produit',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                ), // ← Réduire padding
              ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Erreur chargement produits'),
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

          const SizedBox(height: 12),

          // Quantité
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minQtyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Qté min',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxQtyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Qté max',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
                  ref.read(saleFiltersProvider.notifier).clearFilters();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Réinitialiser'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(saleFiltersProvider.notifier)
                      .setFilters(
                        productId: _selectedProduct?.id,
                        startDate: _startDate,
                        endDate: _endDate,
                        minQuantity: int.tryParse(_minQtyCtrl.text),
                        maxQuantity: int.tryParse(_maxQtyCtrl.text),
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
