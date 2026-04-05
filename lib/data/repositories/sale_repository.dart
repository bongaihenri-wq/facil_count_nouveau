import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import '../../core/utils/business_helper.dart';
import '../../presentation/providers/product_provider.dart';

class SaleRepository {
  final SupabaseClient _client;
  final BusinessHelper _businessHelper;
  final Ref _ref;

  SaleRepository(this._client, this._businessHelper, this._ref);

  /// 🌐 EN LIGNE : Récupère toutes les ventes directement depuis Supabase
  // ⭐ MODIFIÉ : Ajout des paramètres de date optionnels
  Future<List<SaleModel>> getSales({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final businessId = await _businessHelper.getBusinessId();
    
    if (businessId.isEmpty) {
      print('❌ ERREUR: business_id est vide !');
      return [];
    }

    try {
      print('🌐 Supabase - Récupération des ventes en direct...');
      
      // On commence à construire notre requête de base
      var query = _client
          .from('sales')
          .select('*, products(name), clients(name)')
          .eq('business_id', businessId);

      // 📅 FILTRE : Date supérieure ou égale à startDate
      if (startDate != null) {
        query = query.gte('sale_date', startDate.toIso8601String());
      }

      // 📅 FILTRE : Date inférieure ou égale à endDate
      if (endDate != null) {
        query = query.lte('sale_date', endDate.toIso8601String());
      }

      // On applique le tri et on attend la réponse
      final response = await query.order('sale_date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((json) {
        final Map<String, dynamic> saleMap = Map<String, dynamic>.from(json);
        if (saleMap['products'] != null) {
          saleMap['product_name'] = saleMap['products']['name'];
        }
        return SaleModel.fromJson(saleMap);
      }).toList();
      
    } catch (e) {
      print('❌ Erreur getSales() Supabase: $e');
      return [];
    }
  }

 /// 🌐 EN LIGNE : Crée une vente directement sur Supabase
  Future<SaleModel> createSale({
    required String productId,
    required int quantity,
    required double amount,
    String? clientId,
    required DateTime saleDate,
    bool isPaid = true, 
  }) async {
    final businessId = await _businessHelper.getBusinessId();

    try {
      print('🌐 Supabase - Envoi direct de la vente...');
      
      final payload = {
        'id': const Uuid().v4(),
        'business_id': businessId,
        'product_id': productId,
        'quantity': quantity,
        'amount': amount,
        'client_id': clientId,
        'sale_date': saleDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'paid': isPaid,
        'locked': false,
      };

      print('📦 Tentative d\'envoi du payload: $payload');

      final data = await _client
          .from('sales')
          .insert(payload)
          .select('*, products(name)') 
          .single(); 

      print('✅ Vente enregistrée avec succès dans Supabase !');

      final Map<String, dynamic> responseMap = Map<String, dynamic>.from(data);
      if (responseMap['products'] != null) {
        responseMap['product_name'] = responseMap['products']['name'];
      }

      print('✅ Vente enregistrée avec succès sur Supabase !');

      _ref.invalidate(productsProvider); 
      
      return SaleModel.fromJson(responseMap);
      
    } catch (e) {
      print('❌ ERREUR CRÉATION VENTE SUPABASE: $e');
      throw Exception('Échec création vente: $e');
    }
  }

  /// 🌐 EN LIGNE : Modifie une vente
  Future<SaleModel> updateSale({
    required String id,
    required String productId,
    required int quantity,
    required double amount,
    String? clientId,
    required DateTime saleDate,
    required bool isPaid,
    required bool locked,
  }) async {
    final businessId = await _businessHelper.getBusinessId();

    try {
      final data = await _client
          .from('sales')
          .update({
            'product_id': productId,
            'quantity': quantity,
            'amount': amount,
            'client_id': clientId,
            'sale_date': saleDate.toIso8601String(),
            'paid': isPaid,
            'locked': locked,
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

      return SaleModel.fromJson(responseMap);
    } catch (e) {
      print('❌ ERREUR UPDATE VENTE: $e');
      throw Exception('Échec modification vente: $e');
    }
  }

  /// 🌐 EN LIGNE : Supprime une vente
  Future<void> deleteSale(String id, String productId, int quantity) async {
    final businessId = await _businessHelper.getBusinessId();

    try {
      await _client
          .from('sales')
          .delete()
          .eq('id', id)
          .eq('business_id', businessId);
      
    } catch (e) {
      print('❌ ERREUR DELETE VENTE: $e');
      throw Exception('Échec suppression vente: $e');
    }
  }

  /// 🔄 Méthode conservée au cas où tu en aies besoin ailleurs
  Future<void> _updateProductStock(String productId, int quantityDelta, String businessId) async {
    final product = await _client
        .from('products')
        .select('initial_stock')
        .eq('id', productId)
        .eq('business_id', businessId)
        .single();

    final currentStock = (product['initial_stock'] as num).toInt();
    final newStock = currentStock + quantityDelta;

    if (newStock < 0) {
      throw Exception('Opération impossible : le stock deviendrait négatif ($newStock).');
    }

    await _client
        .from('products')
        .update({'initial_stock': newStock})
        .eq('id', productId)
        .eq('business_id', businessId);
  }
}
