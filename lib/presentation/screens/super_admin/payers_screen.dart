import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/super_admin_provider.dart';

class PayersScreen extends ConsumerStatefulWidget {
  const PayersScreen({super.key});

  @override
  ConsumerState<PayersScreen> createState() => _PayersScreenState();
}

class _PayersScreenState extends ConsumerState<PayersScreen> {
  int _year = DateTime.now().year;
  int? _month;
  List<Map<String, dynamic>> _payers = [];
  bool _loading = true;
  String? _error;

  static const _months = [
    'Tous', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ref
          .read(superAdminRepositoryProvider)
          .getPayers(month: _month, year: _year);
      if (mounted) setState(() { _payers = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  double get _total => _payers.fold(0.0, (s, p) => s + (p['total'] as double));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payeurs')),
      body: Column(children: [
        // Filtres
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _month, isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Mois', border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: List.generate(13,
                    (i) => DropdownMenuItem(value: i == 0 ? null : i, child: Text(_months[i]))),
                onChanged: (v) { setState(() => _month = v); _load(); },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _year, isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Année', border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: List.generate(5, (i) {
                  final y = DateTime.now().year - 2 + i;
                  return DropdownMenuItem(value: y, child: Text('$y'));
                }),
                onChanged: (v) { setState(() => _year = v!); _load(); },
              ),
            ),
          ]),
        ),

        // Total général
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            color: Colors.blue.shade50,
            child: ListTile(
              leading: const Icon(Icons.payments, color: Colors.blue),
              title: const Text('Total encaissé (période)'),
              trailing: Text('${_total.toStringAsFixed(0)} XOF',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('⚠️ $_error', style: const TextStyle(color: Colors.red)),
          ),

        // Liste des payeurs
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _payers.isEmpty
                  ? const Center(child: Text('Aucun payeur sur cette période'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _payers.length,
                        itemBuilder: (_, i) => _payerCard(_payers[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _payerCard(Map<String, dynamic> p) {
    final validated = p['validated'] as int;
    final pending = p['pending'] as int;
    final rejected = p['rejected'] as int;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p['businessName']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${p['phone']}  •  ${p['businessCode']}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ]),
            ),
            Text('${(p['total'] as double).toStringAsFixed(0)} XOF',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            _statusChip('✅ Validés: $validated', Colors.green),
            _statusChip('⏳ En attente: $pending', Colors.orange),
            if (rejected > 0) _statusChip('❌ Rejetés: $rejected', Colors.red),
            _statusChip(
                '📅 Dernier: ${(p['lastDate'] as DateTime).toLocal().toString().substring(0, 16)}',
                Colors.grey),
          ]),
        ]),
      ),
    );
  }

  Widget _statusChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(color: color, fontSize: 11)),
      );
}