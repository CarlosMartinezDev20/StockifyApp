import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'inventory_adjust_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with PermissionsMixin {
  final InventoryService _inventoryService = InventoryService();
  final WarehouseService _warehouseService = WarehouseService();
  List<InventoryLevel> _inventoryLevels = [];
  List<Warehouse> _warehouses = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedWarehouseId;

  @override
  void initState() {
    super.initState();
    loadUserRole();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final warehouses = await _warehouseService.getAll();
      final inventoryLevels = await _inventoryService.getLevels(
        warehouseId: _selectedWarehouseId,
      );
      
      setState(() {
        _warehouses = warehouses;
        _inventoryLevels = inventoryLevels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterByWarehouse(String? warehouseId) {
    setState(() {
      _selectedWarehouseId = warehouseId;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          if (hasPermission('inventory.adjust'))
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Ajustar Inventario',
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const InventoryAdjustDialog(),
                  ),
                );
                
                if (result == true) {
                  _loadData();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtro por almacén
          if (_warehouses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              // ignore: deprecated_member_use
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Almacén',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warehouse),
                ),
                // ignore: deprecated_member_use
                value: _selectedWarehouseId,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos los almacenes'),
                  ),
                  ..._warehouses.map((warehouse) {
                    return DropdownMenuItem(
                      value: warehouse.id,
                      child: Text(warehouse.name),
                    );
                  }),
                ],
                onChanged: _filterByWarehouse,
              ),
            ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingIndicator.fullScreen(
        message: 'Cargando inventario...',
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
              'Error al cargar inventario',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_inventoryLevels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay registros de inventario',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos a los almacenes',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _inventoryLevels.length,
        itemBuilder: (context, index) {
          final level = _inventoryLevels[index];
          return _InventoryCard(
            level: level,
            onAdjust: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => InventoryAdjustDialog(
                    preSelectedProductId: level.productId,
                    preSelectedWarehouseId: level.warehouseId,
                  ),
                ),
              );
              
              if (result == true) {
                _loadData();
              }
            },
          );
        },
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryLevel level;
  final VoidCallback onAdjust;

  const _InventoryCard({
    required this.level,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stockColor = _getStockColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAdjust,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
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
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.productName ?? 'Producto',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.warehouse,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                level.warehouseName ?? 'Almacén',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: stockColor, width: 2),
                    ),
                    child: Text(
                      '${level.quantity.toInt()}',
                      style: TextStyle(
                        color: stockColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onAdjust,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Ajustar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStockColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stock = level.quantity;

    if (stock == 0) {
      return colorScheme.error;
    } else if (stock <= 10) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
