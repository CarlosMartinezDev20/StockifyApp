import 'dart:async';
import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'purchase_order_form_screen.dart';
import 'purchase_order_detail_screen.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> with PermissionsMixin {
  final PurchaseOrderService _purchaseOrderService = PurchaseOrderService();
  final WarehouseService _warehouseService = WarehouseService();
  List<PurchaseOrder> _allOrders = [];
  List<PurchaseOrder> _filteredOrders = [];
  List<Warehouse> _warehouses = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all'; // all, draft, ordered, received, cancelled
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    loadUserRole();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final warehouses = await _warehouseService.getAll();
      final orders = await _purchaseOrderService.getAll();
      setState(() {
        _warehouses = warehouses;
        _allOrders = orders;
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
    List<PurchaseOrder> filtered = List.from(_allOrders);

    // Aplicar filtro de estado
    if (_selectedStatus != 'all') {
      filtered = filtered.where((o) => o.status.toLowerCase() == _selectedStatus.toLowerCase()).toList();
    }

    // Aplicar búsqueda
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((o) {
        final supplierName = o.supplierName?.toLowerCase() ?? '';
        final orderId = o.id.toLowerCase();
        return supplierName.contains(query) || orderId.contains(query);
      }).toList();
    }

    setState(() {
      _filteredOrders = filtered;
    });
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
  }

  Future<void> _confirmOrder(PurchaseOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Orden'),
        content: Text(
          '¿Confirmas que deseas ordenar estos productos al proveedor?\n\nOrden #${order.id.substring(0, 8)}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _purchaseOrderService.confirm(order.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden confirmada correctamente'),
            backgroundColor: Colors.blue,
          ),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar orden: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _receiveOrder(PurchaseOrder order) async {
    // Cargar almacenes
    List<Warehouse> warehouses;
    try {
      warehouses = await _warehouseService.getAll();
      if (warehouses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay almacenes disponibles'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar almacenes: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recibir Mercancía'),
        content: Text(
          '¿Confirmas que deseas recibir la mercancía de la orden #${order.id.substring(0, 8)}?\n\n'
          'Los productos se agregarán a los almacenes especificados al crear la orden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recibir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // El backend usa las allocations guardadas en memoria desde create()
      await _purchaseOrderService.receive(order.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mercancía recibida correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      }
    } catch (e) {
      // Si falla, puede ser una orden vieja sin allocations
      final errorMsg = e.toString();
      if (errorMsg.contains('No stored allocations') || errorMsg.contains('POST')) {
        // Mostrar diálogo para recepción manual
        await _receiveOrderManually(order);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al recibir mercancía: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _receiveOrderManually(PurchaseOrder order) async {
    String? selectedWarehouseId;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Recepción Manual'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Esta orden no tiene distribución guardada.\nSelecciona un almacén para recibirla:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedWarehouseId,
                decoration: const InputDecoration(
                  labelText: 'Almacén',
                  border: OutlineInputBorder(),
                ),
                items: _warehouses.map((w) {
                  return DropdownMenuItem(
                    value: w.id,
                    child: Text(w.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedWarehouseId = value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Se recibirán todas las cantidades ordenadas.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selectedWarehouseId == null
                  ? null
                  : () => Navigator.of(context).pop(true),
              child: const Text('Recibir'),
            ),
          ],
        ),
      ),
    );

    if (result != true || selectedWarehouseId == null) return;

    try {
      // Crear mapa de cantidades
      final receivedQuantities = <String, double>{};
      for (var item in order.items) {
        receivedQuantities[item.id] = item.qtyOrdered;
      }

      await _purchaseOrderService.receiveManual(
        order.id,
        warehouseId: selectedWarehouseId!,
        receivedQuantities: receivedQuantities,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mercancía recibida correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes de Compra'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar por proveedor o ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                ),
              ),
              // Filtros de estado
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('Todos', 'all'),
                    _buildFilterChip('Borrador', 'draft'),
                    _buildFilterChip('Ordenadas', 'ordered'),
                    _buildFilterChip('Recibidas', 'received'),
                    _buildFilterChip('Canceladas', 'cancelled'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _buildContent(),
      floatingActionButton: hasPermission('purchase_orders.create')
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PurchaseOrderFormScreen(),
                  ),
                );
                
                if (result == true) {
                  _loadOrders();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Orden'),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingIndicator.fullScreen(
        message: 'Cargando órdenes de compra...',
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
              'Error al cargar órdenes',
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
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_allOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay órdenes de compra',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera orden de compra',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_filteredOrders.isEmpty) {
      return AnimatedEmptyState(
        icon: Icons.filter_list_off,
        title: 'No hay órdenes con este filtro',
        message: 'Intenta con otro filtro o limpia la búsqueda.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          return RepaintBoundary(
            key: ValueKey('purchase_order_${order.id}'),
            child: _PurchaseOrderCard(
              order: order,
              index: index,
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PurchaseOrderDetailScreen(orderId: order.id),
                  ),
                );
                
                if (result == true) {
                  _loadOrders();
                }
              },
              onConfirm: () async {
                await _confirmOrder(order);
              },
              onReceive: () async {
                await _receiveOrder(order);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final VoidCallback onReceive;
  final int index;

  const _PurchaseOrderCard({
    required this.order,
    required this.onTap,
    required this.onConfirm,
    required this.onReceive,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #${order.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.supplierName ?? 'Proveedor ID: ${order.supplierId.substring(0, 8)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(order.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Icon(
                  Icons.list_alt,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${order.items.length} item(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (order.status.toUpperCase() == 'DRAFT') ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Confirmar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
            if (order.status.toUpperCase() == 'ORDERED') ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: onReceive,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Recibir'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (order.status.toUpperCase()) {
      case 'DRAFT':
        return Colors.grey;
      case 'ORDERED':
        return Colors.blue;
      case 'RECEIVED':
        return Colors.green;
      case 'CANCELLED':
        return colorScheme.error;
      default:
        return colorScheme.primary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'Borrador';
      case 'ORDERED':
        return 'Ordenada';
      case 'RECEIVED':
        return 'Recibida';
      case 'CANCELLED':
        return 'Cancelada';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
