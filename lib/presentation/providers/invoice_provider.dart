import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../core/utils/business_helper.dart'; // Vérifie bien ce chemin !

// 🟡 Fournit l'instance du Repository
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

// 🟡 Récupère la liste brute des factures depuis Supabase
final invoicesFutureProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  
  // On récupère le businessId via le helper
  final businessHelper = ref.read(businessHelperProvider);
  final businessId = await businessHelper.getBusinessId();
  
  // On passe l'ID attendu par getInvoices
  return repo.getInvoices(businessId);
});

// 🟡 Filtres d'états
final invoiceStatusFilterProvider = StateProvider<String?>((ref) => null);
final invoiceTypeFilterProvider = StateProvider<String?>((ref) => null);

// 🟡 Filtrage combiné des factures
final filteredInvoicesProvider = Provider<AsyncValue<List<InvoiceModel>>>((ref) {
  final invoicesAsync = ref.watch(invoicesFutureProvider);
  final statusFilter = ref.watch(invoiceStatusFilterProvider);
  final typeFilter = ref.watch(invoiceTypeFilterProvider);

  return invoicesAsync.whenData((invoices) {
    return invoices.where((invoice) {
      final matchesStatus = statusFilter == null || 
                            statusFilter == 'Tous' || 
                            invoice.status == statusFilter;
                            
      final matchesType = typeFilter == null || 
                          typeFilter == 'Tous' || 
                          invoice.type == typeFilter;
                          
      return matchesStatus && matchesType;
    }).toList();
  });
});

// 🟡 Calculateur de statistiques rapides
final invoiceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final invoicesAsync = ref.watch(filteredInvoicesProvider);
  
  return invoicesAsync.maybeWhen(
    data: (invoices) {
      final total = invoices.fold<double>(0.0, (sum, item) => sum + item.amount);
      final payees = invoices.where((inv) => inv.status == 'Payée').length;
      
      return {
        'count': invoices.length,
        'total': total,
        'payees': payees,
      };
    },
    orElse: () => {'count': 0, 'total': 0.0, 'payees': 0},
  );
});

// 🟡 Le Notifier pour les actions d'écriture
class InvoiceNotifier extends StateNotifier<AsyncValue<void>> {
  final InvoiceRepository _repository;
  final Ref _ref;

  InvoiceNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> createInvoice(InvoiceModel invoice) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createInvoice(invoice);
      state = const AsyncValue.data(null);
      _ref.invalidate(invoicesFutureProvider); 
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateInvoice(invoice);
      state = const AsyncValue.data(null);
      _ref.invalidate(invoicesFutureProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteInvoice(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteInvoice(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(invoicesFutureProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 🟡 Fournit le Notifier à l'interface graphique
final invoiceNotifierProvider = StateNotifierProvider<InvoiceNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return InvoiceNotifier(repo, ref);
});
