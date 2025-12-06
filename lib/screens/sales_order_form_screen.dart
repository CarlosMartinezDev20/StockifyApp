import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class SalesOrderFormScreen extends StatefulWidget {
  const SalesOrderFormScreen({super.key});

  @override
  State<SalesOrderFormScreen> createState() => _SalesOrderFormScreenState();
}

class _SalesOrderFormScreenState extends State<SalesOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SalesOrderService _salesOrderService = SalesOrderService();
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();

  List<Customer> _customers = [];
  List<Product> _products = [];
  List<Warehouse> _warehouses = [];
  String? _selectedCustomerId;
  
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
      final customers = await _customerService.getAll();
      final products = await _productService.getAll();
      final warehouses = await WarehouseService().getAll();
      
      setState(() {
        _customers = customers;
        _products = products;
        _warehouses = warehouses;
        _isLoading = false;
      });

      // Agregar un item inicial
      if (_products.isNotEmpty) {
        _addItem();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadWarehouseStock(String productId, _OrderItem item) async {
    try {
      final levels = await _inventoryService.getLevels(productId: productId);
      
      setState(() {
        // Limpiar asignaciones anteriores
        for (var alloc in item.warehouseAllocations) {
          alloc.dispose();
        }
        item.warehouseAllocations.clear();

        // Crear nueva asignación por cada almacén con stock
        for (var level in levels) {
          if (level.quantity > 0) {
            item.warehouseAllocations.add(_WarehouseAllocation(
              warehouseId: level.warehouseId,
              warehouseName: level.warehouseName ?? 'Sin nombre',
              availableStock: level.quantity,
              qtyController: TextEditingController(text: '0'),
            ));
          }
        }
        
        // Si hay almacenes, auto-asignar la cantidad total al primero
        if (item.warehouseAllocations.isNotEmpty) {
          final requestedQty = double.tryParse(item.qtyController.text) ?? 0;
          final firstWarehouse = item.warehouseAllocations.first;
          if (requestedQty > 0 && requestedQty <= firstWarehouse.availableStock) {
            firstWarehouse.qtyController.text = requestedQty.toString();
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar stock: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _addItem() {
    setState(() {
      _items.add(_OrderItem(
        productId: null,
        qtyController: TextEditingController(text: '1'),
        priceController: TextEditingController(),
        discountController: TextEditingController(text: '0'),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].qtyController.dispose();
      _items[index].priceController.dispose();
      _items[index].discountController.dispose();
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

  double _calculateSubtotal(_OrderItem item) {
    final qty = double.tryParse(item.qtyController.text) ?? 0;
    final price = double.tryParse(item.priceController.text) ?? 0;
    return qty * price;
  }

  double get _subtotal {
    return _items.fold(0, (sum, item) => sum + _calculateSubtotal(item));
  }

  double get _totalDiscount {
    return _items.fold(0, (sum, item) {
      return sum + (double.tryParse(item.discountController.text) ?? 0);
    });
  }

  double get _total {
    return _subtotal - _totalDiscount;
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    // Validar distribuciones de almacén
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.productId != null && item.warehouseAllocations.isNotEmpty) {
        final requestedQty = double.tryParse(item.qtyController.text) ?? 0;
        final allocatedQty = _getTotalAllocated(item);
        
        if ((allocatedQty - requestedQty).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ítem ${i + 1}: La distribución por almacén (${allocatedQty.toStringAsFixed(0)}) debe coincidir con la cantidad solicitada (${requestedQty.toStringAsFixed(0)})'
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
      final items = _items.map((item) {
        // Preparar distribuciones de almacén si existen
        final allocations = item.warehouseAllocations
            .where((alloc) => (double.tryParse(alloc.qtyController.text) ?? 0) > 0)
            .map((alloc) => {
                  'warehouseId': alloc.warehouseId,
                  'qty': double.parse(alloc.qtyController.text),
                })
            .toList();

        return {
          'productId': item.productId!,
          'qty': double.parse(item.qtyController.text),
          'unitPrice': double.parse(item.priceController.text),
          'discount': double.parse(item.discountController.text),
          if (allocations.isNotEmpty) 'warehouseAllocations': allocations,
        };
      }).toList();

      await _salesOrderService.create(
        customerId: _selectedCustomerId!,
        items: items,
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
      item.qtyController.dispose();
      item.priceController.dispose();
      item.discountController.dispose();
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
        title: const Text('Nueva Orden de Venta'),
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
                          // Cliente
                          DropdownButtonFormField<String>(
                            value: _selectedCustomerId,
                            decoration: InputDecoration(
                              labelText: 'Cliente *',
                              hintText: 'Seleccionar cliente...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              prefixIcon: const Icon(Icons.person),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            ),
                            style: const TextStyle(fontSize: 16),
                            items: _customers.map((customer) {
                              return DropdownMenuItem(
                                // ignore: deprecated_member_use
                                value: customer.id,
                                child: Text(customer.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCustomerId = value);
                            },
                            validator: (value) =>
                                value == null ? 'Selecciona un cliente' : null,
                          ),

                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PRODUCTOS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Items
                          ..._items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return _buildItemCard(item, index);
                          }),

                          // Botón agregar item
                          OutlinedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Ítem'),
                          ),

                          const SizedBox(height: 24),

                          // Totales
                          Card(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildTotalRow('Subtotal:', _subtotal),
                                  const SizedBox(height: 8),
                                  _buildTotalRow('Descuentos:', -_totalDiscount,
                                      isDiscount: true),
                                  const Divider(height: 24),
                                  _buildTotalRow('Total:', _total, isBold: true),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer con botón guardar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveOrder,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: LoadingIndicator.small(),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Guardando...' : 'Crear Orden'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildItemCard(_OrderItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                if (_items.length > 1)
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
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: item.productId,
              decoration: InputDecoration(
                labelText: 'Producto',
                hintText: 'Seleccionar producto...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                prefixIcon: Icon(
                  Icons.inventory_2_outlined,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              style: const TextStyle(fontSize: 15),
              isExpanded: true,
              items: _products.map((product) {
                final stock = product.stockTotal ?? 0;
                return DropdownMenuItem(
                  // ignore: deprecated_member_use
                  value: product.id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: stock == 0
                              ? Colors.red.withValues(alpha: 0.1)
                              : stock <= (product.minStock ?? 0)
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${stock.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stock == 0
                                ? Colors.red.shade700
                                : stock <= (product.minStock ?? 0)
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  item.productId = value;
                  // Cargar stock por almacén cuando se selecciona un producto
                  if (value != null) {
                    _loadWarehouseStock(value, item);
                  }
                });
              },
              validator: (value) =>
                  value == null ? 'Selecciona un producto' : null,
            ),
            // Mostrar distribución por almacén si el producto está seleccionado
            if (item.productId != null && item.warehouseAllocations.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildWarehouseAllocationSection(item),
            ],
            const SizedBox(height: 20),
            // Cantidad en fila completa
            TextFormField(
              controller: item.qtyController,
              decoration: InputDecoration(
                labelText: 'Cantidad',
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                errorMaxLines: 2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                prefixIcon: const Icon(Icons.shopping_cart_outlined),
                suffixIcon: item.productId != null
                    ? _buildStockWarningIcon(item)
                    : null,
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requerido';
                }
                final qty = double.tryParse(value);
                if (qty == null || qty <= 0) {
                  return 'Cantidad inválida';
                }
                
                // Validar stock disponible
                if (item.productId != null) {
                  final product = _products.firstWhere(
                    (p) => p.id == item.productId,
                    orElse: () => _products.first,
                  );
                  final stock = product.stockTotal ?? 0;
                  if (qty > stock) {
                    return 'Stock insuficiente (disponible: ${stock.toStringAsFixed(0)})';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Precio y descuento en fila
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.priceController,
                    decoration: InputDecoration(
                      labelText: 'Precio Unitario',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Precio inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.discountController,
                    decoration: InputDecoration(
                      labelText: 'Descuento',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      prefixIcon: const Icon(Icons.discount_outlined),
                    ),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final discount = double.tryParse(value);
                      if (discount == null || discount < 0) {
                        return 'Descuento inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calculate_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Subtotal:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${_calculateSubtotal(item).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Theme.of(context).colorScheme.primary,
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

  Widget? _buildStockWarningIcon(_OrderItem item) {
    if (item.productId == null) return null;
    
    final product = _products.firstWhere(
      (p) => p.id == item.productId,
      orElse: () => _products.first,
    );
    final stock = product.stockTotal ?? 0;
    final qty = double.tryParse(item.qtyController.text) ?? 0;
    
    if (qty > stock) {
      return Tooltip(
        message: 'Stock insuficiente',
        child: Icon(
          Icons.error,
          color: Theme.of(context).colorScheme.error,
          size: 20,
        ),
      );
    } else if (qty > 0 && stock - qty <= (product.minStock ?? 0)) {
      return Tooltip(
        message: 'Quedará por debajo del stock mínimo',
        child: Icon(
          Icons.warning,
          color: Colors.orange,
          size: 20,
        ),
      );
    }
    return null;
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isDiscount = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)} USD',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
            color: isDiscount
                ? Colors.red
                : (isBold ? Theme.of(context).colorScheme.primary : null),
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseAllocationSection(_OrderItem item) {
    final requestedQty = double.tryParse(item.qtyController.text) ?? 0;
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
                      'Especifica de dónde sacar',
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
          ...item.warehouseAllocations.asMap().entries.map((entry) {
            final alloc = entry.value;
            final allocQty = double.tryParse(alloc.qtyController.text) ?? 0;
            final hasError = allocQty > alloc.availableStock;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasError 
                      ? Theme.of(context).colorScheme.error 
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alloc.warehouseName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Disponible: ${alloc.availableStock.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                        fillColor: hasError 
                            ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.surface,
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final qty = double.tryParse(value);
                        if (qty == null || qty < 0) {
                          return '';
                        }
                        if (qty > alloc.availableStock) {
                          return '';
                        }
                        return null;
                      },
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
  String? productId;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final TextEditingController discountController;
  final List<_WarehouseAllocation> warehouseAllocations;

  _OrderItem({
    this.productId,
    required this.qtyController,
    required this.priceController,
    required this.discountController,
  }) : warehouseAllocations = [];
}

class _WarehouseAllocation {
  final String warehouseId;
  final String warehouseName;
  final double availableStock;
  final TextEditingController qtyController;

  _WarehouseAllocation({
    required this.warehouseId,
    required this.warehouseName,
    required this.availableStock,
    required this.qtyController,
  });

  void dispose() {
    qtyController.dispose();
  }
}
