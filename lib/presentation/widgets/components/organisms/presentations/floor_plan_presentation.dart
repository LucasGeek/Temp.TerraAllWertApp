import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/app_theme.dart';
import '../../../../design_system/layout_constants.dart';
import '../../../../responsive/breakpoints.dart';

/// Modelo para unidades no pavimento
class FloorUnit {
  final String id;
  final String number;
  final String type; // 'apartment', 'elevator', 'stairs', 'common'
  final Rect area; // Área relativa (0.0 a 1.0)
  final String? description;
  final bool isAvailable;
  final Color? customColor;

  const FloorUnit({
    required this.id,
    required this.number,
    required this.type,
    required this.area,
    this.description,
    this.isAvailable = true,
    this.customColor,
  });

  Color get color {
    if (customColor != null) return customColor!;

    switch (type) {
      case 'apartment':
        return isAvailable ? Colors.green : Colors.red;
      case 'elevator':
        return Colors.grey[600]!;
      case 'stairs':
        return Colors.blue;
      case 'common':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get label {
    switch (type) {
      case 'apartment':
        return isAvailable ? 'Disponível' : 'Vendido';
      case 'elevator':
        return 'Elevador';
      case 'stairs':
        return 'Escada';
      case 'common':
        return 'Área Comum';
      default:
        return type;
    }
  }
}

/// Apresentação de planta de pavimento com unidades interativas
class FloorPlanPresentation extends ConsumerStatefulWidget {
  final String title;
  final String route;
  final String? floorPlanImageUrl;
  final List<FloorUnit>? units;
  final String? description;
  final String? floorNumber;

  const FloorPlanPresentation({
    super.key,
    required this.title,
    required this.route,
    this.floorPlanImageUrl,
    this.units,
    this.description,
    this.floorNumber,
  });

  @override
  ConsumerState<FloorPlanPresentation> createState() => _FloorPlanPresentationState();
}

class _FloorPlanPresentationState extends ConsumerState<FloorPlanPresentation>
    with TickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  FloorUnit? _selectedUnit;
  late AnimationController _highlightAnimationController;
  late Animation<double> _highlightAnimation;

  // Mock floor plan and units
  final String _mockFloorPlan =
      'https://placehold.co/1000x700/F5F5F5/333333?text=Planta+do+Pavimento';

  final List<FloorUnit> _mockUnits = [
    // Apartments
    FloorUnit(
      id: '101',
      number: '101',
      type: 'apartment',
      area: const Rect.fromLTWH(0.1, 0.1, 0.35, 0.4),
      description: '3 quartos, 2 banheiros, 85m²',
      isAvailable: true,
    ),
    FloorUnit(
      id: '102',
      number: '102',
      type: 'apartment',
      area: const Rect.fromLTWH(0.55, 0.1, 0.35, 0.4),
      description: '2 quartos, 1 banheiro, 65m²',
      isAvailable: false,
    ),
    FloorUnit(
      id: '103',
      number: '103',
      type: 'apartment',
      area: const Rect.fromLTWH(0.1, 0.55, 0.35, 0.4),
      description: '4 quartos, 3 banheiros, 120m²',
      isAvailable: true,
    ),
    FloorUnit(
      id: '104',
      number: '104',
      type: 'apartment',
      area: const Rect.fromLTWH(0.55, 0.55, 0.35, 0.4),
      description: '3 quartos, 2 banheiros, 90m²',
      isAvailable: true,
    ),

    // Common areas
    FloorUnit(
      id: 'elevator1',
      number: 'EL',
      type: 'elevator',
      area: const Rect.fromLTWH(0.46, 0.35, 0.08, 0.1),
      description: 'Elevador social',
    ),
    FloorUnit(
      id: 'stairs1',
      number: 'ESC',
      type: 'stairs',
      area: const Rect.fromLTWH(0.46, 0.45, 0.08, 0.1),
      description: 'Escada de emergência',
    ),
    FloorUnit(
      id: 'hall',
      number: 'HALL',
      type: 'common',
      area: const Rect.fromLTWH(0.46, 0.2, 0.08, 0.15),
      description: 'Hall de entrada',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _highlightAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _highlightAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _highlightAnimationController, curve: Curves.easeInOut));

    _highlightAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _highlightAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayFloorPlan = widget.floorPlanImageUrl ?? _mockFloorPlan;
    final displayUnits = widget.units ?? _mockUnits;
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Main floor plan with units
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              constrained: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Stack(
                      children: [
                        // Background floor plan
                        Positioned.fill(
                          child: Container(
                            margin: EdgeInsets.all(LayoutConstants.paddingXl),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
                              child: Image.network(
                                displayFloorPlan,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppTheme.surfaceColor,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.architecture_outlined,
                                          size: 64,
                                          color: AppTheme.textSecondary,
                                        ),
                                        SizedBox(height: LayoutConstants.marginMd),
                                        Text(
                                          'Planta não disponível',
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
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: AppTheme.surfaceColor,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.primaryColor,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // Units overlay
                        ...displayUnits.map((unit) => _buildUnit(unit, constraints)),
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
                  SizedBox(width: LayoutConstants.marginSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.floorNumber != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'Pavimento ${widget.floorNumber}',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),

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

          // Unit details overlay
          if (_selectedUnit != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + LayoutConstants.paddingMd,
              left: LayoutConstants.paddingMd,
              right: LayoutConstants.paddingMd,
              child: _buildUnitDetails(_selectedUnit!),
            ),

          // Legend
          if (!isMobile)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              right: LayoutConstants.paddingMd,
              child: _buildLegend(),
            ),

          // Statistics panel
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            left: LayoutConstants.paddingMd,
            child: _buildStatistics(displayUnits),
          ),
        ],
      ),
    );
  }

