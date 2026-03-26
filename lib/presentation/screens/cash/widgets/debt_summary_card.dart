import 'package:flutter/material.dart';
import '/../../core/utils/formatters.dart';
import '/../../data/models/cash_models.dart';
import '/../../core/constants/app_colors.dart';

class DebtSummaryCard extends StatelessWidget {
  final List<DebtInfo> customerDebts;
  final List<DebtInfo> supplierDebts;

  const DebtSummaryCard({
    super.key,
    required this.customerDebts,
    required this.supplierDebts,
  });

  double get totalCustomerDebt =>
      customerDebts.fold(0, (sum, d) => sum + d.amount);

  double get totalSupplierDebt =>
      supplierDebts.fold(0, (sum, d) => sum + d.amount);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: Colors.purple.shade700,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'État des Créances & Dettes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Clients qui nous doivent
            _buildDebtSection(
              title: 'Clients qui nous doivent',
              icon: Icons.arrow_circle_up,
              color: Colors.orange,
              count: customerDebts.length,
              amount: totalCustomerDebt,
              onTap: () => _showDebtDetail(context, 'Clients', customerDebts),
            ),
            const Divider(height: 24),
            // Fournisseurs à payer
            _buildDebtSection(
              title: 'Fournisseurs à payer',
              icon: Icons.arrow_circle_down,
              color: Colors.blue,
              count: supplierDebts.length,
              amount: totalSupplierDebt,
              onTap: () =>
                  _showDebtDetail(context, 'Fournisseurs', supplierDebts),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSection({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required double amount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.lightGreenAccent.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${count > 1 ? 'personnes' : 'personne'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCompactCurrency(amount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 191, 168, 168),
                  ),
                ),
                Text(
                  'F CFA',
                  style: TextStyle(
                    fontSize: 9,
                    color: const Color.fromARGB(255, 109, 233, 189),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  void _showDebtDetail(
    BuildContext context,
    String title,
    List<DebtInfo> debts,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text('${debts.length}'),
                      backgroundColor: Colors.purple.shade100,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: debts.length,
                  itemBuilder: (context, index) {
                    final debt = debts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: debt.type == 'customer'
                            ? Colors.orange.shade100
                            : Colors.blue.shade100,
                        child: Icon(
                          debt.type == 'customer'
                              ? Icons.person
                              : Icons.business,
                          color: debt.type == 'customer'
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        debt.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${debt.phone ?? 'Pas de téléphone'} • ${_formatDate(debt.date)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatCompactCurrency(debt.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: debt.type == 'customer'
                                  ? Colors.orange.shade800
                                  : Colors.blue.shade800,
                            ),
                          ),
                          Text(
                            'F CFA',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return "Hier";
    if (diff < 7) return "Il y a $diff jours";
    return "${date.day}/${date.month}/${date.year}";
  }
}
