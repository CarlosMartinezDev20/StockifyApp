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

  List<Customer> _customers = [];
  List<Product> _products = [];
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
      
      setState(() {
        _customers = customers;
        _products = products;
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
      _items.removeAt(index);
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

    setState(() => _isSaving = true);

    try {
      final items = _items.map((item) {
        return {
          'productId': item.productId!,
          'qty': double.parse(item.qtyController.text),
          'unitPrice': double.parse(item.priceController.text),
          'discount': double.parse(item.discountController.text),
        };
      }).toList();

      await _salesOrderService.create(
        customerId: _selectedCustomerId!,
        items: items,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear orden: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.qtyController.dispose();
      item.priceController.dispose();
      item.discountController.dispose();
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
                            decoration: const InputDecoration(
                              labelText: 'Cliente *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
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

                          const SizedBox(height: 24),
                          const Text(
                            'ITEMS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),

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
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Producto ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _removeItem(index),
                    color: Theme.of(context).colorScheme.error,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: item.productId,
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              isExpanded: true,
              items: _products.map((product) {
                return DropdownMenuItem(
                  // ignore: deprecated_member_use
                  value: product.id,
                  child: Text(
                    product.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  item.productId = value;
                });
              },
              validator: (value) =>
                  value == null ? 'Selecciona un producto' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: item.qtyController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
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
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: item.priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio Unit.',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '\$',
                    ),
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
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: item.discountController,
                    decoration: const InputDecoration(
                      labelText: 'Descuento',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final discount = double.tryParse(value);
                      if (discount == null || discount < 0) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Subtotal: \$${_calculateSubtotal(item).toStringAsFixed(2)} USD',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
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
}

class _OrderItem {
  String? productId;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final TextEditingController discountController;

  _OrderItem({
    this.productId,
    required this.qtyController,
    required this.priceController,
    required this.discountController,
  });
}
