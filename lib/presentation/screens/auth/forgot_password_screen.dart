import 'package:flutter/material.dart';
import '../../../data/repositories/super_admin_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  final _repo = SuperAdminRepository();
  bool _sent = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final found = await _repo.submitResetRequest(_phoneCtrl.text.trim());
      if (!found) throw Exception('Numéro introuvable');
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.lock_reset, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          if (!_sent) ...[
            const Text(
              'Entrez votre numéro de téléphone. Un administrateur validera votre demande et vous communiquera un mot de passe temporaire.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Envoyer la demande'),
            ),
          ] else ...[
            const Icon(Icons.mark_email_read, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              '📨 Demande envoyée !\n\nContactez l\'administrateur pour recevoir votre mot de passe temporaire.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour à la connexion'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 100), // padding bas pour navigation
        ]),
      ),
    );
  }
}