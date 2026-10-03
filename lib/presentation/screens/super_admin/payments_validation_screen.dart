import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/super_admin_provider.dart';

class PaymentsValidationScreen extends ConsumerStatefulWidget {
  const PaymentsValidationScreen({super.key});

  @override
  ConsumerState<PaymentsValidationScreen> createState() =>
      _PaymentsValidationScreenState();
}

class _PaymentsValidationScreenState
    extends ConsumerState<PaymentsValidationScreen> {
  int _year = DateTime.now().year;
  int? _month;
  String _search = '';
  List<PaymentModel> _payments = [];
  bool _loading = true;
  String? _error; // 🆕 Erreur affichée au lieu d'écran vide silencieux

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
          .getPayments(month: _month, year: _year);
      if (mounted) {
        setState(() { _payments = list; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = e.toString(); });
      }
    }
  }

  List<PaymentModel> get _filtered {
    if (_search.isEmpty) return _payments;
    final q = _search.toLowerCase();
    return _payments.where((p) =>
        (p.businessCode ?? '').toLowerCase().contains(q) ||
        (p.phoneNumber ?? '').toLowerCase().contains(q) ||
        (p.reference ?? '').toLowerCase().contains(q)).toList();
  }

  double get _totalValidated =>
      _filtered.where((p) => p.status == 'validated').fold(0.0, (s, p) => s + p.amount);
  double get _totalPending =>
      _filtered.where((p) => p.status == 'pending').fold(0.0, (s, p) => s + p.amount);

  Future<void> _validate(PaymentModel p) async {
    final validatorId = await SecureStorageService.getUserId();
    if (validatorId == null) return;
    try {
      await ref.read(superAdminRepositoryProvider).validatePayment(p.id, validatorId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Paiement validé — compte réactivé automatiquement')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _reject(PaymentModel p) async {
    final validatorId = await SecureStorageService.getUserId();
    if (validatorId == null) return;
    await ref.read(superAdminRepositoryProvider).rejectPayment(p.id, validatorId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements')),
      body: Column(children: [
        // Filtres
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
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
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher: code boutique, téléphone, référence',
                prefixIcon: Icon(Icons.search), border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ]),
        ),

        // Totaux
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green)),
          child: Row(children: [
            Expanded(child: Column(children: [
              const Text('Validé', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${_totalValidated.toStringAsFixed(0)} XOF',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
            ])),
            Container(width: 1, height: 30, color: Colors.grey.shade300),
            Expanded(child: Column(children: [
              const Text('En attente', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${_totalPending.toStringAsFixed(0)} XOF',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
            ])),
          ]),
        ),

        // 🆕 Erreur affichée (diagnostic)
        if (_error != null)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8)),
            child: Text('⚠️ $_error',
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),

        // Liste
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? const SizedBox.shrink()
                  : _filtered.isEmpty
                      ? const Center(child: Text('Aucun paiement sur cette période'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _paymentCard(_filtered[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _paymentCard(PaymentModel p) {
    final statusColor = p.status == 'validated'
        ? Colors.green
        : (p.status == 'pending' ? Colors.orange : Colors.red);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                '${p.planType.toUpperCase()} — ${p.amount.toStringAsFixed(0)} ${p.currency}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
              child: Text(p.status, style: TextStyle(color: statusColor, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Tél payeur: ${p.phoneNumber ?? '-'}  •  Code: ${p.businessCode ?? '-'}'),
          // 🆕 RÉFÉRENCE EN ÉVIDENCE
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300)),
            child: Row(children: [
              const Icon(Icons.receipt_long, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Réf: ${p.reference ?? '—'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
              ),
            ]),
          ),
          Text('Le: ${p.createdAt.toLocal().toString().substring(0, 16)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (p.status == 'pending') ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Valider', style: TextStyle(color: Colors.white)),
                  onPressed: () => _validate(p),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                  onPressed: () => _reject(p),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}