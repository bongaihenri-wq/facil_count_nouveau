// lib/core/utils/business_helper.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/auth_provider.dart';

final businessHelperProvider = Provider<BusinessHelper>((ref) {
  return BusinessHelper(ref);
});

class BusinessHelper {
  final Ref _ref;

  BusinessHelper(this._ref);

  Future<String> getBusinessId() async {
    final authState = _ref.read(authProvider);
    final businessId = authState.businessId;

    print('🔍 BusinessHelper - businessId depuis authProvider: $businessId');
    print('🔍 BusinessHelper - currentUser: ${authState.currentUser?.id}');

    if (businessId == null || businessId.isEmpty) {
      throw Exception('Pas de business_id - utilisateur non connecté');
    }

    return businessId;
  }
}