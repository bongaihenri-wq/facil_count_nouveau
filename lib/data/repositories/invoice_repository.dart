import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_model.dart';


class InvoiceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Récupérer toutes les factures (Filtrées par Business ID)
  Future<List<InvoiceModel>> getInvoices(String businessId) async {
    try {
      print('🔍 REPOSITORY - Tentative de lecture pour le businessId: "$businessId"');

      // 🟢 On a retiré le blocage du "userId == null" qui arrêtait tout !
      final response = await _supabase
          .from('invoices')
          .select()
          .eq('business_id', businessId) 
          .order('created_at', ascending: false);
          
      print('📊 REPOSITORY - Nombre de factures récupérées depuis Supabase: ${response.length}');
      
      return (response as List)
          .map((json) => InvoiceModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ REPOSITORY - Erreur lors de la récupération : $e');
      throw Exception('Erreur lors de la récupération des factures : $e');
    }
  }

  // 2. Créer une facture
  Future<void> createInvoice(InvoiceModel invoice) async {
    try {
      final json = invoice.toJson();
      // On retire l'ID pour laisser Supabase le générer automatiquement
      json.remove('id'); 
      
      await _supabase.from('invoices').insert(json);
    } catch (e) {
      throw Exception('Erreur lors de la création de la facture : $e');
    }
  }

  // 3. Modifier une facture
  Future<void> updateInvoice(InvoiceModel invoice) async {
    try {
      await _supabase
          .from('invoices')
          .update(invoice.toJson())
          .eq('id', invoice.id);
    } catch (e) {
      throw Exception('Erreur lors de la modification de la facture : $e');
    }
  }

  // 4. Supprimer une facture
  Future<void> deleteInvoice(String id) async {
    try {
      await _supabase.from('invoices').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la facture : $e');
    }
  }

  // 5. Upload de l'image (dans un bucket nommé 'invoices')
  Future<String> uploadImage(File file, String fileName) async {
    try {
      final storage = _supabase.storage.from('invoices');
      
      // Envoi du fichier
      await storage.upload(fileName, file);
      
      // Récupération de l'URL publique
      final publicUrl = storage.getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image : $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final storage = _supabase.storage.from('invoices');
      
      // On extrait le nom du fichier depuis l'URL publique
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      
      await storage.remove([fileName]);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'image : $e');
    }
  }
}