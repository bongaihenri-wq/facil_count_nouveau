import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/purchase_model.dart'; // Assure-toi que ce modèle existe
import '../../core/utils/business_helper.dart';
import '../../presentation/providers/product_provider.dart';

class PurchaseRepository {
  final SupabaseClient _client;
  final BusinessHelper _businessHelper;
  final Ref _ref;

  PurchaseRepository(this._client, this._businessHelper, this._ref);

  /// 🌐 EN LIGNE : Récupère tous les achats directement depuis Supabase
  /// ⭐ Identique à Sales : Filtres de dates optionnels
  Future<List<PurchaseModel>> getPurchases({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final businessId = await _businessHelper.getBusinessId();
    
    if (businessId.isEmpty) {
      print('❌ ERREUR: business_id est vide !');
      return [];
    }

    try {
      print('🌐 Supabase - Récupération des achats en direct...');
      
      // On commence à construire notre requête de base
      var query = _client
          .from('purchases')
          .select('*, products(name)')
          .eq('business_id', businessId);

      // 📅 FILTRE : Date supérieure ou égale à startDate
      if (startDate != null) {
        query = query.gte('purchase_date', startDate.toIso8601String());
      }

      // 📅 FILTRE : Date inférieure ou égale à endDate
      if (endDate != null) {
        query = query.lte('purchase_date', endDate.toIso8601String());
      }

      // On applique le tri et on attend la réponse
      final response = await query.order('purchase_date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((json) {
        final Map<String, dynamic> purchaseMap = Map<String, dynamic>.from(json);
        if (purchaseMap['products'] != null) {
          purchaseMap['product_name'] = purchaseMap['products']['name'];
        }
        return PurchaseModel.fromJson(purchaseMap);
      }).toList();
      
    } catch (e) {
      print('❌ Erreur getPurchases() Supabase: $e');
      return [];
    }
  }

  /// 🌐 EN LIGNE : Crée un achat directement sur Supabase
  Future<PurchaseModel> createPurchase({
    required String productId,
    required int quantity,
    required double amount,
    String? supplierId, // Adapté : fournisseur au lieu de client
    required DateTime purchaseDate,
    bool paid = true,
    bool locked = false,
  }) async {
    final businessId = await _businessHelper.getBusinessId();

    try {
      print('🌐 Supabase - Envoi direct de l\'achat...');
      
      final payload = {
        'id': const Uuid().v4(),
        'business_id': businessId,
        'product_id': productId,
        'quantity': quantity,
        'amount': amount,
        'supplier_id': supplierId, // On utilise supplier_id s'il existe dans ta bdd
        'purchase_date': purchaseDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'paid': paid,
        'locked': locked,
      };

      print('📦 Tentative d\'envoi du payload: $payload');

      final data = await _client
          .from('purchases')
          .insert(payload)
          .select('*, products(name)') 
          .single(); 

      print('✅ Achat enregistré avec succès dans Supabase !');

      final Map<String, dynamic> responseMap = Map<String, dynamic>.from(data);
      if (responseMap['products'] != null) {
        responseMap['product_name'] = responseMap['products']['name'];
      }

      // ⭐ CRUCIAL : On invalide les produits pour forcer l'actualisation du stock
      _ref.invalidate(productsProvider); 
      
      return PurchaseModel.fromJson(responseMap);
      
    } catch (e) {
      print('❌ ERREUR CRÉATION ACHAT SUPABASE: $e');
      throw Exception('Échec création achat: $e');
    }
  }

  /// 🌐 EN LIGNE : Modifie un achat
  Future<PurchaseModel> updatePurchase({
    required String id,
    required String productId,
    required int quantity,
    required double amount,
    String? supplierId,
    required DateTime purchaseDate,
    bool paid = true,
    bool locked = false,
  }) async {
    final businessId = await _businessHelper.getBusinessId();

    try {
      final data = await _client
          .from('purchases')
          .update({
            'product_id': productId,
            'quantity': quantity,
            'amount': amount,
            'supplier_id': supplierId,
            'purchase_date': purchaseDate.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('business_id', businessId)
          .select('*, products(name)')
          .single();

      final Map<String, dynamic> responseMap = Map<String, dynamic>.from(data);
      if (responseMap['products'] != null) {
        responseMap['product_name'] = responseMap['products']['name'];
      }

      _ref.invalidate(productsProvider); 
      return PurchaseModel.fromJson(responseMap);
    } catch (e) {
      print('❌ ERREUR UPDATE ACHAT: $e');
      throw Exception('Échec modification achat: $e');
    }
  }

  /// 🌐 EN LIGNE : Supprime un achat
  Future<void> deletePurchase(String id) async {
    final businessId = await _businessHelper.getBusinessId();

    try {
      await _client
          .from('purchases')
          .delete()
          .eq('id', id)
          .eq('business_id', businessId);
          
      _ref.invalidate(productsProvider); 
      
    } catch (e) {
      print('❌ ERREUR DELETE ACHAT: $e');
      throw Exception('Échec suppression achat: $e');
    }
  }
}
