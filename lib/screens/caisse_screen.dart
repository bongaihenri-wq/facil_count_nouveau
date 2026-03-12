import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CaisseScreen extends StatefulWidget {
  const CaisseScreen({super.key});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen> {
  String _selectedFilter = 'Aujourd\'hui';

  // Données hardcodées caisse (exemple simple)
  final Map<String, dynamic> _caisseSummary = {
    'today': {'entrees': 850000, 'sorties': 320000, 'solde': 530000},
    'week': {'entrees': 3200000, 'sorties': 1450000, 'solde': 1750000},
    'month': {'entrees': 12850000, 'sorties': 6200000, 'solde': 6650000},
  };

  String formatCFA(int amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} F CFA';
  }

  @override
  Widget build(BuildContext context) {
    final data =
        _caisseSummary[_selectedFilter.toLowerCase()] ??
        _caisseSummary['today']!;

    return Scaffold(
      appBar: AppBar(title: const Text('Caisse')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtres : Aujourd'hui / Semaine / Mois
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Aujourd\'hui', 'Semaine', 'Mois'].map((filter) {
                final bool isSelected = filter == _selectedFilter;
                return FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (bool value) {
                    if (value) setState(() => _selectedFilter = filter);
                  },
                  selectedColor: Colors.indigo[700],
                  backgroundColor: Colors.grey[300],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Résumé caisse
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solde actuel ($_selectedFilter)',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatCFA(data['solde']),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: data['solde'] >= 0
                            ? Colors.green[800]
                            : Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Entrées',
                              style: TextStyle(color: Colors.green),
                            ),
                            Text(
                              formatCFA(data['entrees']),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sorties',
                              style: TextStyle(color: Colors.red),
                            ),
                            Text(
                              formatCFA(data['sorties']),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Historique caisse (exemple simple)
            const Text(
              'Mouvements récents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.arrow_circle_up,
                      color: Colors.green,
                    ),
                    title: const Text('Vente téléphone'),
                    subtitle: const Text('Aujourd\'hui 14:30'),
                    trailing: Text(
                      '+150 000 F CFA',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.arrow_circle_down,
                      color: Colors.red,
                    ),
                    title: const Text('Paiement loyer'),
                    subtitle: const Text('Aujourd\'hui 09:15'),
                    trailing: Text(
                      '-150 000 F CFA',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Ajoute plus si besoin
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mouvement caisse (à venir)')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
