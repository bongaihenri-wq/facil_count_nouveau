import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

/// Écran forcé après connexion avec mot de passe temporaire
class ChangePasswordScreen extends StatefulWidget {
  final String phoneNumber;
  const ChangePasswordScreen({super.key, required this.phoneNumber});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _save() async {
    if (_newCtrl.text.length < 6) {
      setState(() => _error = 'Minimum 6 caractères');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().changePassword(widget.phoneNumber, _newCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Mot de passe mis à jour !')));
        Navigator.of(context).pop(); // Retour au login pour se reconnecter
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🚫 Interdit de revenir en arrière
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.lock_person,
                            size: 56, color: Colors.deepPurple),
                        const SizedBox(height: 12),
                        const Text('Changement de mot de passe',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          'Vous avez utilisé un mot de passe temporaire. Définissez votre nouveau mot de passe.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _newCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Nouveau mot de passe',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _loading ? null : _save,
                          child: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}