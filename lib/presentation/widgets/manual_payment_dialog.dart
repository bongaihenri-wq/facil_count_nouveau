import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/payment_service.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/super_admin_repository.dart';

class ManualPaymentDialog extends ConsumerStatefulWidget {
  final SubscriptionType planType;
  final String planTitle;
  final String amount;

  const ManualPaymentDialog({
    super.key,
    required this.planType,
    required this.planTitle,
    required this.amount,
  });

  @override
  ConsumerState<ManualPaymentDialog> createState() => _ManualPaymentDialogState();
}

class _ManualPaymentDialogState extends ConsumerState<ManualPaymentDialog> {
  final _refController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _refController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_refController.text.trim().isEmpty) {
      setState(() => _error = 'Entrez la référence du transfert');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final userId = await SecureStorageService.getUserId();
      if (userId == null) throw Exception('Session expirée, reconnectez-vous');

      // 🆕 Récupère business_id directement (évite l'incompatibilité BusinessHelper/WidgetRef)
      final userData = await Supabase.instance.client
          .from('users')
          .select('business_id')
          .eq('id', userId)
          .single();
      final bId = userData['business_id'] as String;

      await SuperAdminRepository().insertPendingPayment(
        businessId: bId,
        userId: userId,
        planType: widget.planType.name,
        amount: PaymentService.getPrice(widget.planType),
        method: 'manual',
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        reference: _refController.text.trim(),
      );

      if (mounted) {
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
    return AlertDialog(
      title: Text("Paiement Forfait ${widget.planTitle}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1. Effectuez le transfert de :",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("${widget.amount} CFA",
                style: const TextStyle(
                    fontSize: 20, color: Colors.orange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text("2. Vers l'un des numéros suivants :"),
            const Text("• Orange : 07 49 63 55 22"),
            const Text("• MTN : 05 06 43 29 43"),
            const SizedBox(height: 15),
            const Text("3. Votre numéro (qui a payé) :",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "Ex: 0749635522",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            const Text("4. Référence du transfert :",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _refController,
              decoration: const InputDecoration(
                hintText: "Ex: PP230415.1234.C45678",
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text("Envoyer",
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}