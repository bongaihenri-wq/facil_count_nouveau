import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/super_admin_repository.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/password_reset_request_model.dart';
import '../../data/models/user_model.dart';

final superAdminRepositoryProvider =
    Provider<SuperAdminRepository>((ref) => SuperAdminRepository());

final superAdminStatsProvider = FutureProvider<Map<String, int>>((ref) =>
    ref.watch(superAdminRepositoryProvider).getStats());

final pendingPaymentsProvider = FutureProvider<List<PaymentModel>>((ref) =>
    ref.watch(superAdminRepositoryProvider).getPendingPayments());

final pendingResetRequestsProvider =
    FutureProvider<List<PasswordResetRequestModel>>((ref) =>
        ref.watch(superAdminRepositoryProvider).getPendingResetRequests());

final allUsersProvider = FutureProvider<List<UserModel>>((ref) =>
    ref.watch(superAdminRepositoryProvider).getAllUsers());