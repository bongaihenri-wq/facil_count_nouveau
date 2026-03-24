import 'package:flutter/material.dart';
import 'package:facil_count_nouveau/core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String _phoneNumber = '';
  String _password = '';
  String _businessName = '';
  String _businessType = 'produits';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nom du commerce',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le nom du commerce';
                    }
                    return null;
                  },
                  onSaved: (value) => _businessName = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _businessType,
                  decoration: const InputDecoration(
                    labelText: 'Type de commerce',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'produits',
                      child: Text('Vente de produits'),
                    ),
                    DropdownMenuItem(
                      value: 'services',
                      child: Text('Vente de services'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _businessType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un numéro de téléphone';
                    }
                    return null;
                  },
                  onSaved: (value) => _phoneNumber = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value!,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('S\'inscrire'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      await _authService.registerUser(
        phoneNumber: _phoneNumber,
        password: _password,
        businessName: _businessName,
        businessType: _businessType,
        isAdmin: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Inscription réussie!')));
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
