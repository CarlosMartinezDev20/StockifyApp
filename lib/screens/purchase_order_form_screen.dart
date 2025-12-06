import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class PurchaseOrderFormScreen extends StatefulWidget {
  const PurchaseOrderFormScreen({super.key});

  @override
  State<PurchaseOrderFormScreen> createState() => _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupplierService _supplierService = SupplierService();
  final ProductService _productService = ProductService();
  final PurchaseOrderService _purchaseOrderService = PurchaseOrderService();
  final WarehouseService _warehouseService = WarehouseService();

  List<Supplier> _suppliers = [];
  List<Product> _products = [];
  List<Warehouse> _warehouses = [];
  Supplier? _selectedSupplier;
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 7));
  
  final List<_OrderItem> _items = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final suppliers = await _supplierService.getAll();
      final products = await _productService.getAll();
      final warehouses = await _warehouseService.getAll();
      
      setState(() {
        _suppliers = suppliers;
        _products = products;
        _warehouses = warehouses;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }



  void _addItem() {
    setState(() {
      final item = _OrderItem(
        product: null,
        quantityController: TextEditingController(text: '1'),
        priceController: TextEditingController(),
      );
      _items.add(item);
      _initializeWarehouseAllocations(item);
    });
  }

  void _initializeWarehouseAllocations(_OrderItem item) {
    // Limpiar asignaciones anteriores
    for (var alloc in item.warehouseAllocations) {
      alloc.dispose();
    }
    item.warehouseAllocations.clear();

    // Crear una asignación por cada almacén disponible
    for (var warehouse in _warehouses) {
      item.warehouseAllocations.add(_WarehouseAllocation(
        warehouseId: warehouse.id!,
        warehouseName: warehouse.name,
        qtyController: TextEditingController(text: '0'),
      ));
    }

    // Auto-asignar la cantidad total al primer almacén
    if (item.warehouseAllocations.isNotEmpty) {
      final requestedQty = double.tryParse(item.quantityController.text) ?? 0;
      if (requestedQty > 0) {
        item.warehouseAllocations.first.qtyController.text = requestedQty.toString();
      }
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].quantityController.dispose();
      _items[index].priceController.dispose();
      for (var alloc in _items[index].warehouseAllocations) {
        alloc.dispose();
      }
      _items.removeAt(index);
    });
  }

  double _getTotalAllocated(_OrderItem item) {
    return item.warehouseAllocations.fold(0.0, (sum, alloc) {
      return sum + (double.tryParse(alloc.qtyController.text) ?? 0);
    });
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) {
      if (item.product == null) return sum;
      final qty = double.tryParse(item.quantityController.text) ?? 0;
      final price = double.tryParse(item.priceController.text) ?? 0;
      return sum + (qty * price);
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un proveedor')),
      );
      return;
    }

    if (_items.isEmpty || _items.every((item) => item.product == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    // Validar distribuciones de almacén
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.product != null && item.warehouseAllocations.isNotEmpty) {
        final requestedQty = double.tryParse(item.quantityController.text) ?? 0;
        final allocatedQty = _getTotalAllocated(item);
        
        if ((allocatedQty - requestedQty).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ítem ${i + 1}: La distribución por almacén (${allocatedQty.toStringAsFixed(0)}) debe coincidir con la cantidad ordenada (${requestedQty.toStringAsFixed(0)})'
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      final items = _items
          .where((item) => item.product != null)
          .map((item) {
            // Preparar distribuciones de almacén si existen
            final allocations = item.warehouseAllocations
                .where((alloc) => (double.tryParse(alloc.qtyController.text) ?? 0) > 0)
                .map((alloc) => {
                      'warehouseId': alloc.warehouseId,
                      'qty': double.parse(alloc.qtyController.text),
                    })
                .toList();

            return {
              'productId': item.product!.id,
              'qtyOrdered': double.parse(item.quantityController.text),
              'unitPrice': double.parse(item.priceController.text),
              if (allocations.isNotEmpty) 'warehouseAllocations': allocations,
            };
          })
          .toList();

      await _purchaseOrderService.create(
        supplierId: _selectedSupplier!.id,
        items: items,
        expectedAt: _expectedDate,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orden creada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.quantityController.dispose();
      item.priceController.dispose();
      for (var alloc in item.warehouseAllocations) {
        alloc.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Orden de Compra'),
      ),
      body: _isLoading
          ? const LoadingIndicator.fullScreen(
              message: 'Cargando datos...',
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Proveedor
                          // ignore: deprecated_member_use
                          DropdownButtonFormField<Supplier>(
                            decoration: const InputDecoration(
                              labelText: 'Proveedor *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            hint: const Text('Seleccionar...'),
                            isExpanded: true,
                            // ignore: deprecated_member_use
                            value: _selectedSupplier,
                            items: _suppliers.map((supplier) {
                              return DropdownMenuItem(
                                value: supplier,
                                child: Text(
                                  supplier.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (supplier) {
                              setState(() => _selectedSupplier = supplier);
                            },
                            validator: (value) {
                              if (value == null) return 'Selecciona un proveedor';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Fecha Esperada
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _expectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => _expectedDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha Esperada',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                '${_expectedDate.day}/${_expectedDate.month}/${_expectedDate.year}',
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ITEMS
                          Row(
                            children: [
                              Text(
                                'ITEMS',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          ..._items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return _buildItemRow(index, item);
                          }),

                          const SizedBox(height: 16),

                          OutlinedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Item'),
                          ),

                          const SizedBox(height: 24),

                          // Total
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${_calculateTotal().toStringAsFixed(2)} USD',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer con botones
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: _isSaving ? null : _saveOrder,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: LoadingIndicator.small(),
                                  )
                                : const Text('Crear Orden'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildItemRow(int index, _OrderItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Ítem ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => _removeItem(index),
                  color: Theme.of(context).colorScheme.error,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ignore: deprecated_member_use
            DropdownButtonFormField<Product>(
              decoration: InputDecoration(
                labelText: 'Producto',
                hintText: 'Seleccionar producto...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                prefixIcon: Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              isExpanded: true,
              // ignore: deprecated_member_use
              value: item.product,
              items: _products.map((product) {
                return DropdownMenuItem(
                  value: product,
                  child: Text(
                    product.name,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (product) {
                setState(() {
                  item.product = product;
                  // Inicializar distribuciones de almacén cuando se selecciona un producto
                  if (product != null && item.warehouseAllocations.isEmpty) {
                    _initializeWarehouseAllocations(item);
                  }
                });
              },
            ),
            // Distribución por almacén
            if (item.product != null && item.warehouseAllocations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWarehouseAllocationSection(item),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cantidad',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: item.quantityController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precio',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: item.priceController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.product != null &&
                item.quantityController.text.isNotEmpty &&
                item.priceController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        '\$${((double.tryParse(item.quantityController.text) ?? 0) * (double.tryParse(item.priceController.text) ?? 0)).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseAllocationSection(_OrderItem item) {
    final requestedQty = double.tryParse(item.quantityController.text) ?? 0;
    final allocatedQty = _getTotalAllocated(item);
    final isValid = (allocatedQty - requestedQty).abs() < 0.01;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid 
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.warehouse,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribución por Almacén',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Especifica dónde guardar',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isValid 
                      ? Colors.green.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isValid ? Colors.green : Theme.of(context).colorScheme.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.error,
                      size: 14,
                      color: isValid ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${allocatedQty.toStringAsFixed(0)}/${requestedQty.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isValid 
                            ? Colors.green.shade700
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isValid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'La suma debe ser exactamente ${requestedQty.toStringAsFixed(0)} unidades',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...item.warehouseAllocations.map((alloc) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Text(
                      alloc.warehouseName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      controller: alloc.qtyController,
                      decoration: InputDecoration(
                        labelText: 'Cant.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        errorStyle: const TextStyle(fontSize: 0, height: 0),
                        labelStyle: const TextStyle(fontSize: 11),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _OrderItem {
  Product? product;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final List<_WarehouseAllocation> warehouseAllocations;

  _OrderItem({
    this.product,
    required this.quantityController,
    required this.priceController,
  }) : warehouseAllocations = [];
}

class _WarehouseAllocation {
  final String warehouseId;
  final String warehouseName;
  final TextEditingController qtyController;

  _WarehouseAllocation({
    required this.warehouseId,
    required this.warehouseName,
    required this.qtyController,
  });

  void dispose() {
    qtyController.dispose();
  }
}
