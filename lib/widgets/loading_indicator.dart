import 'package:flutter/material.dart';

/// Widget de carga interactivo siguiendo Material Design 3
/// con animaciones suaves y efectos visuales mejorados
class LoadingIndicator extends StatefulWidget {
  /// Tamaño del indicador (por defecto: 48.0)
  final double size;
  
  /// Grosor del trazo (por defecto: 4.0)
  final double strokeWidth;
  
  /// Color personalizado (usa el color primario del tema si es null)
  final Color? color;
  
  /// Mensaje de carga opcional
  final String? message;
  
  /// Si se debe mostrar una animación de pulso en el fondo
  final bool showPulse;

  const LoadingIndicator({
    super.key,
    this.size = 48.0,
    this.strokeWidth = 4.0,
    this.color,
    this.message,
    this.showPulse = true,
  });

  /// Constructor para un indicador pequeño (botones)
  const LoadingIndicator.small({
    super.key,
    this.size = 20.0,
    this.strokeWidth = 2.5,
    this.color,
    this.message,
    this.showPulse = false,
  });

  /// Constructor para pantalla completa con mensaje
  const LoadingIndicator.fullScreen({
    super.key,
    this.size = 56.0,
    this.strokeWidth = 4.5,
    this.color,
    this.message = 'Cargando...',
    this.showPulse = true,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animación de rotación optimizada
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    
    _rotationAnimation = _rotationController;

    // Animación de pulso optimizada
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(_pulseController);

    // Animación de fade-in inicial optimizada
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = _fadeController;
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = widget.color ?? colorScheme.primary;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Efecto de pulso en el fondo
                if (widget.showPulse)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: widget.size * 2,
                        height: widget.size * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: effectiveColor.withValues(alpha: 0.1 * _pulseAnimation.value),
                        ),
                      );
                    },
                  ),
                
                // Indicador circular principal
                RotationTransition(
                  turns: _rotationAnimation,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      strokeWidth: widget.strokeWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
              ],
            ),
            
            // Mensaje opcional
            if (widget.message != null) ...[
              SizedBox(height: widget.size * 0.4),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.5 + (0.5 * _pulseAnimation.value),
                    child: Text(
                      widget.message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget de carga con esqueleto para listas
class SkeletonLoader extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80.0,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = _shimmerController;
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Container(
              height: widget.itemHeight,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            colorScheme.surface.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                          stops: [
                            _shimmerAnimation.value - 0.3,
                            _shimmerAnimation.value,
                            _shimmerAnimation.value + 0.3,
                          ].map((e) => e.clamp(0.0, 1.0)).toList(),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 16,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 12,
                                width: 150,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              );
            },
          ),
        );
      },
    );
  }
}
