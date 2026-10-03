import 'package:flutter/material.dart';
import '../../data/repositories/business_repository.dart';

class AddBusinessSheet extends StatefulWidget {
  const AddBusinessSheet({super.key});

  @override
  State<AddBusinessSheet> createState() => _AddBusinessSheetState();
}

class _AddBusinessSheetState extends State<AddBusinessSheet> {
  final _nameController = TextEditingController();
  String _type = 'produits';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Entrez le nom du commerce');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result =
          await BusinessRepository().addBusiness(_nameController.text.trim(), _type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Boutique créée ! Code: ${result['code']}'),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Ajouter une boutique',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du commerce',
              prefixIcon: Icon(Icons.store),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Type de commerce',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'produits', child: Text('Vente de produits')),
              DropdownMenuItem(value: 'services', child: Text('Vente de services')),
              DropdownMenuItem(value: 'mixte', child: Text('Mixte (produits + services)')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'produits'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Créer la boutique'),
          ),
        ],
      ),
    );
  }
}