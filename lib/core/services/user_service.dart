import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:facil_count_nouveau/data/models/user_model.dart' as user_model;

class UserService {
  final supabase = Supabase.instance.client;

  Future<List<user_model.User>> getUsersByBusiness(String businessId) async {
    final res = await supabase
        .from('users')
        .select()
        .eq('businessId', businessId);

    return (res as List).map((user) => user_model.User.fromMap(user)).toList();
  }

  Future<void> lockUser(String userId, bool locked) async {
    await supabase.from('users').update({'isActive': !locked}).eq('id', userId);
  }

  Future<bool> verifyAdminPassword(String adminId, String password) async {
    final admin = await supabase
        .from('users')
        .select()
        .eq('id', adminId)
        .eq('password', password)
        .maybeSingle();

    return admin != null;
  }
}
