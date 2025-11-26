import 'dart:async';
import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'customer_form_screen.dart';
import 'customer_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> with SingleTickerProviderStateMixin {
  final CustomerService _customerService = CustomerService();
  List<Customer> _clients = [];
  List<Customer> _filteredClients = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'name'; // name, email, recent
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    );
    _loadClients();
  }
  
  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clients = await _customerService.getAll();
      setState(() {
        _clients = clients;
        _applySortAndFilter();
        _isLoading = false;
      });
      // Animar FAB después de cargar
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _fabController.forward();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySortAndFilter() {
    List<Customer> filtered = List.from(_clients);

    // Aplicar búsqueda
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query) ||
            (c.email?.toLowerCase().contains(query) ?? false) ||
            (c.phone?.contains(query) ?? false);
      }).toList();
    }

    // Aplicar ordenamiento
    if (_sortBy == 'name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'email') {
      filtered.sort((a, b) {
        final emailA = a.email ?? '';
        final emailB = b.email ?? '';
        return emailA.compareTo(emailB);
      });
    } else if (_sortBy == 'recent') {
      filtered = filtered.reversed.toList(); // Más recientes primero
    }

    setState(() {
      _filteredClients = filtered;
    });
  }

  Future<void> _deleteClient(Customer client) async {
    final confirmed = await AnimatedConfirmDialog.show(
      context,
      title: 'Eliminar Cliente',
      message: '¿Estás seguro de eliminar a "${client.name}"?\n\nEsta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      icon: Icons.delete_forever,
    );

    if (!confirmed) return;

    try {
      await _customerService.delete(client.id);
      
      if (mounted) {
        AnimatedSnackBar.showSuccess(
          context,
          'Cliente eliminado correctamente',
        );
        _loadClients();
      }
    } catch (e) {
      if (mounted) {
        AnimatedSnackBar.showError(
          context,
          'Error al eliminar cliente: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          // Bot\u00f3n de ordenamiento
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _applySortAndFilter();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortBy == 'name' ? Theme.of(context).colorScheme.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text('Por nombre', style: TextStyle(
                      fontWeight: _sortBy == 'name' ? FontWeight.bold : null,
                    )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'email',
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: _sortBy == 'email' ? Theme.of(context).colorScheme.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text('Por email', style: TextStyle(
                      fontWeight: _sortBy == 'email' ? FontWeight.bold : null,
                    )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: _sortBy == 'recent' ? Theme.of(context).colorScheme.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text('M\u00e1s recientes', style: TextStyle(
                      fontWeight: _sortBy == 'recent' ? FontWeight.bold : null,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de b\u00fasqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar por nombre, email o tel\u00e9fono...',
              leading: const Icon(Icons.search),
              trailing: _searchController.text.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applySortAndFilter();
                        },
                      ),
                    ]
                  : null,
              onChanged: (value) {
                // Debounce para búsqueda eficiente
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  _applySortAndFilter();
                });
              },
            ),
          ),
          // Resultado de búsqueda
          if (!_isLoading && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Mostrando ${_filteredClients.length} de ${_clients.length} cliente${_clients.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Lista de clientes
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          heroTag: 'add_client_fab',
          onPressed: () async {
            final result = await Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const CustomerFormScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 250),
              ),
            );
            
            if (result == true) {
              _loadClients();
            }
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Nuevo Cliente'),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingIndicator.fullScreen(
        message: 'Cargando clientes...',
      );
    }

    if (_error != null) {
      return AnimatedErrorState(
        title: 'Error al cargar clientes',
        message: _error!,
        onRetry: _loadClients,
      );
    }

    if (_filteredClients.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        // Mostrar cuando no hay resultados de búsqueda
        return AnimatedEmptyState(
          icon: Icons.search_off,
          title: 'No se encontraron clientes',
          message: 'Intenta con otros términos de búsqueda',
        );
      }
      // Mostrar cuando no hay clientes en absoluto
      return AnimatedEmptyState(
        icon: Icons.people_outlined,
        title: 'No hay clientes',
        message: 'Comienza agregando tu primer cliente para gestionar tus ventas',
        actionText: 'Agregar Cliente',
        onAction: () async {
          final result = await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const CustomerFormScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
          if (result == true) _loadClients();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClients,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _filteredClients.length,
        itemBuilder: (context, index) {
          final client = _filteredClients[index];
          return RepaintBoundary(
            key: ValueKey('client_${client.id}'),
            child: _ClientCard(
              client: client,
              index: index,
            onTap: () async {
              final result = await Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      CustomerDetailScreen(customerId: _filteredClients[index].id),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
              
              if (result == true) {
                _loadClients();
              }
            },
            onEdit: () async {
              final result = await Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      CustomerFormScreen(customer: _clients[index]),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 250),
                ),
              );
              
              if (result == true) {
                _loadClients();
              }
            },
            onDelete: () => _deleteClient(client),
            ),
          );
        },
      ),
    );
  }
}

class _ClientCard extends StatefulWidget {
  final Customer client;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int index;

  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.index,
  });

  @override
  State<_ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<_ClientCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_controller);

    // Limitar delay máximo a 100ms para mejor fluidez
    final delayMs = (10 * widget.index).clamp(0, 100);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Hero(
            tag: 'client_${widget.client.id}',
            child: Material(
              color: Colors.transparent,
              child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            widget.client.name[0].toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.client.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.client.email != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.client.email!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEdit();
                      } else if (value == 'delete') {
                        widget.onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.client.phone != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.client.phone!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
