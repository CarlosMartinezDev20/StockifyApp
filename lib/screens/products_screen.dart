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
          return RepaintBoundary(
            key: ValueKey('product_${product.id}'),
            child: _ProductCard(product: product, index: index),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final int index;

  const _ProductCard({required this.product, required this.index});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(_controller);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(_controller);

    // Limitar delay máximo a 100ms para mejor fluidez
    final delayMs = (10 * widget.index).clamp(0, 100);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stockColor = _getStockColor(context);

    return RepaintBoundary(
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Hero(
          tag: 'product_${widget.product.id}',
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ProductDetailScreen(productId: widget.product.id),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
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
                          widget.product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${widget.product.sku}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.product.stockTotal != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
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
                              '${widget.product.stockTotal!.toInt()}',
                              style: TextStyle(
                                color: stockColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              if (widget.product.categoryName != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(widget.product.categoryName!),
                      avatar: const Icon(Icons.category, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(widget.product.unit),
                      avatar: const Icon(Icons.straighten, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
              if (widget.product.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.product.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
          ),
        ),
      ),
      ),
    );
  }

  Color _getStockColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stock = widget.product.stockTotal ?? 0;
    final minStock = widget.product.minStock ?? 10;

    if (stock == 0) {
      return colorScheme.error;
    } else if (stock <= minStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
