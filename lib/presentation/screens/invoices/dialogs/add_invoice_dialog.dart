import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '/data/models/invoice_model.dart';
import '/presentation/providers/invoice_provider.dart';

void showAddInvoiceDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddInvoiceDialog(),
  );
}

class AddInvoiceDialog extends ConsumerStatefulWidget {
  const AddInvoiceDialog({super.key});

  @override
  ConsumerState<AddInvoiceDialog> createState() => _AddInvoiceDialogState();
}

class _AddInvoiceDialogState extends ConsumerState<AddInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  String? _selectedType;
  String _selectedStatus = 'En attente';
  DateTime _invoiceDate = DateTime.now();
  File? _selectedImage;
  bool _isLoading = false;

  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Source de l\'image'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Caméra'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Galerie'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image si présente
      String? imageUrl;
      if (_selectedImage != null) {
        final repo = ref.read(invoiceRepositoryProvider);
        final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await repo.uploadImage(File(_selectedImage!.path), fileName);
      }
      
      // Créer la facture
      final invoice = InvoiceModel(
        id: '', // Généré par Supabase
        type: _selectedType!,
        number: _numberCtrl.text.trim(),
        invoiceDate: _invoiceDate,
        amount: double.parse(_amountCtrl.text.trim()),
        status: _selectedStatus,
        imageUrl: imageUrl,
        supplier: _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        locked: false,
        createdAt: DateTime.now(),
      );

      await ref.read(invoiceNotifierProvider.notifier).createInvoice(invoice);
      
      // Rafraîchir la liste
      ref.invalidate(invoicesProvider);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Facture ajoutée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding - 20 : 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.shade700,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Nouvelle facture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ✅ SECTION IMAGE
                  _buildImageSection(),
                  const SizedBox(height: 20),
                  
                  // Type
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Type *',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: ['Achats', 'Ventes', 'Dépenses']
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Row(
                                children: [
                                  Icon(
                                    _getTypeIcon(t),
                                    color: _getTypeColor(t),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(t),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedType = v),
                    validator: (v) => v == null ? 'Obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Numéro
                  TextFormField(
                    controller: _numberCtrl,
                    decoration: InputDecoration(
                      labelText: 'Numéro facture *',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v?.trim().isEmpty == true ? 'Obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _invoiceDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _invoiceDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date *',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      child: Text(
                        '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Montant
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: InputDecoration(
                      labelText: 'Montant TTC *',
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: 'CFA',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.trim().isEmpty == true) return 'Obligatoire';
                      if (double.tryParse(v!.trim()) == null) return 'Nombre invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Fournisseur/Client
                  TextFormField(
                    controller: _supplierCtrl,
                    decoration: InputDecoration(
                      labelText: 'Fournisseur / Client',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Statut
                  const Text('Statut', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Payée',
                        label: Text('Payée'),
                        icon: Icon(Icons.check_circle),
                      ),
                      ButtonSegment(
                        value: 'En attente',
                        label: Text('En attente'),
                        icon: Icon(Icons.pending),
                      ),
                    ],
                    selected: {_selectedStatus},
                    onSelectionChanged: (v) => setState(() => _selectedStatus = v.first),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notes
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          
          // Bouton submit
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enregistrer la facture',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    if (_selectedImage != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _selectedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: _showImageSourceDialog,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.purple.shade200,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: Colors.purple.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Ajouter une photo de facture',
              style: TextStyle(
                color: Colors.purple.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Caméra ou galerie',
              style: TextStyle(
                color: Colors.purple.shade300,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    return switch (type) {
      'Achats' => Icons.shopping_cart,
      'Ventes' => Icons.point_of_sale,
      'Dépenses' => Icons.money_off,
      _ => Icons.receipt,
    };
  }

  Color _getTypeColor(String type) {
    return switch (type) {
      'Achats' => Colors.blue,
      'Ventes' => Colors.green,
      'Dépenses' => Colors.orange,
      _ => Colors.grey,
    };
  }
}