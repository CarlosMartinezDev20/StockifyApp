import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with PermissionsMixin {
  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();

  Product? _product;
  List<InventoryLevel> _inventoryLevels = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadUserRole();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final product = await _productService.getById(widget.productId);
      final inventory = await _inventoryService.getLevels(
        productId: widget.productId,
      );

      setState(() {
        _product = product;
        _inventoryLevels = inventory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${_product?.name}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _productService.delete(widget.productId);
        if (mounted) {
          AnimatedSnackBar.showSuccess(
            context,
            'Producto eliminado exitosamente',
          );
          Navigator.of(context).pop(true); // true = actualizar lista
        }
      } catch (e) {
        if (mounted) {
          AnimatedSnackBar.showError(
            context,
            'Error al eliminar: $e',
          );
        }
      }
    }
  }

  Future<void> _editProduct() async {
    if (_product == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: _product),
      ),
    );

    if (result == true) {
      _loadProductDetails(); // Recargar detalles
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Producto'),
        actions: [
          if (_product != null) ...[
            if (hasPermission('products.edit'))
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
                onPressed: _editProduct,
              ),
            if (hasPermission('products.delete'))
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Eliminar',
                onPressed: _deleteProduct,
              ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator.fullScreen(
        message: 'Cargando detalles...',
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
              'Error al cargar producto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadProductDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_product == null) {
      return const Center(child: Text('Producto no encontrado'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final stockColor = _getStockColor();

    return RefreshIndicator(
      onRefresh: _loadProductDetails,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta principal del producto
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          size: 40,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product!.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU: ${_product!.sku}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Información del producto
                  _InfoRow(
                    icon: Icons.category,
                    label: 'Categoría',
                    value: _product!.categoryName ?? 'Sin categoría',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.straighten,
                    label: 'Unidad',
                    value: _product!.unit,
                  ),
                  if (_product!.minStock != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.warning_amber,
                      label: 'Stock Mínimo',
                      value: '${_product!.minStock!.toStringAsFixed(0)} unidades',
                    ),
                  ],
                  if (_product!.barcode != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.barcode_reader,
                      label: 'Código de Barras',
                      value: _product!.barcode!,
                    ),
                  ],
                  if (_product!.description != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Descripción',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_product!.description!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stock total
          Card(
            color: stockColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.inventory, color: stockColor, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Total',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${(_product!.stockTotal ?? 0).toInt()} unidades',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: stockColor,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Inventario por almacén
          if (_inventoryLevels.isNotEmpty) ...[
            Text(
              'Inventario por Almacén',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._inventoryLevels.map((level) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.warehouse),
                    title: Text(level.warehouseName ?? 'Almacén desconocido'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${level.quantity.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Color _getStockColor() {
    final colorScheme = Theme.of(context).colorScheme;
    final stock = _product?.stockTotal ?? 0;
    final minStock = _product?.minStock ?? 10;

    if (stock == 0) {
      return colorScheme.error;
    } else if (stock <= minStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
