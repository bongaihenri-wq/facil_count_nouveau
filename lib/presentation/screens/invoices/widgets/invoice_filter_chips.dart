import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/presentation/providers/invoice_provider.dart';

class InvoiceFilterChips extends ConsumerWidget {
  const InvoiceFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(invoiceTypeFilterProvider);
    
    final types = ['Tous', 'Achats', 'Ventes', 'Dépenses'];
    final colors = {
      'Tous': Colors.purple,
      'Achats': Colors.blue,
      'Ventes': Colors.green,
      'Dépenses': Colors.orange,
    };

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = type == selectedType;
          final color = colors[type]!;

          return ChoiceChip(
            label: Text(type),
            selected: isSelected,
            onSelected: (_) {
              ref.read(invoiceTypeFilterProvider.notifier).state = type;
            },
            selectedColor: color.shade100,
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color: isSelected ? color.shade700 : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? color.shade300 : Colors.transparent,
              ),
            ),
          );
        },
      ),
    );
  }
}
