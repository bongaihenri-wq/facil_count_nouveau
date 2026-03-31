import 'package:flutter/material.dart'; // ← AJOUTÉ pour DateTimeRange
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../core/utils/business_helper.dart';

// Repository provider
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final client = Supabase.instance.client;
  final businessHelper = ref.watch(businessHelperProvider);
  return InvoiceRepository(client, businessHelper);
});

// ✅ SUPPRIMÉ : Le StreamProvider en double (garder uniquement FutureProvider)
// Liste des factures (FutureProvider simple et fiable)
final invoicesProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getInvoices();
});

// Filtre par type
final invoiceTypeFilterProvider = StateProvider<String>((ref) => 'Tous');

// Filtre par statut
final invoiceStatusFilterProvider = StateProvider<String?>((ref) => null);

// ✅ CORRIGÉ : DateTimeRange vient de material.dart
final invoicePeriodFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

// Factures filtrées
final filteredInvoicesProvider = Provider<AsyncValue<List<InvoiceModel>>>((ref) {
  final invoicesAsync = ref.watch(invoicesProvider);
  final typeFilter = ref.watch(invoiceTypeFilterProvider);
  final statusFilter = ref.watch(invoiceStatusFilterProvider);
  final periodFilter = ref.watch(invoicePeriodFilterProvider);

  return invoicesAsync.when(
    data: (invoices) {
      var filtered = invoices;

      // Filtre par type
      if (typeFilter != 'Tous') {
        filtered = filtered.where((i) => i.type == typeFilter).toList();
      }

      // Filtre par statut
      if (statusFilter != null) {
        filtered = filtered.where((i) => i.status == statusFilter).toList();
      }

      // Filtre par période
      if (periodFilter != null) {
        filtered = filtered.where((i) {
          return i.invoiceDate.isAfter(periodFilter.start.subtract(const Duration(days: 1))) &&
                 i.invoiceDate.isBefore(periodFilter.end.add(const Duration(days: 1)));
        }).toList();
      }

      // Trier par date décroissante
      filtered.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// Notifier pour les actions (CRUD)
class InvoiceNotifier extends StateNotifier<AsyncValue<void>> {
  final InvoiceRepository _repo;

  InvoiceNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> createInvoice(InvoiceModel invoice) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createInvoice(invoice);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateInvoice(invoice);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteInvoice(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteInvoice(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String status) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateStatus(id, status);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final invoiceNotifierProvider =
    StateNotifierProvider<InvoiceNotifier, AsyncValue<void>>((ref) {
  return InvoiceNotifier(ref.watch(invoiceRepositoryProvider));
});

// Stats des factures
final invoiceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final invoices = ref.watch(filteredInvoicesProvider).valueOrNull ?? [];

  final total = invoices.fold(0.0, (sum, i) => sum + i.amount);
  final payees = invoices.where((i) => i.status == 'Payée').length;
  final enAttente = invoices.where((i) => i.status == 'En attente').length;
  final annulees = invoices.where((i) => i.status == 'Annulée').length;

  return {
    'count': invoices.length,
    'total': total,
    'payees': payees,
    'enAttente': enAttente,
    'annulees': annulees,
  };
});
