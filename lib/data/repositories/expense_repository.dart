import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';
import '../../core/utils/business_helper.dart';

class ExpenseRepository {
  final SupabaseClient _client;
  final BusinessHelper _businessHelper;

  ExpenseRepository(this._client, this._businessHelper);

  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    final businessId = await _businessHelper.getBusinessId();  // ← AJOUTÉ
    
    var query = _client.from('expenses').select()
        .eq('business_id', businessId);  // ← AJOUTÉ ICI

    if (startDate != null) {
      query = query.gte('expenses_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('expenses_date', endDate.toIso8601String());
    }

    final data = await query.order('expenses_date', ascending: false);

    var expenses = (data as List<dynamic>)
        .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      expenses = expenses
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              (e.recipient?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return expenses;
  }

  Future<ExpenseModel> addExpense({
    required String name,
    required double amount,
    String? recipient,
    String? invoiceNumber,
    required DateTime expensesDate,
    bool locked = false,
  }) async {
    final businessId = await _businessHelper.getBusinessId();

    final data = await _client
        .from('expenses')
        .insert({
          'name': name,
          'amount': amount,
          'recipient': recipient,
          'invoice_number': invoiceNumber,
          'expenses_date': expensesDate.toIso8601String(),
          'locked': locked,
          'business_id': businessId,
        })
        .select()
        .single();

    return ExpenseModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ExpenseModel> updateExpense(
    String id, {
    required String name,
    required double amount,
    String? recipient,
    String? invoiceNumber,
    required DateTime expensesDate,
    required bool locked,
  }) async {
    final data = await _client
        .from('expenses')
        .update({
          'name': name,
          'amount': amount,
          'recipient': recipient,
          'invoice_number': invoiceNumber,
          'expenses_date': expensesDate.toIso8601String(),
          'locked': locked,
        })
        .eq('id', id)
        .select()
        .single();

    return ExpenseModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }

  Future<Map<String, dynamic>> getMonthlyStats() async {
    final businessId = await _businessHelper.getBusinessId();
    final response = await _client.rpc('get_expense_stats', params: {
      'p_business_id': businessId,
    });
    return response as Map<String, dynamic>;
  }
}