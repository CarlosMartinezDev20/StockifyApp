import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = crear nuevo, con data = editar

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  late TextEditingController _skuController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _minStockController;
  late TextEditingController _barcodeController;

  List<Category> _categories = [];
  String? _selectedCategoryId;
  String _selectedUnit = 'EA';
  bool _isLoading = false;
  bool _loadingCategories = true;

  final List<String> _units = ['EA', 'BOX', 'KG', 'L'];
  final Map<String, String> _unitLabels = {
    'EA': 'Unidad (EA)',
    'BOX': 'Caja (BOX)',
    'KG': 'Kilogramo (KG)',
    'L': 'Litro (L)',
  };

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadCategories();
  }

  void _initControllers() {
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _minStockController = TextEditingController(
      text: widget.product?.minStock?.toString() ?? '',
    );
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _selectedCategoryId = widget.product?.categoryId;
    _selectedUnit = widget.product?.unit ?? 'EA';
    
    // Generar SKU automáticamente solo al crear nuevo producto
    if (widget.product == null) {
      _nameController.addListener(_generateSku);
    }
  }
  
  void _generateSku() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _skuController.text = '';
      return;
    }
    
    // Convertir nombre a SKU: MAYÚSCULAS, sin espacios, sin acentos
    String sku = name.toUpperCase();
    
    // Remover acentos
    const accents = 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÄËÏÖÜÃÕÑÇáéíóúàèìòùâêîôûäëïöüãõñç';
    const noAccents = 'AEIOUAEIOUAEIOUAEIOUAONCaeiouaeiouaeiouaeiouaonc';
    
    for (int i = 0; i < accents.length; i++) {
      sku = sku.replaceAll(accents[i], noAccents[i]);
    }
    
    // Remover caracteres especiales
    sku = sku.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    // Tomar las primeras 3 letras (o menos si el nombre es corto)
    String prefix = sku.length >= 3 ? sku.substring(0, 3) : sku.padRight(3, 'X');
    
    // Generar número de 4 dígitos más compacto (evita ceros al inicio)
    // Usa los últimos dígitos del timestamp + un random para evitar colisiones
    final now = DateTime.now();
    final timePart = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    
    _skuController.text = '$prefix-$timePart';
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAll();
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _loadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar categorías: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (widget.product == null) {
      _nameController.removeListener(_generateSku);
    }
    _skuController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _minStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.product == null) {
        // Crear nuevo producto
        await _productService.create(
          sku: _skuController.text.trim(),
          name: _nameController.text.trim(),
          categoryId: _selectedCategoryId!,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          unit: _selectedUnit,
          minStock: _minStockController.text.isNotEmpty
              ? double.tryParse(_minStockController.text)
              : null,
          barcode: _barcodeController.text.trim().isNotEmpty
              ? _barcodeController.text.trim()
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // true = actualizar lista
        }
      } else {
        // Actualizar producto existente
        await _productService.update(
          widget.product!.id,
          {
            'sku': _skuController.text.trim(),
            'name': _nameController.text.trim(),
            'categoryId': _selectedCategoryId,
            'description': _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            'unit': _selectedUnit,
            'minStock': _minStockController.text.isNotEmpty
                ? double.tryParse(_minStockController.text)
                : null,
            'barcode': _barcodeController.text.trim().isNotEmpty
                ? _barcodeController.text.trim()
                : null,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
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
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        actions: [
          if (_isLoading)
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
      body: _loadingCategories
          ? const LoadingIndicator.fullScreen(
              message: 'Cargando datos...',
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // SKU
                  TextFormField(
                    controller: _skuController,
                    decoration: InputDecoration(
                      labelText: 'SKU *',
                      hintText: isEditing ? 'Código único del producto' : 'Se genera automáticamente',
                      prefixIcon: const Icon(Icons.qr_code),
                      border: const OutlineInputBorder(),
                      suffixIcon: !isEditing ? const Icon(Icons.auto_awesome, size: 20) : null,
                      helperText: !isEditing ? 'Generado desde el nombre' : null,
                    ),
                    readOnly: true, // Siempre solo lectura
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El SKU es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nombre
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      hintText: 'Nombre del producto',
                      prefixIcon: Icon(Icons.inventory_2),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Categoría
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona una categoría';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Unidad de medida
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unidad de Medida *',
                      prefixIcon: Icon(Icons.straighten),
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(_unitLabels[unit] ?? unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Descripción detallada del producto',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Stock mínimo
                  TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock Mínimo',
                      hintText: 'Cantidad mínima de alerta',
                      prefixIcon: Icon(Icons.warning_amber),
                      border: OutlineInputBorder(),
                      suffixText: 'unidades',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Código de barras
                  TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Código de Barras',
                      hintText: 'Código de barras del producto',
                      prefixIcon: Icon(Icons.barcode_reader),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _saveProduct,
                          icon: _isLoading
                              ? const LoadingIndicator.small(
                                  color: Colors.white,
                                )
                              : Icon(isEditing ? Icons.save : Icons.add),
                          label: Text(isEditing ? 'Guardar' : 'Crear Producto'),
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
