import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  String _selectedType = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await supabase
          .from('invoices')
          .select()
          .order('invoice_date', ascending: false);

      if (!mounted) return;

      setState(() {
        _invoices = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement factures : $e')),
      );
    }
  }

  String formatCFA(num? amount) {
    if (amount == null || amount == 0) return '0 F CFA';
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.abs())} F CFA';
  }

  Color getTypeColor(String type) {
    switch (type) {
      case 'Achats':
        return Colors.blue[700]!;
      case 'Ventes':
        return Colors.green[700]!;
      case 'Dépenses':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Payée':
        return Colors.green[700]!;
      case 'En attente':
        return Colors.orange[700]!;
      case 'Annulée':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInvoices = _selectedType == 'Tous'
        ? _invoices
        : _invoices.where((inv) => inv['type'] == _selectedType).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Factures')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Tous', 'Achats', 'Ventes', 'Dépenses'].map((
                        type,
                      ) {
                        final isSelected = type == _selectedType;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (value) {
                              if (value) setState(() => _selectedType = type);
                            },
                            selectedColor: getTypeColor(type),
                            backgroundColor: Colors.grey[300],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                Expanded(
                  child: filteredInvoices.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune facture pour ce type',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = filteredInvoices[index];
                            final type =
                                invoice['type'] as String? ?? 'Inconnu';
                            final status =
                                invoice['status'] as String? ?? 'Inconnu';
                            final amount = (invoice['amount'] as num?) ?? 0;
                            final imageUrl = invoice['image_url'] as String?;
                            final bool locked = invoice['locked'] ?? false;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          imageUrl != null &&
                                              imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => _placeholderImage(),
                                            )
                                          : _placeholderImage(),
                                    ),
                                    const SizedBox(width: 16),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '$type - ${invoice['number'] ?? 'N° inconnu'}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: getTypeColor(type),
                                                ),
                                              ),
                                              if (locked)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 8.0,
                                                      ),
                                                  child: Icon(
                                                    Icons.lock,
                                                    color: Colors.yellow[800],
                                                    size: 24,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            invoice['invoice_date']?.substring(
                                                  0,
                                                  10,
                                                ) ??
                                                'Date inconnue',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            formatCFA(amount),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: amount > 0
                                                  ? Colors.red[800]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: getStatusColor(
                                                status,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: getStatusColor(status),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () =>
                                              _showEditInvoiceDialog(invoice),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteInvoice(invoice),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        onPressed: () => _showAddInvoiceForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[300],
      child: const Icon(Icons.receipt_long, size: 50, color: Colors.grey),
    );
  }

  void _showAddInvoiceForm() {
    String? selectedType;
    final numberController = TextEditingController();
    final amountController = TextEditingController();
    DateTime invoiceDate = DateTime.now();
    String? selectedStatus = 'En attente';
    final imageUrlController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle facture'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Type *',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedType,
                      items: ['Achats', 'Ventes', 'Dépenses']
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedType = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro facture *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: invoiceDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => invoiceDate = picked);
                        }
                      },
                      child: Text(DateFormat('dd/MM/yyyy').format(invoiceDate)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Montant TTC *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedStatus,
                      items: ['Payée', 'En attente', 'Annulée']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedStatus = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL photo facture (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final number = numberController.text.trim();
                final amountText = amountController.text.trim();

                if (selectedType == null ||
                    number.isEmpty ||
                    amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Type, numéro et montant obligatoires'),
                    ),
                  );
                  return;
                }

                try {
                  final amount = double.parse(amountText);

                  await supabase.from('invoices').insert({
                    'type': selectedType,
                    'number': number,
                    'invoice_date': invoiceDate.toIso8601String().substring(
                      0,
                      10,
                    ),
                    'amount': amount,
                    'status': selectedStatus,
                    'image_url': imageUrlController.text.trim().isEmpty
                        ? null
                        : imageUrlController.text.trim(),
                    'notes': notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    'locked': false,
                  });

                  if (!mounted) return;
                  await _loadInvoices();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Facture ajoutée !')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur ajout : $e')));
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showEditInvoiceDialog(Map<String, dynamic> invoice) {
    String? selectedType = invoice['type'];
    final numberController = TextEditingController(
      text: invoice['number'] ?? '',
    );
    final amountController = TextEditingController(
      text: invoice['amount'].toString(),
    );
    DateTime invoiceDate = DateTime.parse(invoice['invoice_date']);
    String? selectedStatus = invoice['status'];
    final imageUrlController = TextEditingController(
      text: invoice['image_url'] ?? '',
    );
    final notesController = TextEditingController(text: invoice['notes'] ?? '');
    bool locked = invoice['locked'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier facture'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Achats', 'Ventes', 'Dépenses']
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedType = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro facture *',
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: invoiceDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => invoiceDate = picked);
                        }
                      },
                      child: Text(DateFormat('dd/MM/yyyy').format(invoiceDate)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Montant TTC *',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Payée', 'En attente', 'Annulée']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedStatus = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL photo facture (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optionnel)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Verrouillé'),
                      value: locked,
                      onChanged: (val) => setDialogState(() => locked = val),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final number = numberController.text.trim();
                final amountText = amountController.text.trim();

                if (selectedType == null ||
                    number.isEmpty ||
                    amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Type, numéro et montant obligatoires'),
                    ),
                  );
                  return;
                }

                try {
                  final amount = double.parse(amountText);

                  await supabase
                      .from('invoices')
                      .update({
                        'type': selectedType,
                        'number': number,
                        'invoice_date': invoiceDate.toIso8601String().substring(
                          0,
                          10,
                        ),
                        'amount': amount,
                        'status': selectedStatus,
                        'image_url': imageUrlController.text.trim().isEmpty
                            ? null
                            : imageUrlController.text.trim(),
                        'notes': notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        'locked': locked,
                      })
                      .eq('id', invoice['id']);

                  if (!mounted) return;
                  await _loadInvoices();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Facture modifiée !')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur modification : $e')),
                  );
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteInvoice(Map<String, dynamic> invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer facture ?'),
        content: Text(
          'Voulez-vous supprimer la facture ${invoice['number'] ?? 'N° inconnu'} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('invoices').delete().eq('id', invoice['id']);
      if (!mounted) return;
      await _loadInvoices();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Facture supprimée')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur suppression : $e')));
    }
  }
}
