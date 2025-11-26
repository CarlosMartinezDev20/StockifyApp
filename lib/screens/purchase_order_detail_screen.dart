import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class PurchaseOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const PurchaseOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  final PurchaseOrderService _purchaseOrderService = PurchaseOrderService();
  final WarehouseService _warehouseService = WarehouseService();
  PurchaseOrder? _order;
  bool _isLoading = true;
  bool _isReceiving = false;
  bool _isConfirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final order = await _purchaseOrderService.getById(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmOrder() async {
    if (_order == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Orden'),
        content: const Text('¿Confirmas que deseas ordenar estos productos al proveedor?'),
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

    setState(() => _isConfirming = true);

    try {
      final updatedOrder = await _purchaseOrderService.confirm(widget.orderId);
      
      if (mounted) {
        setState(() {
          _order = updatedOrder;
          _isConfirming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden confirmada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar orden: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _receiveOrder() async {
    if (_order == null) return;

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

    // Mostrar diálogo para seleccionar almacén
    String? selectedWarehouseId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Recibir Mercancía'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Selecciona el almacén donde se recibirá la mercancía:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedWarehouseId,
                decoration: const InputDecoration(
                  labelText: 'Almacén',
                  border: OutlineInputBorder(),
                ),
                items: warehouses.map((warehouse) {
                  return DropdownMenuItem(
                    // ignore: deprecated_member_use
                    value: warehouse.id,
                    child: Text(warehouse.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedWarehouseId = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Se recibirán todas las cantidades ordenadas.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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

    if (confirmed != true || selectedWarehouseId == null) return;

    setState(() => _isReceiving = true);

    try {
      // Crear mapa de cantidades recibidas (todas las cantidades ordenadas)
      final receivedQuantities = <String, double>{};
      for (var item in _order!.items) {
        receivedQuantities[item.id] = item.qtyOrdered;
      }

      await _purchaseOrderService.receive(
        widget.orderId,
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
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReceiving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recibir mercancía: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _order != null 
            ? Text('Orden #${_order!.id.substring(0, 8)}')
            : const Text('Detalle de Orden'),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingIndicator.fullScreen(
        message: 'Cargando orden...',
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
              'Error al cargar orden',
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
              onPressed: _loadOrder,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_order == null) {
      return const Center(child: Text('Orden no encontrada'));
    }

    final order = _order!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDraft = order.status.toUpperCase() == 'DRAFT';
    final canReceive = order.status.toUpperCase() == 'ORDERED';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Información general
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Proveedor',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.supplierName ?? 'ID: ${order.supplierId}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('Estado', _getStatusText(order.status), _getStatusColor(order.status)),
                        const SizedBox(height: 12),
                        _buildInfoRow('Fecha Creación', _formatDate(order.createdAt), null),
                        if (order.expectedAt != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('Fecha Esperada', _formatDate(order.expectedAt!), null),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Items
                Text(
                  'PRODUCTOS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ...order.items.map((item) => _buildItemCard(item)),

                const SizedBox(height: 16),

                // Total
                Card(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${order.total.toStringAsFixed(2)} USD',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Footer con botones de acción
        if (isDraft || canReceive)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
            child: isDraft
                ? FilledButton.icon(
                    onPressed: _isConfirming ? null : _confirmOrder,
                    icon: _isConfirming
                        ? const LoadingIndicator.small()
                        : const Icon(Icons.send),
                    label: Text(_isConfirming ? 'Confirmando...' : 'Confirmar Orden'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.blue,
                    ),
                  )
                : FilledButton.icon(
                    onPressed: _isReceiving ? null : _receiveOrder,
                    icon: _isReceiving
                        ? const LoadingIndicator.small()
                        : const Icon(Icons.check_circle),
                    label: Text(_isReceiving ? 'Recibiendo...' : 'Recibir Mercancía'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(PurchaseOrderItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName ?? 'Producto ID: ${item.productId}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cantidad',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '${item.qtyOrdered.toInt()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precio Unit.',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '\$${item.unitPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Subtotal',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '\$${item.total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Colors.grey;
      case 'ORDERED':
        return Colors.blue;
      case 'RECEIVED':
        return Colors.green;
      case 'CANCELLED':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.primary;
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
