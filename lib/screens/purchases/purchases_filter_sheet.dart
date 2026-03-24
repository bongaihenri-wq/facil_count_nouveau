import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> showPurchasesFilterSheet(
  BuildContext context, {
  required Function(String filter, DateTime? start, DateTime? end, int? qty)
  onFilterChanged,
}) async {
  String productFilter = '';
  DateTime? startDate;
  DateTime? endDate;
  int? exactQuantity;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Produit (contient)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  productFilter = val.trim();
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          startDate = picked;
                          setModalState(() {});
                        }
                      },
                      child: Text(
                        startDate == null
                            ? 'Date début'
                            : DateFormat('dd/MM/yyyy').format(startDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          endDate = picked;
                          setModalState(() {});
                        }
                      },
                      child: Text(
                        endDate == null
                            ? 'Date fin'
                            : DateFormat('dd/MM/yyyy').format(endDate!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Quantité exacte',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  exactQuantity = int.tryParse(val.trim());
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    onPressed: () {
                      productFilter = '';
                      startDate = null;
                      endDate = null;
                      exactQuantity = null;
                      setModalState(() {});
                      onFilterChanged('', null, null, null);
                      Navigator.pop(context);
                    },
                    child: const Text('Réinitialiser'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onFilterChanged(
                        productFilter,
                        startDate,
                        endDate,
                        exactQuantity,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Appliquer'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
} // TODO Implement this library.
