import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/invoice_model.dart';
import '../../../core/utils/business_helper.dart';

class InvoiceRepository {
  final SupabaseClient _client;
  final BusinessHelper _businessHelper;

  InvoiceRepository(this._client, this._businessHelper);

  String get _table => 'invoices';

  // ✅ CORRIGÉ : Utilise directement BusinessHelper avec retry
  Future<String> _getBusinessId() async {
    // Réessayer plusieurs fois si nécessaire (max 3 secondes)
    int attempts = 0;
    Exception? lastError;
    
    while (attempts < 30) {
      try {
        final businessId = await _businessHelper.getBusinessId();
        if (businessId.isNotEmpty) return businessId;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        // Attendre un peu avant de réessayer
        await Future.delayed(const Duration(milliseconds: 100));
      }
      attempts++;
    }
    
    // Si toujours pas trouvé, lever l'erreur
    throw lastError ?? Exception('Impossible de récupérer le Business ID');
  }

  Future<List<InvoiceModel>> getInvoices() async {
    final businessId = await _getBusinessId();
    
    final response = await _client
        .from(_table)
        .select()
        .eq('business_id', businessId)
        .order('invoice_date', ascending: false);

    return (response as List)
        .map((json) => InvoiceModel.fromJson(json))
        .toList();
  }

  Future<InvoiceModel> getInvoiceById(String id) async {
    final businessId = await _getBusinessId();
    
    final response = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('business_id', businessId)
        .single();

    return InvoiceModel.fromJson(response);
  }

  Future<void> createInvoice(InvoiceModel invoice) async {
    final businessId = await _getBusinessId();
    
    await _client.from(_table).insert({
      'type': invoice.type,
      'number': invoice.number,
      'invoice_date': invoice.invoiceDate.toIso8601String(),
      'amount': invoice.amount,
      'status': invoice.status,
      'image_url': invoice.imageUrl,
      'supplier': invoice.supplier,
      'notes': invoice.notes,
      'locked': invoice.locked,
      'business_id': businessId,
    });
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    final businessId = await _getBusinessId();
    
    await _client
        .from(_table)
        .update({
          'type': invoice.type,
          'number': invoice.number,
          'invoice_date': invoice.invoiceDate.toIso8601String(),
          'amount': invoice.amount,
          'status': invoice.status,
          'image_url': invoice.imageUrl,
          'supplier': invoice.supplier,
          'notes': invoice.notes,
          'locked': invoice.locked,
        })
        .eq('id', invoice.id)
        .eq('business_id', businessId);
  }

  Future<void> deleteInvoice(String id) async {
    final businessId = await _getBusinessId();
    
    await _client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('business_id', businessId);
  }

  Future<void> updateStatus(String id, String status) async {
    final businessId = await _getBusinessId();
    
    await _client
        .from(_table)
        .update({'status': status})
        .eq('id', id)
        .eq('business_id', businessId);
  }

  Future<String?> uploadImage(File file, String fileName) async {
    try {
      final businessId = await _getBusinessId();
      final path = '$businessId/invoices/$fileName';
      
      await _client.storage
          .from('factures')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      
      return _client.storage.from('factures').getPublicUrl(path);
    } catch (e) {
      print('Erreur upload image: $e');
      return null;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final path = imageUrl.split('/factures/').last;
      await _client.storage.from('factures').remove([path]);
    } catch (e) {
      print('Erreur suppression image: $e');
    }
  }
}
