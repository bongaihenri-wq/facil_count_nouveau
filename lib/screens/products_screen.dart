import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _supplierController = TextEditingController();
  final _stockController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur chargement : $e')));
      }
    }
  }

  Future<void> _addProduct() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom du produit obligatoire')),
      );
      return;
    }

    final stockText = _stockController.text.trim();
    final stock = stockText.isEmpty ? 0 : int.tryParse(stockText) ?? 0;

    try {
      await supabase.from('products').insert({
        'name': name,
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        'supplier': _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
        'stock': stock,
      });

      _clearControllers();
      Navigator.of(context).pop();
      _loadProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit ajouté avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur ajout : $e')));
    }
  }

  Future<void> _updateProduct(Map<String, dynamic> product) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom du produit obligatoire')),
      );
      return;
    }

    final stockText = _stockController.text.trim();
    final stock = stockText.isEmpty ? 0 : int.tryParse(stockText) ?? 0;

    try {
      await supabase
          .from('products')
          .update({
            'name': name,
            'category': _categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim(),
            'supplier': _supplierController.text.trim().isEmpty
                ? null
                : _supplierController.text.trim(),
            'stock': stock,
          })
          .eq('id', product['id']);

      _clearControllers();
      Navigator.of(context).pop();
      _loadProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit modifié avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur modification : $e')));
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer produit ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${product['name']}" ? Cette action est irréversible.',
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
      await supabase.from('products').delete().eq('id', product['id']);
      _loadProducts();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit supprimé')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur suppression : $e')));
    }
  }

  void _clearControllers() {
    _nameController.clear();
    _categoryController.clear();
    _supplierController.clear();
    _stockController.text = '0';
  }

  void _showAddProductDialog() {
    _clearControllers();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouveau produit / service'),
          content: _buildProductForm(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: _addProduct,
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    _nameController.text = product['name'] ?? '';
    _categoryController.text = product['category'] ?? '';
    _supplierController.text = product['supplier'] ?? '';
    _stockController.text = (product['stock'] ?? 0).toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier produit'),
          content: _buildProductForm(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => _updateProduct(product),
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du produit *',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Catégorie (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _supplierController,
            decoration: const InputDecoration(
              labelText: 'Fournisseur (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _stockController,
            decoration: const InputDecoration(
              labelText: 'Stock actuel (0 si aucun)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produits / Services')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(
              child: Text('Aucun produit enregistré pour l\'instant'),
            )
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  final stock = product['stock'] ?? 0;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        product['name'] ?? 'Sans nom',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product['category'] != null)
                            Text('Catégorie : ${product['category']}'),
                          if (product['supplier'] != null)
                            Text('Fournisseur : ${product['supplier']}'),
                          Text(
                            'Stock : $stock',
                            style: TextStyle(
                              color: stock <= 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditProductDialog(product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter produit'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _supplierController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
