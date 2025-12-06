import 'dart:async';
import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'sales_order_form_screen.dart';
import 'sales_order_detail_screen.dart';

class SalesOrdersScreen extends StatefulWidget {
  const SalesOrdersScreen({super.key});

  @override
  State<SalesOrdersScreen> createState() => _SalesOrdersScreenState();
}

class _SalesOrdersScreenState extends State<SalesOrdersScreen> with PermissionsMixin {
  final SalesOrderService _salesOrderService = SalesOrderService();
  List<SalesOrder> _orders = [];
  List<SalesOrder> _filteredOrders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all'; // all, pending, confirmed, fulfilled, cancelled
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
      final orders = await _salesOrderService.getAll();
      setState(() {
        _orders = orders;
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
    List<SalesOrder> filtered = List.from(_orders);

    // Aplicar filtro de estado
    if (_selectedStatus != 'all') {
      filtered = filtered.where((o) => o.status == _selectedStatus).toList();
    }

    // Aplicar búsqueda
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((o) {
        final customerName = o.customerName?.toLowerCase() ?? '';
        final orderId = o.id.toLowerCase();
        return customerName.contains(query) || orderId.contains(query);
      }).toList();
    }

    setState(() {
      _filteredOrders = filtered;
    });
  }

  Future<void> _confirmOrder(SalesOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Orden'),
        content: Text(
          '¿Confirmas que deseas procesar esta orden de venta?\n\nOrden #${order.id.substring(0, 8)}'
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
      await _salesOrderService.confirm(order.id);
      
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

  Future<void> _fulfillOrder(SalesOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Orden'),
        content: Text(
          '¿Confirmas que deseas completar la orden #${order.id.substring(0, 8)}?\n\n'
          'El inventario se descontará de los almacenes especificados al crear la orden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Completar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // No se pasa warehouseId porque las allocations ya están guardadas en el backend
      await _salesOrderService.fulfill(order.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden completada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar orden: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _orders.where((o) => o.status == 'pending').length;
    final confirmedCount = _orders.where((o) => o.status == 'confirmed').length;
    final fulfilledCount = _orders.where((o) => o.status == 'fulfilled').length;

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar por cliente o ID...',
              leading: const Icon(Icons.search),
              trailing: _searchController.text.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      ),
                    ]
                  : null,
              onChanged: (value) {
                // Debounce para evitar filtros excesivos
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  _applyFilters();
                });
              },
            ),
          ),

          // Chips de filtro por estado
          if (!_isLoading)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: Text('Todas (${_orders.length})'),
                    selected: _selectedStatus == 'all',
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = 'all';
                        _applyFilters();
                      });
                    },
                    avatar: _selectedStatus == 'all'
                        ? const Icon(Icons.check_circle, size: 18)
                        : const Icon(Icons.shopping_cart, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('Pendiente ($pendingCount)'),
                    selected: _selectedStatus == 'pending',
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = 'pending';
                        _applyFilters();
                      });
                    },
                    avatar: Icon(
                      Icons.schedule,
                      size: 18,
                      color: _selectedStatus == 'pending'
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('Confirmada ($confirmedCount)'),
                    selected: _selectedStatus == 'confirmed',
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = 'confirmed';
                        _applyFilters();
                      });
                    },
                    avatar: Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: _selectedStatus == 'confirmed'
                          ? Theme.of(context).colorScheme.onTertiaryContainer
                          : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('Completada ($fulfilledCount)'),
                    selected: _selectedStatus == 'fulfilled',
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = 'fulfilled';
                        _applyFilters();
                      });
                    },
                    avatar: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: _selectedStatus == 'fulfilled'
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Lista de órdenes
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: hasPermission('sales_orders.create')
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SalesOrderFormScreen(),
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
        message: 'Cargando órdenes de venta...',
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
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
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

    if (_filteredOrders.isEmpty) {
      return AnimatedEmptyState(
        icon: _selectedStatus == 'all' ? Icons.shopping_cart_outlined : Icons.filter_list_off,
        title: _selectedStatus == 'all' ? 'No hay órdenes de venta' : 'No hay órdenes con este filtro',
        message: _selectedStatus == 'all'
            ? 'Crea tu primera orden de venta'
            : 'Intenta con otro filtro o limpia la búsqueda.',
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
            key: ValueKey('order_${order.id}'),
            child: _SalesOrderCard(
              order: order,
              index: index,
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SalesOrderDetailScreen(orderId: _filteredOrders[index].id),
                ),
              );
              
              if (result == true) {
                _loadOrders();
              }
            },
            onConfirm: () async {
              await _confirmOrder(order);
            },
            onFulfill: () async {
              await _fulfillOrder(order);
            },
            ),
          );
        },
      ),
    );
  }
}

class _SalesOrderCard extends StatelessWidget {
  final SalesOrder order;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final VoidCallback onFulfill;
  final int index;

  const _SalesOrderCard({
    required this.order,
    required this.onTap,
    required this.onConfirm,
    required this.onFulfill,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
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
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: colorScheme.onSecondaryContainer,
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
                          order.customerName ?? 'Cliente ID: ${order.customerId.substring(0, 8)}',
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
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirmar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
              if (order.status.toUpperCase() == 'CONFIRMED') ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: onFulfill,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Completar'),
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
      case 'CONFIRMED':
        return Colors.blue;
      case 'FULFILLED':
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
      case 'CONFIRMED':
        return 'Confirmada';
      case 'FULFILLED':
        return 'Completada';
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
