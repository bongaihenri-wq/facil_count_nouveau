import 'package:flutter/material.dart';

class ProductRanking extends StatelessWidget {
  final List<Map<String, dynamic>> topProducts; // 👈 AJOUTÉ ICI

  const ProductRanking({super.key, required this.topProducts}); // 👈 AJOUTÉ ICI

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top 5 - Produits les plus vendus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          if (topProducts.isEmpty)
            const Center(child: Text('Aucune vente enregistrée'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = topProducts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text('#${index + 1}', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(item['name']),
                  trailing: Text('${item['qty'].toInt()} unités', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
        ],
      ),
    );
  }
}