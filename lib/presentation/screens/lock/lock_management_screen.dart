import 'package:flutter/material.dart';
import '../../../data/repositories/lock_repository.dart';

class LockManagementScreen extends StatefulWidget {
  const LockManagementScreen({super.key});

  @override
  State<LockManagementScreen> createState() => _LockManagementScreenState();
}

class _LockManagementScreenState extends State<LockManagementScreen> {
  String _actionType = 'Ventes';
  bool _lock = true; // true = verrouiller
  bool _isDayScope = true;
  DateTime _day = DateTime.now();
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  final _noteController = TextEditingController();
  final _repo = LockRepository();
  bool _loading = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final events = await _repo.getLockEvents();
      if (mounted) setState(() => _history = events);
    } catch (_) {}
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  DateTime get _rangeFrom => _isDayScope
      ? DateTime(_day.year, _day.month, _day.day)
      : DateTime(_from.year, _from.month, _from.day);

  DateTime get _rangeTo => _isDayScope
      ? DateTime(_day.year, _day.month, _day.day).add(const Duration(days: 1))
      : DateTime(_to.year, _to.month, _to.day).add(const Duration(days: 1));

  Future<void> _apply() async {
    setState(() => _loading = true);
    try {
      final count = await _repo.bulkLockUnlock(
        actionType: _actionType,
        lock: _lock,
        from: _rangeFrom,
        to: _rangeTo,
        scope: _isDayScope ? 'day' : 'period',
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ $count ${_actionType.toLowerCase()} ${_lock ? "verrouillées" : "déverrouillées"}'),
        ));
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // L'écran est accessible depuis le TDB admin uniquement
    return Scaffold(
      appBar: AppBar(title: const Text('Verrouillage des actions')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Choix du type d'action
        DropdownButtonFormField<String>(
          value: _actionType,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Type d\'action', border: OutlineInputBorder()),
          items: ['Ventes', 'Achats', 'Dépenses', 'Factures']
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _actionType = v!),
        ),
        const SizedBox(height: 16),

        // Verrouiller / Déverrouiller
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('🔒 Verrouiller'),
                icon: Icon(Icons.lock)),
            ButtonSegment(value: false, label: Text('🔓 Déverrouiller'),
                icon: Icon(Icons.lock_open)),
          ],
          selected: {_lock},
          onSelectionChanged: (s) => setState(() => _lock = s.first),
        ),
        const SizedBox(height: 16),

        // Jour / Période
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Un jour')),
            ButtonSegment(value: false, label: Text('Une période')),
          ],
          selected: {_isDayScope},
          onSelectionChanged: (s) => setState(() => _isDayScope = s.first),
        ),
        const SizedBox(height: 12),

        if (_isDayScope)
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text('Date : ${_day.day}/${_day.month}/${_day.year}'),
            onPressed: () async {
              final p = await showDatePicker(
                context: context, initialDate: _day,
                firstDate: DateTime(2024), lastDate: DateTime(2030));
              if (p != null) setState(() => _day = p);
            },
          )
        else
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text('Du : ${_from.day}/${_from.month}'),
                onPressed: () => _pickDate(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text('Au : ${_to.day}/${_to.month}'),
                onPressed: () => _pickDate(false),
              ),
            ),
          ]),
        const SizedBox(height: 16),

        // Note de point de contrôle
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Note de point de contrôle (optionnel)',
            hintText: 'Ex: Point de contrôle du 02/10 — écart caisse : 0 FCFA',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _lock ? Colors.orange.shade700 : Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(_lock ? Icons.lock : Icons.lock_open),
          label: Text(_lock
              ? 'Verrouiller les $_actionType de la ${_isDayScope ? "journée" : "période"}'
              : 'Déverrouiller (admin)'),
          onPressed: _loading ? null : _apply,
        ),
        if (!_lock)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('⚠️ Le déverrouillage est réservé à l\'administrateur et est tracé.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
          ),

        const Divider(height: 40),

        // Registre des clôtures
        const Text('📜 Registre des clôtures',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (_history.isEmpty)
          const Text('Aucune clôture enregistrée',
              style: TextStyle(color: Colors.grey))
        else
          ..._history.map((e) {
            final op = e['operation'] == 'lock';
            final df = DateTime.tryParse(e['date_from']?.toString() ?? '')?.toLocal();
            final dt = DateTime.tryParse(e['date_to']?.toString() ?? '')?.toLocal();
            final dateStr = e['scope'] == 'single'
                ? (df != null ? '${df.day}/${df.month}/${df.year}' : '-')
                : '${df?.day}/${df?.month} → ${dt?.day}/${dt?.month}';
            return Card(
              child: ListTile(
                dense: true,
                leading: Icon(op ? Icons.lock : Icons.lock_open,
                    color: op ? Colors.orange : Colors.green, size: 20),
                title: Text('${e['action_type']} — ${op ? "Verrouillé" : "Déverrouillé"}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '$dateStr • ${e['operator_role'] ?? ''}${e['note'] != null ? '\n📝 ${e['note']}' : ''}',
                    style: const TextStyle(fontSize: 12)),
              ),
            );
          }),
        const SizedBox(height: 80),
      ]),
    );
  }
}