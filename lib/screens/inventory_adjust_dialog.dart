import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class InventoryAdjustDialog extends StatefulWidget {
  final String? preSelectedProductId;
  final String? preSelectedWarehouseId;
  
  const InventoryAdjustDialog({
    super.key,
    this.preSelectedProductId,
    this.preSelectedWarehouseId,
  });

  @override
  State<InventoryAdjustDialog> createState() => _InventoryAdjustDialogState();
}

class _InventoryAdjustDialogState extends State<InventoryAdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  
  final ProductService _productService = ProductService();
  final WarehouseService _warehouseService = WarehouseService();
  final InventoryService _inventoryService = InventoryService();
  
  List<Product> _products = [];
  List<Warehouse> _warehouses = [];
  Product? _selectedProduct;
  Warehouse? _selectedWarehouse;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final products = await _productService.getAll();
      final warehouses = await _warehouseService.getAll();
      
      // Pre-seleccionar producto y almacén si se pasaron
      Product? preSelectedProduct;
      Warehouse? preSelectedWarehouse;
      
      if (widget.preSelectedProductId != null) {
        preSelectedProduct = products.firstWhere(
          (p) => p.id == widget.preSelectedProductId,
          orElse: () => products.first,
        );
      }
      
      if (widget.preSelectedWarehouseId != null) {
        preSelectedWarehouse = warehouses.firstWhere(
          (w) => w.id == widget.preSelectedWarehouseId,
          orElse: () => warehouses.first,
        );
      }
      
      setState(() {
        _products = products;
        _warehouses = warehouses;
        _selectedProduct = preSelectedProduct;
        _selectedWarehouse = preSelectedWarehouse;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AnimatedSnackBar.showError(
          context,
          'Error al cargar datos: $e',
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveAdjustment() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedProduct == null) {
      AnimatedSnackBar.showWarning(
        context,
        'Por favor selecciona un producto',
      );
      return;
    }
    
    if (_selectedWarehouse == null) {
      AnimatedSnackBar.showWarning(
        context,
        'Por favor selecciona un almacén',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final quantity = double.parse(_quantityController.text);
      
      await _inventoryService.adjust(
        productId: _selectedProduct!.id,
        warehouseId: _selectedWarehouse!.id,
        quantity: quantity,
        reason: _reasonController.text.trim().isEmpty 
            ? null 
            : _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        AnimatedSnackBar.showSuccess(
          context,
          'Inventario ajustado exitosamente',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AnimatedSnackBar.showError(
          context,
          'Error al ajustar inventario: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar Inventario'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: LoadingIndicator.small(),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator.fullScreen(
              message: 'Cargando datos...',
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Producto
                  // ignore: deprecated_member_use
                  DropdownButtonFormField<Product>(
                    decoration: const InputDecoration(
                      labelText: 'Producto *',
                      hintText: 'Selecciona un producto',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    isExpanded: true,
                    // ignore: deprecated_member_use
                    value: _selectedProduct,
                    items: _products.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Text(
                          '${product.name} (${product.sku})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _isSaving ? null : (product) {
                      setState(() => _selectedProduct = product);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un producto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Almacén
                  // ignore: deprecated_member_use
                  DropdownButtonFormField<Warehouse>(
                    decoration: const InputDecoration(
                      labelText: 'Almacén *',
                      hintText: 'Selecciona un almacén',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warehouse),
                    ),
                    isExpanded: true,
                    // ignore: deprecated_member_use
                    value: _selectedWarehouse,
                    items: _warehouses.map((warehouse) {
                      return DropdownMenuItem(
                        value: warehouse,
                        child: Text(
                          warehouse.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _isSaving ? null : (warehouse) {
                      setState(() => _selectedWarehouse = warehouse);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un almacén';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nueva Cantidad
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Cantidad *',
                      hintText: 'Cantidad total actualizada',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                      suffixText: 'unidades',
                      helperText: 'Esta será la cantidad total en el almacén',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ],
                    enabled: !_isSaving,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa una cantidad';
                      }
                      final number = double.tryParse(value);
                      if (number == null) {
                        return 'Ingresa un número válido';
                      }
                      if (number < 0) {
                        return 'La cantidad no puede ser negativa';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Motivo
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo',
                      hintText: 'Motivo del ajuste (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveAdjustment,
                          icon: _isSaving
                              ? const LoadingIndicator.small(
                                  color: Colors.white,
                                )
                              : const Icon(Icons.check),
                          label: const Text('Ajustar Inventario'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
