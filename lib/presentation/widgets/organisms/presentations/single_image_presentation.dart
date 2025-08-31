import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';

/// Apresentação de imagem única para fichas técnicas e documentos
class SingleImagePresentation extends ConsumerStatefulWidget {
  final String title;
  final String route;
  final String? imageUrl;
  final String? description;

  const SingleImagePresentation({
    super.key,
    required this.title,
    required this.route,
    this.imageUrl,
    this.description,
  });

  @override
  ConsumerState<SingleImagePresentation> createState() => _SingleImagePresentationState();
}

class _SingleImagePresentationState extends ConsumerState<SingleImagePresentation> {
  final TransformationController _transformationController = TransformationController();
  bool _isZoomed = false;

  // Mock image URL for technical sheets
  final String _mockImageUrl = 'https://via.placeholder.com/1200x800/2E7D32/FFFFFF?text=Ficha+Técnica';

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = widget.imageUrl ?? _mockImageUrl;
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Main image viewer
          Center(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                onInteractionStart: (details) {
                  setState(() {
                    _isZoomed = _transformationController.value.getMaxScaleOnAxis() > 1.0;
                  });
                },
                onInteractionEnd: (details) {
                  setState(() {
                    _isZoomed = _transformationController.value.getMaxScaleOnAxis() > 1.0;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(LayoutConstants.paddingLg),
                  child: Image.network(
                    displayImageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(height: LayoutConstants.marginMd),
                            Text(
                              'Documento ainda não disponível',
                              style: TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: LayoutConstants.fontSizeXLarge,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: LayoutConstants.marginMd),
                            Text(
                              'O documento técnico para "${widget.title}" ainda não foi carregado.\n\nEste é um menu recém-criado e o conteúdo será adicionado em breve.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: LayoutConstants.fontSizeMedium,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: LayoutConstants.marginMd),
                            Text(
                              'Verifique novamente mais tarde ou entre em contato com o administrador.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: LayoutConstants.fontSizeSmall,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                                strokeWidth: 4,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                            SizedBox(height: LayoutConstants.marginMd),
                            Text(
                              'Carregando documento...',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: LayoutConstants.fontSizeMedium,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
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
                        if (widget.description != null) ...[
                          SizedBox(height: 4),
                          Text(
                            widget.description!,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Zoom controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildZoomButton(
                        icon: Icons.zoom_out,
                        onPressed: _zoomOut,
                        tooltip: 'Diminuir zoom',
                      ),
                      SizedBox(width: LayoutConstants.marginXs),
                      _buildZoomButton(
                        icon: Icons.zoom_in,
                        onPressed: _zoomIn,
                        tooltip: 'Aumentar zoom',
                      ),
                      SizedBox(width: LayoutConstants.marginXs),
                      _buildZoomButton(
                        icon: Icons.fit_screen,
                        onPressed: _resetZoom,
                        tooltip: 'Ajustar à tela',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom info overlay (if needed)
          if (widget.description != null && !isMobile)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + LayoutConstants.paddingMd,
                  top: LayoutConstants.paddingMd,
                  left: LayoutConstants.paddingMd,
                  right: LayoutConstants.paddingMd,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: LayoutConstants.iconMedium,
                    ),
                    SizedBox(width: LayoutConstants.marginSm),
                    Expanded(
                      child: Text(
                        widget.description!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: LayoutConstants.fontSizeMedium,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Zoom indicator
          if (_isZoomed)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              right: LayoutConstants.paddingMd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Ampliado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoomButton({
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
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  void _zoomIn() {
    final currentTransform = _transformationController.value;
    final currentScale = currentTransform.getMaxScaleOnAxis();
    
    if (currentScale < 4.0) {
      final newScale = (currentScale * 1.5).clamp(1.0, 4.0);
      _transformationController.value = Matrix4.identity()..scale(newScale);
      setState(() {
        _isZoomed = newScale > 1.0;
      });
    }
  }

  void _zoomOut() {
    final currentTransform = _transformationController.value;
    final currentScale = currentTransform.getMaxScaleOnAxis();
    
    if (currentScale > 1.0) {
      final newScale = (currentScale / 1.5).clamp(1.0, 4.0);
      _transformationController.value = Matrix4.identity()..scale(newScale);
      setState(() {
        _isZoomed = newScale > 1.0;
      });
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _isZoomed = false;
    });
  }
}