import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/data/models/invoice_model.dart';
import '/presentation/providers/invoice_provider.dart';
import '/core/utils/business_helper.dart';

/// Fonction globale pour appeler le modal depuis n'importe où
void showInvoiceDialog(BuildContext context, {InvoiceModel? invoice}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => InvoiceFormDialog(invoice: invoice),
  );
}

class InvoiceFormDialog extends ConsumerStatefulWidget {
  final InvoiceModel? invoice; // Si null = Ajout, si renseigné = Édition

  const InvoiceFormDialog({super.key, this.invoice});

  @override
  ConsumerState<InvoiceFormDialog> createState() => _InvoiceFormDialogState();
}

class _InvoiceFormDialogState extends ConsumerState<InvoiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _numberCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _supplierCtrl;
  late TextEditingController _notesCtrl;
  
  String? _selectedType;
  String _selectedStatus = 'En attente';
  DateTime _invoiceDate = DateTime.now();
  File? _selectedImage;
  String? _existingImageUrl; 
  bool _isLoading = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final isEdit = widget.invoice != null;
    
    // Remplissage automatique si on est en modification
    _numberCtrl = TextEditingController(text: isEdit ? widget.invoice!.number : '');
    _amountCtrl = TextEditingController(text: isEdit ? widget.invoice!.amount.toString() : '');
    _supplierCtrl = TextEditingController(text: isEdit ? widget.invoice!.supplier : '');
    _notesCtrl = TextEditingController(text: isEdit ? widget.invoice!.notes : '');
    
    if (isEdit) {
      _selectedType = widget.invoice!.type;
      _selectedStatus = widget.invoice!.status;
      _invoiceDate = widget.invoice!.invoiceDate;
      _existingImageUrl = widget.invoice!.imageUrl;
    }
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _amountCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _existingImageUrl = null; // Remplace l'ancienne image
      });
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
      final isEdit = widget.invoice != null;
      String? imageUrl = _existingImageUrl;
      
      if (_selectedImage != null) {
        final repo = ref.read(invoiceRepositoryProvider);
        final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await repo.uploadImage(File(_selectedImage!.path), fileName);
      }
      
      // Nettoyage et conversion sécurisée du montant
      final amountText = _amountCtrl.text.trim().replaceAll(',', '.');
      final parsedAmount = double.parse(amountText);
      // 🚨 IMPORTANT : On récupère l'ID de l'utilisateur ou du business connecté
      // Adapte cette ligne selon l'endroit où tu stockes ton user ou business ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final invoice = InvoiceModel(
        id: isEdit ? widget.invoice!.id : '', 
        type: _selectedType!,
        number: _numberCtrl.text.trim().isEmpty ? null : _numberCtrl.text.trim(),
        invoiceDate: _invoiceDate,
        amount: parsedAmount,
        status: _selectedStatus,
        imageUrl: imageUrl,
        supplier: _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        locked: isEdit ? widget.invoice!.locked : false,
        createdAt: isEdit ? widget.invoice!.createdAt : DateTime.now(),
      );
        /// ... création de l'objet invoice ...
      final data = invoice.toJson();
      if (!isEdit) {
        data.remove('id'); 
      }

      // 🟢 LA CORRECTION DYNAMIQUE : On récupère le businessId via ton helper
      try {
        final businessHelper = ref.read(businessHelperProvider);
        final String businessId = await businessHelper.getBusinessId();
        
        data['business_id'] = businessId; 
        print('🚀 Facture liée au business dynamique : $businessId');
      } catch (e) {
        print('❌ Erreur BusinessHelper : $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : Impossible de récupérer l\'ID du business.'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
        return; // On arrête tout si on n'a pas le businessId
      }

      final notifier = ref.read(invoiceNotifierProvider.notifier);
      
      if (isEdit) {
        await notifier.updateInvoice(invoice);
      } else {
        // Insertion directe avec le business_id inclus !
        await Supabase.instance.client.from('invoices').insert(data);
        ref.invalidate(invoicesFutureProvider);
      }
      // On convertit en JSON
     
        


          
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? '✅ Facture modifiée !' : '✅ Facture ajoutée !'),
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
    final isEdit = widget.invoice != null;

    return Container(
      // Empêche le clavier de cacher le formulaire
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isEdit ? Colors.teal.shade700 : Colors.purple.shade700,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(isEdit ? Icons.edit : Icons.receipt_long, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEdit ? 'Modifier la facture' : 'Nouvelle facture',
                    style: const TextStyle(
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
          
          // Formulaire
          Flexible(
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                children: [
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
                                  Icon(_getTypeIcon(t), color: _getTypeColor(t), size: 20),
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
                  
                  // Numéro (Optionnel)
                  TextFormField(
                    controller: _numberCtrl,
                    decoration: InputDecoration(
                      labelText: 'Numéro facture (Optionnel)',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Obligatoire';
                      final cleanValue = v.trim().replaceAll(',', '.');
                      if (double.tryParse(cleanValue) == null) return 'Nombre invalide';
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Bouton d'action
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
                    backgroundColor: isEdit ? Colors.teal.shade700 : Colors.purple.shade700,
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
                      : Text(
                          isEdit ? 'Enregistrer les modifications' : 'Enregistrer la facture',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      return _buildImageFrame(Image.file(_selectedImage!, fit: BoxFit.cover));
    }
    if (_existingImageUrl != null) {
      return _buildImageFrame(Image.network(_existingImageUrl!, fit: BoxFit.cover));
    }

    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade200, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 48, color: Colors.purple.shade300),
            const SizedBox(height: 12),
            Text(
              'Ajouter une photo de facture',
              style: TextStyle(color: Colors.purple.shade400, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFrame(Widget imageWidget) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(height: 200, width: double.infinity, child: imageWidget),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  onPressed: _showImageSourceDialog,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => setState(() {
                    _selectedImage = null;
                    _existingImageUrl = null;
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
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