  Widget _buildUnit(FloorUnit unit, BoxConstraints constraints) {
    final margin = LayoutConstants.paddingXl;
    final effectiveWidth = constraints.maxWidth - (margin * 2);
    final effectiveHeight = constraints.maxHeight - (margin * 2);

    final left = margin + (unit.area.left * effectiveWidth);
    final top = margin + (unit.area.top * effectiveHeight);
    final width = unit.area.width * effectiveWidth;
    final height = unit.area.height * effectiveHeight;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => _selectUnit(unit),
        child: AnimatedBuilder(
          animation: _highlightAnimation,
          builder: (context, child) {
            final isSelected = _selectedUnit?.id == unit.id;
            final opacity = isSelected ? _highlightAnimation.value : 0.7;

            return Container(
              decoration: BoxDecoration(
                color: unit.color.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.white : unit.color,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (unit.type == 'apartment') ...[
                      Icon(Icons.home, color: Colors.white, size: width > 60 ? 24 : 16),
                      if (height > 40) SizedBox(height: 4),
                    ],
                    Text(
                      unit.number,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width > 60 ? 14 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnitDetails(FloorUnit unit) {
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
                  color: unit.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  unit.type == 'apartment' ? Icons.home : Icons.location_on,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: LayoutConstants.marginSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.type == 'apartment' ? 'Apartamento ${unit.number}' : unit.number,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: LayoutConstants.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      unit.label,
                      style: TextStyle(
                        color: unit.color,
                        fontSize: LayoutConstants.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedUnit = null),
                icon: Icon(Icons.close, color: AppTheme.textSecondary),
              ),
            ],
          ),
          if (unit.description != null) ...[
            SizedBox(height: LayoutConstants.marginSm),
            Text(
              unit.description!,
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

  Widget _buildLegend() {
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
      constraints: BoxConstraints(maxWidth: 180),
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
          _buildLegendItem('Disponível', Colors.green),
          _buildLegendItem('Vendido', Colors.red),
          _buildLegendItem('Elevador', Colors.grey[600]!),
          _buildLegendItem('Escada', Colors.blue),
          _buildLegendItem('Área Comum', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(List<FloorUnit> units) {
    final apartments = units.where((u) => u.type == 'apartment').toList();
    final available = apartments.where((a) => a.isAvailable).length;
    final sold = apartments.length - available;

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
      constraints: BoxConstraints(maxWidth: 160),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disponibilidade',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: LayoutConstants.fontSizeMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: LayoutConstants.marginSm),
          _buildStatItem('Total', '${apartments.length}', AppTheme.primaryColor),
          _buildStatItem('Disponível', '$available', Colors.green),
          _buildStatItem('Vendido', '$sold', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
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

  void _selectUnit(FloorUnit unit) {
    setState(() {
      _selectedUnit = _selectedUnit?.id == unit.id ? null : unit;
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }
}
