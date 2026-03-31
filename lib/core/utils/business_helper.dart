// lib/core/utils/business_helper.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/auth_provider.dart';

final businessHelperProvider = Provider<BusinessHelper>((ref) {
  return BusinessHelper(ref);
});

class BusinessHelper {
  final Ref _ref;
  String? _cachedBusinessId;

  BusinessHelper(this._ref);

  Future<String> getBusinessId() async {
    if (_cachedBusinessId != null) return _cachedBusinessId!;

    final authState = _ref.read(authProvider);
    final businessId = authState.businessId;

    print('🔍 BusinessHelper - AuthState businessId: $businessId');

    if (businessId == null || businessId.isEmpty) {
      throw Exception('User sans business_id dans AuthProvider');
    }

    _cachedBusinessId = businessId;
    return businessId;
  }

  void clearCache() => _cachedBusinessId = null;
}