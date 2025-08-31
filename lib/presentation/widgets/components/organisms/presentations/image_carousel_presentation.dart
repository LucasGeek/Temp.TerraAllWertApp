import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/app_theme.dart';
import '../../../../design_system/layout_constants.dart';
import '../../../../responsive/breakpoints.dart';

/// Apresentação em carrossel de imagens para galerias
/// Usado para apartamentos, fotos gerais, etc.
class ImageCarouselPresentation extends ConsumerStatefulWidget {
  final String title;
  final String route;
  final List<String>? images;
  final String? description;

  const ImageCarouselPresentation({
    super.key,
    required this.title,
    required this.route,
    this.images,
    this.description,
  });

  @override
  ConsumerState<ImageCarouselPresentation> createState() => _ImageCarouselPresentationState();
}

class _ImageCarouselPresentationState extends ConsumerState<ImageCarouselPresentation> {
  PageController? _pageController;
  int _currentIndex = 0;

  // Mock images - later this will come from API/storage
  final List<String> _mockImages = [
    'https://via.placeholder.com/800x600/2E7D32/FFFFFF?text=Apartamento+1',
    'https://via.placeholder.com/800x600/FFA726/FFFFFF?text=Apartamento+2',
    'https://via.placeholder.com/800x600/1976D2/FFFFFF?text=Apartamento+3',
    'https://via.placeholder.com/800x600/388E3C/FFFFFF?text=Apartamento+4',
    'https://via.placeholder.com/800x600/F57C00/FFFFFF?text=Apartamento+5',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayImages = widget.images?.isNotEmpty == true ? widget.images! : _mockImages;
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main carousel
          PageView.builder(
            controller: _pageController,
            itemCount: displayImages.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: Image.network(
                    displayImages[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.surfaceColor,
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
                              'Imagem não disponível',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: LayoutConstants.fontSizeMedium,
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
              );
            },
          ),

          // Side navigation arrows for desktop
          if (!isMobile && displayImages.length > 1) ...[
            // Previous button
            if (_currentIndex > 0)
              Positioned(
                left: LayoutConstants.paddingLg,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavButton(
                    icon: Icons.arrow_back_ios,
                    onPressed: _previousImage,
                    size: 48,
                  ),
                ),
              ),

            // Next button
            if (_currentIndex < displayImages.length - 1)
              Positioned(
                right: LayoutConstants.paddingLg,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildNavButton(
                    icon: Icons.arrow_forward_ios,
                    onPressed: _nextImage,
                    size: 48,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    double size = 32,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.white.withValues(alpha: 0.5),
          size: size * 0.5,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController?.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < (_mockImages.length - 1)) {
      _pageController?.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
