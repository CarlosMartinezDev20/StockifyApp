import 'dart:async';
import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with PermissionsMixin {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, low_stock, out_of_stock
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    loadUserRole();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _productService.getAll(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      setState(() {
        _products = products;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Product> filtered = List.from(_products);

    // Aplicar filtro de stock
    if (_selectedFilter == 'low_stock') {
      filtered = filtered.where((p) {
        final stock = p.stockTotal ?? 0;
        final minStock = p.minStock ?? 0;
        return stock < minStock && stock > 0;
      }).toList();
    } else if (_selectedFilter == 'out_of_stock') {
      filtered = filtered.where((p) => (p.stockTotal ?? 0) == 0).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalProducts = _products.length;
    final lowStock = _products.where((p) {
      final stock = p.stockTotal ?? 0;
      final minStock = p.minStock ?? 0;
      return stock < minStock && stock > 0;
    }).length;
    final outOfStock = _products.where((p) => (p.stockTotal ?? 0) == 0).length;

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar productos...',
              leading: const Icon(Icons.search),
              trailing: _searchController.text.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadProducts();
                        },
                      ),
                    ]
                  : null,
              onChanged: (value) {
                // Debounce de 300ms para no hacer búsquedas excesivas
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  _loadProducts();
                });
              },
              onSubmitted: (value) {
                _debounceTimer?.cancel();
                _loadProducts();
              },
            ),
          ),

          // Chips de filtro
          if (!_isLoading)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: Text('Todos ($totalProducts)'),
                    selected: _selectedFilter == 'all',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'all';
                        _applyFilters();
                      });
                    },
                    avatar: _selectedFilter == 'all'
                        ? const Icon(Icons.check_circle, size: 18)
                        : const Icon(Icons.inventory_2, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('Stock Bajo ($lowStock)'),
                    selected: _selectedFilter == 'low_stock',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'low_stock';
                        _applyFilters();
                      });
                    },
                    avatar: Icon(
                      Icons.warning,
                      size: 18,
                      color: _selectedFilter == 'low_stock'
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('Sin Stock ($outOfStock)'),
                    selected: _selectedFilter == 'out_of_stock',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'out_of_stock';
                        _applyFilters();
                      });
                    },
                    avatar: Icon(
                      Icons.error,
                      size: 18,
                      color: _selectedFilter == 'out_of_stock'
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Lista de productos
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: hasPermission('products.create')
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const ProductFormScreen(),
                  ),
                );
                if (result == true) {
                  _loadProducts(); // Recargar lista
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Producto'),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingIndicator.fullScreen(
        message: 'Cargando productos...',
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar productos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return AnimatedEmptyState(
        icon: _selectedFilter == 'all' ? Icons.inventory_2_outlined : Icons.filter_list_off,
        title: _selectedFilter == 'all' ? 'No hay productos' : 'No hay productos con este filtro',
        message: _selectedFilter == 'all'
            ? 'Aún no hay productos registrados.\\nCrea tu primer producto.'
            : 'Intenta con otro filtro o limpia la búsqueda.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return _ProductCard(
            product: product,
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stockColor = _getStockColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${product.sku}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (product.stockTotal != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stockColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: stockColor),
                      ),
                      child: Text(
                        '${product.stockTotal!.toInt()}',
                        style: TextStyle(
                          color: stockColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (product.categoryName != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(product.categoryName!),
                      avatar: const Icon(Icons.category, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(product.unit),
                      avatar: const Icon(Icons.straighten, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
              if (product.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  product.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
              ),
            ),
    );
  }

  Color _getStockColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stock = product.stockTotal ?? 0;
    final minStock = product.minStock ?? 10;    if (stock == 0) {
      return colorScheme.error;
    } else if (stock <= minStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
