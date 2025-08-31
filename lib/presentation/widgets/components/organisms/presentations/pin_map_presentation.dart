import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/app_theme.dart';
import '../../../../design_system/layout_constants.dart';
import '../../../../responsive/breakpoints.dart';

/// Modelo para pins no mapa
class MapPin {
  final String id;
  final String title;
  final String? description;
  final Offset position; // Posição relativa (0.0 a 1.0)
  final IconData icon;
  final Color color;

  const MapPin({
    required this.id,
    required this.title,
    required this.position,
    this.description,
    this.icon = Icons.place,
    this.color = Colors.red,
  });
}

/// Apresentação de mapa com pins interativos
/// Usado para localização, plantas baixas com pontos de interesse, etc.
class PinMapPresentation extends ConsumerStatefulWidget {
  final String? backgroundImageUrl;
  final List<MapPin>? pins;
  final String? description;
  final String? videoUrl;

  const PinMapPresentation({
    super.key,
    this.backgroundImageUrl,
    this.pins,
    this.description,
    this.videoUrl,
  });

  @override
  ConsumerState<PinMapPresentation> createState() => _PinMapPresentationState();
}

class _PinMapPresentationState extends ConsumerState<PinMapPresentation>
    with TickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  MapPin? _selectedPin;
  late AnimationController _pinAnimationController;
  late Animation<double> _pinAnimation;

  // Mock background image and pins
  final String _mockBackgroundImage =
      'https://placehold.co/1200x800/E8F5E8/2E7D32?text=Mapa+do+Empreendimento';

  final List<MapPin> _mockPins = [
    MapPin(
      id: '1',
      title: 'Entrada Principal',
      description: 'Portaria 24h com segurança',
      position: const Offset(0.2, 0.8),
      icon: Icons.home,
      color: Colors.blue,
    ),
    MapPin(
      id: '2',
      title: 'Torre A',
      description: '120 apartamentos - 3 e 4 quartos',
      position: const Offset(0.4, 0.3),
      icon: Icons.apartment,
      color: Colors.green,
    ),
    MapPin(
      id: '3',
      title: 'Torre B',
      description: '80 apartamentos - 2 e 3 quartos',
      position: const Offset(0.7, 0.3),
      icon: Icons.apartment,
      color: Colors.green,
    ),
    MapPin(
      id: '4',
      title: 'Área de Lazer',
      description: 'Piscina, academia e salão de festas',
      position: const Offset(0.5, 0.6),
      icon: Icons.pool,
      color: Colors.orange,
    ),
    MapPin(
      id: '5',
      title: 'Estacionamento',
      description: '200 vagas cobertas',
      position: const Offset(0.8, 0.7),
      icon: Icons.local_parking,
      color: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pinAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _pinAnimationController, curve: Curves.elasticOut));

    // Start animation loop for pins
    _pinAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pinAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayBackgroundImage = widget.backgroundImageUrl ?? _mockBackgroundImage;
    final displayPins = widget.pins ?? _mockPins;
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background map with pins
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 3.0,
              constrained: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      children: [
                        // Background image
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: displayBackgroundImage,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) {
                              debugPrint('Error loading background image: $error');
                              return Container(
                                color: AppTheme.surfaceColor,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.map_outlined,
                                      size: 64,
                                      color: AppTheme.textSecondary,
                                    ),
                                    SizedBox(height: LayoutConstants.marginMd),
                                    Text(
                                      'Mapa não disponível',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: LayoutConstants.fontSizeLarge,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            placeholder: (context, url) {
                              return Container(
                                color: AppTheme.surfaceColor,
                                child: Center(
                                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                                ),
                              );
                            },
                          ),
                        ),

                        // Pins overlay
                        ...displayPins.map((pin) => _buildPin(pin, constraints)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Top overlay with title and controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + LayoutConstants.paddingMd,
                bottom: LayoutConstants.paddingMd,
                left: LayoutConstants.paddingMd,
                right: LayoutConstants.paddingMd,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                    iconSize: LayoutConstants.iconLarge,
                  ),
                  const Spacer(),
                  
                  // Share button
                  _buildControlButton(
                    icon: Icons.add,
                    onPressed: _shareMap,
                    tooltip: 'Compartilhar',
                  ),
                  SizedBox(width: LayoutConstants.marginXs),
                  
                  // Video player button
                  if (widget.videoUrl != null)
                    _buildControlButton(
                      icon: Icons.play_arrow,
                      onPressed: _playVideo,
                      tooltip: 'Ver vídeo',
                    ),
                  if (widget.videoUrl != null) SizedBox(width: LayoutConstants.marginXs),
                  
                  // Reset zoom button
                  _buildControlButton(
                    icon: Icons.fit_screen,
                    onPressed: _resetZoom,
                    tooltip: 'Ajustar à tela',
                  ),
                ],
              ),
            ),
          ),

          // Pin details overlay
          if (_selectedPin != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + LayoutConstants.paddingMd,
              left: LayoutConstants.paddingMd,
              right: LayoutConstants.paddingMd,
              child: _buildPinDetails(_selectedPin!),
            ),

          // Legend
          if (!isMobile)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              right: LayoutConstants.paddingMd,
              child: _buildLegend(displayPins),
            ),
        ],
      ),
    );
  }

  Widget _buildPin(MapPin pin, BoxConstraints constraints) {
    final left = pin.position.dx * constraints.maxWidth - 24; // 24 = pin width/2
    final top = pin.position.dy * constraints.maxHeight - 48; // 48 = pin height

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _selectPin(pin),
        child: AnimatedBuilder(
          animation: _pinAnimation,
          builder: (context, child) {
            final scale = _selectedPin?.id == pin.id ? _pinAnimation.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pin icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: pin.color,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(pin.icon, color: Colors.white, size: 24),
                  ),

                  // Pin point
                  Container(
                    width: 6,
                    height: 12,
                    decoration: BoxDecoration(
                      color: pin.color,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPinDetails(MapPin pin) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: pin.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(pin.icon, color: Colors.white, size: 18),
              ),
              SizedBox(width: LayoutConstants.marginSm),
              Expanded(
                child: Text(
                  pin.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: LayoutConstants.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedPin = null),
                icon: Icon(Icons.close, color: AppTheme.textSecondary),
              ),
            ],
          ),
          if (pin.description != null) ...[
            SizedBox(height: LayoutConstants.marginSm),
            Text(
              pin.description!,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: LayoutConstants.fontSizeMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend(List<MapPin> pins) {
    final uniqueCategories = <String, MapPin>{};
    for (final pin in pins) {
      final key = '${pin.icon.codePoint}_${pin.color.hashCode}';
      if (!uniqueCategories.containsKey(key)) {
        uniqueCategories[key] = pin;
      }
    }

    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: BoxConstraints(maxWidth: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: LayoutConstants.fontSizeMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: LayoutConstants.marginSm),
          ...uniqueCategories.values.map((pin) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: pin.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(pin.icon, color: Colors.white, size: 12),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _getCategoryName(pin),
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: AppTheme.primaryColor, size: 20),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  String _getCategoryName(MapPin pin) {
    switch (pin.icon) {
      case Icons.home:
        return 'Entrada';
      case Icons.apartment:
        return 'Torres';
      case Icons.pool:
        return 'Lazer';
      case Icons.local_parking:
        return 'Estacionamento';
      default:
        return 'Ponto de Interesse';
    }
  }

  void _selectPin(MapPin pin) {
    setState(() {
      _selectedPin = _selectedPin?.id == pin.id ? null : pin;
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _shareMap() {
    // TODO: Implementar compartilhamento do mapa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartilhamento em desenvolvimento')),
    );
  }

  void _playVideo() {
    // TODO: Implementar player de vídeo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Player de vídeo em desenvolvimento')),
    );
  }
}
