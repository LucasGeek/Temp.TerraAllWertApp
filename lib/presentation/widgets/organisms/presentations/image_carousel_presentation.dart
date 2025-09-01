import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../domain/entities/carousel_data.dart';
import '../../../../domain/enums/map_type.dart';
import '../../../../infra/logging/app_logger.dart';
import '../../../../infra/storage/carousel_data_storage.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../notification/snackbar_notification.dart';
import '../../molecules/offline_image.dart';

/// Tipos de item no carrossel
enum CarouselItemType { image, map }

/// Item do carrossel (imagem ou mapa)
class CarouselItem {
  final CarouselItemType type;
  final dynamic data;

  CarouselItem(this.type, this.data);
}

/// Apresentação de carrossel de imagens com funcionalidades avançadas
/// Suporta imagens, vídeo, mapa, caixa de texto e zoom
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

class _ImageCarouselPresentationState extends ConsumerState<ImageCarouselPresentation>
    with TickerProviderStateMixin {
  final CarouselDataStorage _carouselStorage = CarouselDataStorage();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  PageController? _pageController;
  TransformationController? _transformationController;
  VideoPlayerController? _videoController;
  MapController? _mapController;

  CarouselData? _carouselData;
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _showControls = true;

  // Mapa para armazenar bytes de imagem por path (para Web)
  final Map<String, Uint8List> _imagesBytesMap = {};

  // Mock removido - foco em estado vazio incentivando adição

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _transformationController = TransformationController();
    _loadCarouselData();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _transformationController?.dispose();
    _videoController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Carrega os dados do carrossel do storage local
  Future<void> _loadCarouselData() async {
    setState(() => _isLoading = true);

    try {
      final carouselData = await _carouselStorage.loadCarouselData(widget.route);

      if (carouselData == null) {
        // Cria dados iniciais vazios se não existir - promove adição manual
        final initialImages = widget.images ?? <String>[];
        _carouselData = CarouselData(
          id: _uuid.v4(),
          routeId: widget.route,
          imageUrls: initialImages,
          createdAt: DateTime.now(),
        );
      } else {
        _carouselData = carouselData;
      }

      // Inicializa controlador de vídeo se houver
      if (_carouselData!.videoUrl != null || _carouselData!.videoPath != null) {
        _initializeVideoController();
      }
    } catch (e) {
      // Em caso de erro, cria dados vazios para incentivar adição manual
      final initialImages = widget.images ?? <String>[];
      _carouselData = CarouselData(
        id: _uuid.v4(),
        routeId: widget.route,
        imageUrls: initialImages,
        createdAt: DateTime.now(),
      );
      SnackbarNotification.showWarning('Aviso: Usando dados padrão - $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Salva os dados no storage local
  Future<void> _saveCarouselData() async {
    if (_carouselData == null) return;

    try {
      final updatedData = _carouselData!.copyWith(updatedAt: DateTime.now());

      await _carouselStorage.saveCarouselData(updatedData);
      _carouselData = updatedData;

      SnackbarNotification.showSuccess('Dados salvos com sucesso!');
    } catch (e) {
      SnackbarNotification.showError('Erro ao salvar dados: $e');
    }
  }

  /// Inicializa controlador de vídeo
  Future<void> _initializeVideoController() async {
    try {
      final videoSource = _carouselData!.videoUrl ?? _carouselData!.videoPath!;

      if (videoSource.startsWith('http') || videoSource.startsWith('blob:')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoSource));
      } else {
        // Para Web, paths locais também devem usar networkUrl
        try {
          _videoController = VideoPlayerController.file(File(videoSource));
        } catch (e) {
          // Fallback para Web - tenta como URL
          _videoController = VideoPlayerController.networkUrl(Uri.parse(videoSource));
        }
      }

      await _videoController!.initialize();
      setState(() {});
    } catch (e) {
      SnackbarNotification.showError('Erro ao inicializar vídeo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_carouselData == null) {
      return _buildErrorState();
    }

    // Estado vazio - incentiva adição de conteúdo
    if (_allImages.isEmpty &&
        _carouselData!.mapConfig == null &&
        _carouselData!.videoUrl == null &&
        _carouselData!.videoPath == null) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Área principal do carrossel
            Positioned.fill(child: _buildMainContent()),

            // NOVO: Setas de navegação (apenas se múltiplos itens)
            if (_showControls && _allItems.length > 1) _buildNavigationArrows(),

            // Controles superiores esquerdos
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + LayoutConstants.paddingMd,
                left: LayoutConstants.paddingMd,
                child: _buildTopLeftControls(),
              ),

            // Controles inferiores direitos (zoom)
            if (_showControls)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + LayoutConstants.paddingMd,
                right: LayoutConstants.paddingMd,
                child: _buildBottomRightControls(),
              ),

            // Indicadores do carrossel (se múltiplos itens)
            if (_showControls && _allItems.length > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + LayoutConstants.paddingXl,
                left: 0,
                right: 0,
                child: _buildPageIndicators(),
              ),

            // Overlay da caixa de texto
            if (_carouselData!.textBox != null) _buildTextBoxOverlay(_carouselData!.textBox!),
          ],
        ),
      ),
    );
  }

  /// Combina URLs online e paths locais das imagens
  List<String> get _allImages {
    final images = [..._carouselData!.imageUrls, ..._carouselData!.imagePaths];
    AppLogger.debug(
      '_allImages: total=${images.length}, urls=${_carouselData!.imageUrls.length}, paths=${_carouselData!.imagePaths.length}',
      tag: 'ImageCarousel',
    );
    return images;
  }

  /// Combina imagens e mapa (se existir) como itens do carrossel
  List<CarouselItem> get _allItems {
    final items = <CarouselItem>[];

    // Adicionar imagens
    for (final imageUrl in _allImages) {
      items.add(CarouselItem(CarouselItemType.image, imageUrl));
    }

    // Adicionar mapa se configurado
    if (_carouselData?.mapConfig != null) {
      items.add(CarouselItem(CarouselItemType.map, _carouselData!.mapConfig!));
    }

    AppLogger.debug(
      '_allItems: total=${items.length}, images=${_allImages.length}, hasMap=${_carouselData?.mapConfig != null}',
      tag: 'ImageCarousel',
    );

    return items;
  }

  /// Constrói o conteúdo principal do carrossel
  Widget _buildMainContent() {
    final items = _allItems;

    AppLogger.debug('_buildMainContent: items.length=${items.length}', tag: 'ImageCarousel');

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    if (items.length == 1) {
      return _buildSingleItem(items.first);
    }

    return GestureDetector(
      // NOVO: Gestos adicionais para navegação
      onPanEnd: (details) {
        // Swipe horizontal para navegar
        if (details.velocity.pixelsPerSecond.dx > 500) {
          _previousItem(); // Swipe para direita = item anterior
        } else if (details.velocity.pixelsPerSecond.dx < -500) {
          _nextItem(); // Swipe para esquerda = próximo item
        }
      },
      child: PageView.builder(
        controller: _pageController,
        itemCount: items.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _resetZoom();
          // REMOVIDO: _startControlsTimer() - controles permanecem visíveis
        },
        itemBuilder: (context, index) {
          return _buildSingleItem(items[index]);
        },
      ),
    );
  }

  /// Constrói um único item do carrossel (imagem ou mapa)
  Widget _buildSingleItem(CarouselItem item) {
    switch (item.type) {
      case CarouselItemType.image:
        return _buildSingleImage(item.data as String);
      case CarouselItemType.map:
        return _buildMapWidget(item.data as MapConfig);
    }
  }

  /// Constrói uma única imagem com zoom
  Widget _buildSingleImage(String imageUrl) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 5.0,
      onInteractionEnd: (details) {
        setState(() {});
      },
      child: _buildImageWidget(imageUrl),
    );
  }

  /// Constrói widget do OpenStreetMap
  Widget _buildMapWidget(MapConfig mapConfig) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: FlutterMap(
        mapController: _mapController ??= MapController(),
        options: MapOptions(
          initialCenter: LatLng(mapConfig.latitude, mapConfig.longitude),
          initialZoom: 15.0,
          minZoom: 5.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: _getTileUrlTemplate(mapConfig.mapType),
            userAgentPackageName: 'com.terra.allwert.app',
            maxZoom: 18,
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 40.0,
                height: 40.0,
                point: LatLng(mapConfig.latitude, mapConfig.longitude),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Retorna template de URL para diferentes tipos de mapa
  String _getTileUrlTemplate(MapType mapType) {
    switch (mapType) {
      case MapType.openStreet:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapType.terrain:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
    }
  }

  /// Widget de imagem com tratamento de erro e loading robusto
  Widget _buildImageWidget(String imageUrl) {
    AppLogger.debug('Renderizando imagem: $imageUrl', tag: 'ImageCarousel');

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        // Para Web com bytes em memória
        if (kIsWeb && _imagesBytesMap.containsKey(imageUrl)) {
          AppLogger.debug('Usando Image.memory para: $imageUrl', tag: 'ImageCarousel');
          return SizedBox(
            width: width,
            height: height,
            child: Image.memory(
              _imagesBytesMap[imageUrl]!,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                AppLogger.error('Erro ao carregar imagem da memória: $error', tag: 'ImageCarousel');
                return _buildRobustErrorWidget();
              },
            ),
          );
        }

        // Para URLs de rede
        if (imageUrl.startsWith('http') || imageUrl.startsWith('blob:')) {
          AppLogger.debug('Usando Image.network para: $imageUrl', tag: 'ImageCarousel');
          return SizedBox(
            width: width,
            height: height,
            child: Image.network(
              imageUrl,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                AppLogger.error('Erro ao carregar imagem de rede: $error', tag: 'ImageCarousel');
                return _buildRobustErrorWidget();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildRobustPlaceholder();
              },
            ),
          );
        }

        // Para arquivos locais (não-Web)
        if (!kIsWeb) {
          AppLogger.debug('Usando Image.file para: $imageUrl', tag: 'ImageCarousel');
          return SizedBox(
            width: width,
            height: height,
            child: Image.file(
              File(imageUrl),
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                AppLogger.error('Erro ao carregar imagem local: $error', tag: 'ImageCarousel');
                return _buildRobustErrorWidget();
              },
            ),
          );
        }

        // Fallback - tenta OfflineImage
        AppLogger.debug('Usando OfflineImage como fallback para: $imageUrl', tag: 'ImageCarousel');
        return SizedBox(
          width: width,
          height: height,
          child: OfflineImage(
            networkUrl: imageUrl.startsWith('http') ? imageUrl : null,
            localPath: !imageUrl.startsWith('http') ? imageUrl : null,
            fit: BoxFit.fill,
            placeholder: _buildRobustPlaceholder(),
            errorWidget: _buildRobustErrorWidget(),
            enableCaching: true,
          ),
        );
      },
    );
  }

  /// Placeholder robusto para carregamento
  Widget _buildRobustPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width,
          height: constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height,
          color: AppTheme.surfaceColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3),
              SizedBox(height: LayoutConstants.marginMd),
              Text(
                'Carregando imagem...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: LayoutConstants.fontSizeMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: LayoutConstants.marginSm),
              Text(
                'Verifique sua conexão com a internet',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: LayoutConstants.fontSizeSmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget de erro robusto para imagens
  Widget _buildRobustErrorWidget() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width,
          height: constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height,
          color: AppTheme.surfaceColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, size: 80, color: AppTheme.textSecondary),
              SizedBox(height: LayoutConstants.marginMd),
              Text(
                'Imagem não disponível',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: LayoutConstants.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: LayoutConstants.marginSm),
              Text(
                'A imagem pode ter sido removida ou\no caminho está incorreto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: LayoutConstants.fontSizeMedium,
                ),
              ),
              SizedBox(height: LayoutConstants.marginMd),
              ElevatedButton.icon(
                onPressed: () {
                  // Força reload do widget
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Estado vazio (sem imagens) - informativo para novos menus
  Widget _buildEmptyState() {
    return Container(
      color: AppTheme.surfaceColor,
      padding: EdgeInsets.all(LayoutConstants.paddingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone principal
          Container(
            padding: EdgeInsets.all(LayoutConstants.paddingXl),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.photo_library_outlined, size: 80, color: AppTheme.primaryColor),
          ),

          SizedBox(height: LayoutConstants.marginXl),

          // Título
          Text(
            'Menu "${widget.title}" criado com sucesso!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: LayoutConstants.fontSizeXLarge,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: LayoutConstants.marginMd),

          // Subtítulo explicativo incentivando ação
          Text(
            '👆 Clique aqui e adicione suas primeiras imagens!\n\n'
            'Você pode adicionar:\n'
            '📷 Imagens da galeria\n'
            '🗺️ Mapas interativos\n'
            '🎨 E muito mais!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: LayoutConstants.fontSizeMedium,
              height: 1.5,
            ),
          ),

          SizedBox(height: LayoutConstants.marginXl),

          // Botões de ação
          Wrap(
            alignment: WrapAlignment.center,
            spacing: LayoutConstants.marginMd,
            runSpacing: LayoutConstants.marginMd,
            children: [
              ElevatedButton.icon(
                onPressed: _addImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Adicionar Imagens'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: LayoutConstants.paddingLg,
                    vertical: LayoutConstants.paddingMd,
                  ),
                ),
              ),

              OutlinedButton.icon(
                onPressed: _addOrEditMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Adicionar Mapa'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: LayoutConstants.paddingLg,
                    vertical: LayoutConstants.paddingMd,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: LayoutConstants.marginXl),

          // Dica informativa
          Container(
            padding: EdgeInsets.all(LayoutConstants.paddingMd),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.primaryColor,
                  size: LayoutConstants.iconMedium,
                ),
                SizedBox(width: LayoutConstants.marginMd),
                Expanded(
                  child: Text(
                    'Dica: Toque na tela para esconder/mostrar os controles quando houver conteúdo',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: LayoutConstants.fontSizeSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Estado de erro
  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.white),
            SizedBox(height: LayoutConstants.marginMd),
            Text(
              'Erro ao carregar dados',
              style: TextStyle(
                color: Colors.white,
                fontSize: LayoutConstants.fontSizeLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: LayoutConstants.marginMd),
            ElevatedButton(onPressed: _loadCarouselData, child: const Text('Tentar Novamente')),
          ],
        ),
      ),
    );
  }

  /// Controles superiores esquerdos
  Widget _buildTopLeftControls() {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingSm),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vídeo como recurso complementar (apenas quando há conteúdo principal)
          if (_allImages.isNotEmpty || _carouselData!.mapConfig != null)
            _buildControlButton(
              icon: Icons.videocam_outlined,
              onPressed: _addOrViewVideo,
              tooltip: _carouselData!.videoUrl != null || _carouselData!.videoPath != null
                  ? 'Gerenciar Vídeo'
                  : 'Adicionar Vídeo',
              hasContent: _carouselData!.videoUrl != null || _carouselData!.videoPath != null,
            ),

          if (_allImages.isNotEmpty || _carouselData!.mapConfig != null)
            SizedBox(height: LayoutConstants.marginSm),

          _buildControlButton(
            icon: Icons.add_photo_alternate,
            onPressed: _addImages,
            tooltip: 'Adicionar Imagem',
          ),

          SizedBox(height: LayoutConstants.marginSm),

          _buildControlButton(
            icon: Icons.reorder,
            onPressed: _reorderImages,
            tooltip: 'Reordenar Imagens',
          ),

          SizedBox(height: LayoutConstants.marginSm),

          _buildControlButton(
            icon: Icons.text_fields,
            onPressed: _addOrEditTextBox,
            tooltip: _carouselData!.textBox != null ? 'Editar Texto' : 'Adicionar Texto',
            hasContent: _carouselData!.textBox != null,
          ),

          SizedBox(height: LayoutConstants.marginSm),

          _buildControlButton(
            icon: Icons.map_outlined,
            onPressed: _addOrEditMap,
            tooltip: _carouselData!.mapConfig != null ? 'Editar Mapa' : 'Adicionar Mapa',
            hasContent: _carouselData!.mapConfig != null,
          ),

          SizedBox(height: LayoutConstants.marginSm),

          _buildControlButton(
            icon: Icons.delete_outline,
            onPressed: _deleteCurrentImage,
            tooltip: 'Apagar Imagem',
          ),
        ],
      ),
    );
  }

  /// Controles inferiores direitos (zoom)
  Widget _buildBottomRightControls() {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingSm),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(icon: Icons.zoom_in, onPressed: _zoomIn, tooltip: 'Aumentar Zoom'),

          SizedBox(height: LayoutConstants.marginSm),

          _buildControlButton(icon: Icons.zoom_out, onPressed: _zoomOut, tooltip: 'Diminuir Zoom'),

          SizedBox(height: LayoutConstants.marginSm),

          _buildControlButton(
            icon: Icons.fit_screen,
            onPressed: _resetZoom,
            tooltip: 'Resetar Zoom',
          ),
        ],
      ),
    );
  }

  /// Indicadores de páginas aprimorados com contador
  Widget _buildPageIndicators() {
    final items = _allItems;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicadores de pontos com ícones diferenciados
        ...List.generate(items.length, (index) {
          final isActive = index == _currentIndex;
          final item = items[index];

          return Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
              border: Border.all(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              item.type == CarouselItemType.image ? Icons.image : Icons.map,
              size: 12,
              color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.8),
            ),
          );
        }),

        // Contador de itens
        if (items.length > 1) ...[
          SizedBox(width: LayoutConstants.marginMd),
          Container(
            padding: EdgeInsets.symmetric(horizontal: LayoutConstants.paddingSm, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              '${_currentIndex + 1}/${items.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Overlay da caixa de texto
  Widget _buildTextBoxOverlay(TextBox textBox) {
    return Positioned(
      left: textBox.positionX * MediaQuery.of(context).size.width - 100,
      top: textBox.positionY * MediaQuery.of(context).size.height - 25,
      child: Container(
        padding: EdgeInsets.all(LayoutConstants.paddingSm),
        decoration: BoxDecoration(
          color: Color(textBox.backgroundColor),
          borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          textBox.text,
          style: TextStyle(
            color: Color(textBox.fontColor),
            fontSize: textBox.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Botão de controle padrão
  /// Botão de controle customizado com feedback visual aprimorado
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool hasContent = false, // Novo parâmetro para indicar conteúdo
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasContent
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasContent ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.3),
            width: hasContent ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            IconButton(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
            ),
            // Indicador de conteúdo ativo
            if (hasContent)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // === MÉTODOS DE AÇÃO ===

  /// Alterna visibilidade dos controles
  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    // REMOVIDO: Timer automático - controles só mudam com interação do usuário
  }

  // REMOVIDO: Método _startControlsTimer() - controles agora são sempre visíveis
  // exceto quando o usuário escolhe escondê-los manualmente

  /// NOVO: Constrói as setas de navegação laterais
  Widget _buildNavigationArrows() {
    return Stack(
      children: [
        // Seta Esquerda
        if (_currentIndex > 0)
          Positioned(
            left: LayoutConstants.paddingMd,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildNavigationArrow(
                icon: Icons.arrow_back_ios,
                onPressed: _previousItem,
                tooltip: 'Item Anterior',
              ),
            ),
          ),

        // Seta Direita
        if (_currentIndex < _allItems.length - 1)
          Positioned(
            right: LayoutConstants.paddingMd,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildNavigationArrow(
                icon: Icons.arrow_forward_ios,
                onPressed: _nextItem,
                tooltip: 'Próximo Item',
              ),
            ),
          ),
      ],
    );
  }

  /// NOVO: Constrói botão de seta de navegação
  Widget _buildNavigationArrow({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedScale(
        scale: _showControls ? 1.0 : 0.8,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  onPressed();
                  // Feedback háptico
                  HapticFeedback.lightImpact();
                },
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// NOVO: Navega para item anterior
  void _previousItem() {
    if (_currentIndex > 0 && _pageController != null) {
      _pageController!.animateToPage(
        _currentIndex - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// NOVO: Navega para próximo item
  void _nextItem() {
    if (_currentIndex < _allItems.length - 1 && _pageController != null) {
      _pageController!.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Adiciona ou visualiza vídeo
  void _addOrViewVideo() async {
    final hasVideo = _carouselData?.videoUrl != null || _carouselData?.videoPath != null;
    
    if (hasVideo) {
      // Se já tem vídeo, mostrar opções: visualizar ou configurar
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Vídeo Configurado'),
          content: Text('O que você gostaria de fazer?'),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _playVideo();
              },
              icon: Icon(Icons.play_circle_outline),
              label: Text('Visualizar'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showVideoConfigDialog();
              },
              icon: Icon(Icons.settings),
              label: Text('Configurar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        ),
      );
    } else {
      // Se não tem vídeo, ir direto para configuração
      _showVideoConfigDialog();
    }
  }

  /// Modal para configuração de vídeo com título e opção de remover (mesma lógica do PinMapPresentation)
  void _showVideoConfigDialog() {
    final hasExistingVideo = _carouselData?.videoUrl != null || _carouselData?.videoPath != null;
    final titleController = TextEditingController(text: _carouselData?.videoTitle ?? '');
    final urlController = TextEditingController(text: _carouselData?.videoUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasExistingVideo ? 'Configurar Vídeo' : 'Adicionar Vídeo'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo de título
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Título do vídeo',
                  hintText: 'Ex: Tour virtual do apartamento',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Campo de URL
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'URL do vídeo',
                  hintText: 'Cole a URL do vídeo aqui',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              if (hasExistingVideo) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(child: Text('Já existe um vídeo configurado')),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (hasExistingVideo) ...[
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _playVideo();
              },
              icon: Icon(Icons.play_circle_outline),
              label: Text('Visualizar Vídeo'),
            ),
            TextButton.icon(
              onPressed: () => _removeVideo(context),
              icon: Icon(Icons.delete, color: Colors.red),
              label: Text('Remover Vídeo', style: TextStyle(color: Colors.red)),
            ),
          ],
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancelar')),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickVideoFromGallery(context, titleController.text),
                icon: Icon(Icons.upload_file),
                label: Text('Galeria'),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    _saveVideoFromUrl(context, titleController.text, urlController.text),
                icon: Icon(Icons.link),
                label: Text('Salvar URL'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Remove o vídeo configurado
  void _removeVideo(BuildContext dialogContext) async {
    if (_carouselData != null) {
      _carouselData = _carouselData!.copyWith(
        videoPath: null,
        videoUrl: null,
        videoTitle: null,
        updatedAt: DateTime.now(),
      );

      await _saveCarouselData();
      if (mounted && context.mounted) {
        setState(() {});
        Navigator.of(dialogContext).pop();
        SnackbarNotification.showSuccess('Vídeo removido com sucesso!');
      }
    }
  }

  /// Seleciona vídeo da galeria
  void _pickVideoFromGallery(BuildContext dialogContext, String title) async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null && _carouselData != null && mounted) {
        _carouselData = _carouselData!.copyWith(
          videoPath: video.path,
          videoUrl: null,
          videoTitle: title.trim().isEmpty ? 'Vídeo do carrossel' : title.trim(),
          updatedAt: DateTime.now(),
        );

        await _saveCarouselData();
        if (mounted && context.mounted) {
          setState(() {});
          Navigator.of(dialogContext).pop();
          SnackbarNotification.showSuccess('Vídeo adicionado com sucesso!');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarNotification.showError('Erro ao adicionar vídeo: $e');
      }
    }
  }

  /// Salva vídeo através de URL
  void _saveVideoFromUrl(BuildContext dialogContext, String title, String url) async {
    if (url.trim().isEmpty) {
      if (mounted) {
        SnackbarNotification.showError('Por favor, insira uma URL válida');
      }
      return;
    }

    if (_carouselData != null && mounted) {
      try {
        AppLogger.info('Salvando vídeo da URL: $url com título: $title');

        _carouselData = _carouselData!.copyWith(
          videoUrl: url.trim(),
          videoPath: null,
          videoTitle: title.trim().isEmpty ? 'Vídeo do carrossel' : title.trim(),
          updatedAt: DateTime.now(),
        );

        await _saveCarouselData();

        AppLogger.info('Vídeo salvo com sucesso, forçando atualização da tela');

        // Delay e setState explícito para garantir atualização da tela
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && context.mounted) {
          setState(() {
            AppLogger.info('Estado atualizado após salvar vídeo');
          });
          Navigator.of(dialogContext).pop();
          SnackbarNotification.showSuccess('Vídeo configurado com sucesso!');
        }
      } catch (e) {
        AppLogger.error('Erro ao salvar vídeo: $e');
        if (mounted) {
          SnackbarNotification.showError('Erro ao salvar vídeo: $e');
        }
      }
    }
  }

  /// Adiciona imagens ao carrossel (usando lógica do PinMapPresentation)
  Future<void> _addImages() async {
    try {
      AppLogger.debug('Iniciando seleção de imagens', tag: 'ImageCarousel');
      final images = await _imagePicker.pickMultiImage();
      AppLogger.debug('${images.length} imagens selecionadas', tag: 'ImageCarousel');
      if (images.isNotEmpty && _carouselData != null) {
        final imagePaths = <String>[];

        // Verificar cada imagem individualmente
        for (final image in images) {
          AppLogger.debug('Processando imagem: ${image.path}', tag: 'ImageCarousel');

          if (kIsWeb) {
            // Para Web, tentar obter bytes da imagem
            try {
              final bytes = await image.readAsBytes();
              _imagesBytesMap[image.path] = bytes;
              imagePaths.add(image.path);
              AppLogger.debug(
                'Imagem Web processada e armazenada em memória: ${image.path}',
                tag: 'ImageCarousel',
              );
            } catch (e) {
              AppLogger.error('Erro ao processar imagem Web: $e', tag: 'ImageCarousel');
            }
          } else {
            // Para plataformas nativas
            final file = File(image.path);
            final exists = await file.exists();
            AppLogger.debug('Arquivo existe: $exists para ${image.path}', tag: 'ImageCarousel');

            if (exists) {
              imagePaths.add(image.path);
            } else {
              AppLogger.warning('Arquivo não existe: ${image.path}', tag: 'ImageCarousel');
            }
          }
        }

        if (imagePaths.isNotEmpty) {
          // Atualizar dados do carrossel
          _carouselData = _carouselData!.copyWith(
            imagePaths: [..._carouselData!.imagePaths, ...imagePaths],
            updatedAt: DateTime.now(),
          );

          AppLogger.debug(
            '_carouselData atualizado. Total de imagePaths: ${_carouselData!.imagePaths.length}',
            tag: 'ImageCarousel',
          );
          AppLogger.debug(
            '_allImages após atualização: ${_allImages.length}',
            tag: 'ImageCarousel',
          );

          // Salvar os dados atualizados
          await _saveCarouselData();

          if (mounted) {
            setState(() {});
            SnackbarNotification.showSuccess('${imagePaths.length} imagem(ns) adicionada(s)!');
          }
        } else {
          AppLogger.warning('Nenhuma imagem válida foi processada', tag: 'ImageCarousel');
          SnackbarNotification.showError('Nenhuma imagem válida foi selecionada');
        }
      } else {
        AppLogger.warning('Imagens vazias ou _carouselData nulo', tag: 'ImageCarousel');
        if (images.isEmpty) AppLogger.debug('images está vazio', tag: 'ImageCarousel');
        if (_carouselData == null) AppLogger.debug('_carouselData é null', tag: 'ImageCarousel');
      }
    } catch (e) {
      AppLogger.error('Erro ao selecionar imagens: $e', tag: 'ImageCarousel');
      SnackbarNotification.showError('Erro ao selecionar imagens: $e');
    }
  }

  /// Reordena imagens
  void _reorderImages() {
    if (_allImages.length <= 1) {
      SnackbarNotification.showError('Precisa de pelo menos 2 imagens para reordenar');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ReorderImagesScreen(
          images: _allImages,
          onReorder: (reorderedImages) async {
            // Separar URLs e paths após reordenação
            final urls = <String>[];
            final paths = <String>[];

            for (final image in reorderedImages) {
              if (image.startsWith('http')) {
                urls.add(image);
              } else {
                paths.add(image);
              }
            }

            setState(() {
              _carouselData = _carouselData!.copyWith(
                imageUrls: urls,
                imagePaths: paths,
                updatedAt: DateTime.now(),
              );
            });
            await _saveCarouselData();
          },
        ),
      ),
    );
  }

  /// Adiciona ou edita caixa de texto
  void _addOrEditTextBox() {
    _showTextBoxDialog(_carouselData!.textBox);
  }

  /// Dialog para configurar caixa de texto
  void _showTextBoxDialog(TextBox? existingTextBox) {
    final textController = TextEditingController(text: existingTextBox?.text ?? '');
    double fontSize = existingTextBox?.fontSize ?? 16.0;
    Color fontColor = existingTextBox != null ? Color(existingTextBox.fontColor) : Colors.black;
    Color backgroundColor = existingTextBox != null
        ? Color(existingTextBox.backgroundColor)
        : Colors.white;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                existingTextBox != null ? 'Editar Caixa de Texto' : 'Adicionar Caixa de Texto',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        labelText: 'Texto*',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    Text('Tamanho da Fonte: ${fontSize.toInt()}'),
                    Slider(
                      value: fontSize,
                      min: 12.0,
                      max: 32.0,
                      divisions: 20,
                      onChanged: (value) => setState(() => fontSize = value),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Cor da Fonte'),
                              SizedBox(height: LayoutConstants.marginSm),
                              _buildColorPicker(
                                fontColor,
                                (color) => setState(() => fontColor = color),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: LayoutConstants.marginMd),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Cor de Fundo'),
                              SizedBox(height: LayoutConstants.marginSm),
                              _buildColorPicker(
                                backgroundColor,
                                (color) => setState(() => backgroundColor = color),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                if (existingTextBox != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _removeTextBox();
                    },
                    child: const Text('Remover'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: textController.text.isNotEmpty
                      ? () {
                          final textBox = TextBox(
                            id: existingTextBox?.id ?? _uuid.v4(),
                            text: textController.text,
                            fontSize: fontSize,
                            fontColor: fontColor.toARGB32(),
                            backgroundColor: backgroundColor.toARGB32(),
                            positionX: existingTextBox?.positionX ?? 0.5,
                            positionY: existingTextBox?.positionY ?? 0.1,
                            createdAt: existingTextBox?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          Navigator.of(context).pop();
                          _saveTextBox(textBox);
                        }
                      : null,
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Color picker simples
  Widget _buildColorPicker(Color currentColor, Function(Color) onColorChanged) {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
    ];

    return Wrap(
      children: colors.map((color) {
        final isSelected = color.toARGB32() == currentColor.toARGB32();
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Salva caixa de texto
  Future<void> _saveTextBox(TextBox textBox) async {
    setState(() {
      _carouselData = _carouselData!.copyWith(textBox: textBox);
    });
    await _saveCarouselData();
  }

  /// Remove caixa de texto
  Future<void> _removeTextBox() async {
    setState(() {
      _carouselData = _carouselData!.copyWith(textBox: null);
    });
    await _saveCarouselData();
  }

  /// Adiciona ou edita mapa
  void _addOrEditMap() {
    _showMapDialog(_carouselData!.mapConfig);
  }

  /// Dialog para configurar mapa
  void _showMapDialog(MapConfig? existingMap) {
    final latController = TextEditingController(
      text: existingMap?.latitude.toString() ?? '-23.550520',
    );
    final lngController = TextEditingController(
      text: existingMap?.longitude.toString() ?? '-46.633308',
    );
    MapType mapType = existingMap?.mapType ?? MapType.openStreet;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingMap != null ? 'Editar Mapa' : 'Adicionar Mapa'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    TextField(
                      controller: lngController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    DropdownButtonFormField<MapType>(
                      value: mapType,
                      onChanged: (value) => setState(() => mapType = value!),
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Mapa',
                        border: OutlineInputBorder(),
                      ),
                      items: MapType.values.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type.displayName));
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (existingMap != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _removeMap();
                    },
                    child: const Text('Remover'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final lat = double.tryParse(latController.text);
                    final lng = double.tryParse(lngController.text);

                    if (lat == null || lng == null) {
                      SnackbarNotification.showError('Coordenadas inválidas');
                      return;
                    }

                    final mapConfig = MapConfig(
                      id: existingMap?.id ?? _uuid.v4(),
                      latitude: lat,
                      longitude: lng,
                      mapType: mapType,
                      createdAt: existingMap?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    Navigator.of(context).pop();
                    _saveMap(mapConfig);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Salva configuração do mapa
  Future<void> _saveMap(MapConfig mapConfig) async {
    try {
      AppLogger.info(
        'Salvando configuração do mapa: ${mapConfig.mapType.displayName} em ${mapConfig.latitude}, ${mapConfig.longitude}',
      );

      setState(() {
        _carouselData = _carouselData!.copyWith(mapConfig: mapConfig);
      });
      await _saveCarouselData();

      AppLogger.info('Mapa salvo com sucesso, forçando atualização da tela');

      // Delay e setState explícito para garantir atualização da tela
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          AppLogger.info('Estado atualizado após salvar mapa');
        });
      }

      if (mounted) {
        SnackbarNotification.showSuccess('Mapa adicionado com sucesso');
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar mapa: $e');
      if (mounted) {
        SnackbarNotification.showError('Erro ao salvar mapa: $e');
      }
    }
  }

  /// Remove mapa
  Future<void> _removeMap() async {
    setState(() {
      _carouselData = _carouselData!.copyWith(mapConfig: null);
    });
    await _saveCarouselData();
  }

  /// Apaga imagem atual
  void _deleteCurrentImage() {
    final allItems = _allItems;
    if (allItems.isEmpty) {
      SnackbarNotification.showError('Nenhum item para remover');
      return;
    }
    
    if (_currentIndex >= allItems.length) {
      SnackbarNotification.showError('Índice inválido');
      return;
    }
    
    final currentItem = allItems[_currentIndex];
    final itemType = currentItem.type == CarouselItemType.image ? 'Imagem' : 'Mapa';
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Apagar $itemType'),
          content: Text('Tem certeza que deseja apagar este $itemType?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Cancelar')
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeCurrentItem();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Apagar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Remove item atual (imagem ou mapa)
  Future<void> _removeCurrentItem() async {
    if (_carouselData == null) return;
    
    final allItems = _allItems;
    if (allItems.isEmpty || _currentIndex >= allItems.length) {
      SnackbarNotification.showError('Nenhum item para remover');
      return;
    }

    final currentItem = allItems[_currentIndex];
    final oldIndex = _currentIndex;

    try {
      bool itemRemoved = false;
      
      if (currentItem.type == CarouselItemType.image) {
        // Remover imagem
        final imageToRemove = currentItem.data as String;
        final newImageUrls = List<String>.from(_carouselData!.imageUrls);
        final newImagePaths = List<String>.from(_carouselData!.imagePaths);

        // Busca inteligente em ambas as listas
        if (newImageUrls.contains(imageToRemove)) {
          newImageUrls.remove(imageToRemove);
          itemRemoved = true;
        } else if (newImagePaths.contains(imageToRemove)) {
          newImagePaths.remove(imageToRemove);
          itemRemoved = true;
        }

        if (itemRemoved) {
          setState(() {
            _carouselData = _carouselData!.copyWith(
              imageUrls: newImageUrls,
              imagePaths: newImagePaths,
            );
          });
          AppLogger.debug('Imagem removida do carrossel', tag: 'ImageCarousel');
        }
      } else if (currentItem.type == CarouselItemType.map) {
        // Remover mapa
        setState(() {
          _carouselData = _carouselData!.copyWith(mapConfig: null);
        });
        itemRemoved = true;
        AppLogger.debug('Mapa removido do carrossel', tag: 'ImageCarousel');
      }

      if (!itemRemoved) {
        SnackbarNotification.showError('Não foi possível remover o item');
        return;
      }

      // Implementar navegação segura após exclusão
      final newItems = _allItems;
      
      if (newItems.isEmpty) {
        // Todos os itens foram removidos - voltar para estado vazio
        _currentIndex = 0;
        AppLogger.debug('Todos os itens removidos - resetando para estado vazio', tag: 'ImageCarousel');
      } else {
        // Ainda há itens - ajustar índice
        if (oldIndex >= newItems.length) {
          // Índice estava no final, mover para o último item disponível
          _currentIndex = newItems.length - 1;
        } else {
          // Manter no mesmo índice (o próximo item ocupará a posição atual)
          _currentIndex = oldIndex;
        }
        
        // Atualizar PageController para refletir mudanças
        if (_pageController != null && _pageController!.hasClients) {
          await _pageController!.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        
        AppLogger.debug(
          'Item removido - novo índice: $_currentIndex, total de itens: ${newItems.length}',
          tag: 'ImageCarousel',
        );
      }

      await _saveCarouselData();
      setState(() {}); // Forçar rebuild para atualizar indicadores
    } catch (e) {
      AppLogger.error('Erro ao remover item do carrossel: $e', tag: 'ImageCarousel');
      SnackbarNotification.showError('Erro ao remover item: $e');
    }
  }

  /// Reproduz o vídeo configurado
  Future<void> _playVideo() async {
    if (_carouselData?.videoUrl == null && _carouselData?.videoPath == null) {
      SnackbarNotification.showError('Nenhum vídeo configurado');
      return;
    }

    try {
      // Inicializar controlador se não estiver inicializado
      if (_videoController == null) {
        await _initializeVideoController();
      }

      if (_videoController != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _VideoPlayerScreen(
              videoController: _videoController!,
              title: _carouselData!.videoTitle ?? 'Vídeo do Carrossel',
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao reproduzir vídeo: $e', tag: 'ImageCarousel');
      SnackbarNotification.showError('Erro ao reproduzir vídeo: $e');
    }
  }

  // === CONTROLES DE ZOOM ===

  /// Aumenta o zoom
  void _zoomIn() {
    final currentItem = _getCurrentItem();

    if (currentItem?.type == CarouselItemType.map && _mapController != null) {
      // Zoom do mapa via Flutter Map Controller
      final currentZoom = _mapController!.camera.zoom;
      _mapController!.move(_mapController!.camera.center, currentZoom + 1);
    } else {
      // Zoom de imagem via InteractiveViewer
      final matrix = _transformationController!.value.clone();
      matrix.scale(1.2);
      _transformationController!.value = matrix;
    }
    setState(() {});
  }

  /// Diminui o zoom
  void _zoomOut() {
    final currentItem = _getCurrentItem();

    if (currentItem?.type == CarouselItemType.map && _mapController != null) {
      // Zoom do mapa via Flutter Map Controller
      final currentZoom = _mapController!.camera.zoom;
      _mapController!.move(_mapController!.camera.center, currentZoom - 1);
    } else {
      // Zoom de imagem via InteractiveViewer
      final matrix = _transformationController!.value.clone();
      matrix.scale(0.8);
      _transformationController!.value = matrix;
    }
    setState(() {});
  }

  /// Reseta o zoom
  void _resetZoom() {
    final currentItem = _getCurrentItem();

    if (currentItem?.type == CarouselItemType.map && _mapController != null) {
      // Reset do mapa para posição inicial
      final mapConfig = currentItem!.data as MapConfig;
      _mapController!.move(
        LatLng(mapConfig.latitude, mapConfig.longitude),
        15.0,
      );
    } else {
      // Reset do zoom de imagem
      _transformationController!.value = Matrix4.identity();
    }
    setState(() {});
  }

  /// Obtém o item atual do carrossel
  CarouselItem? _getCurrentItem() {
    final items = _allItems;
    if (_currentIndex < 0 || _currentIndex >= items.length) {
      return null;
    }
    return items[_currentIndex];
  }

  // === UTILITÁRIOS ===

}

/// Tela para reprodução de vídeo
class _VideoPlayerScreen extends StatefulWidget {
  final VideoPlayerController videoController;
  final String title;

  const _VideoPlayerScreen({required this.videoController, required this.title});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    widget.videoController.play();
    // REMOVIDO: _startControlsTimer() - controles ficam visíveis
  }

  // REMOVIDO: Timer automático dos controles do vídeo

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    // REMOVIDO: Timer automático - toggle apenas manual
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.videoController.value.aspectRatio,
                child: VideoPlayer(widget.videoController),
              ),
            ),

            if (_showControls) ...[
              // AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  title: Text(widget.title),
                ),
              ),

              // Controles de reprodução
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + LayoutConstants.paddingMd,
                left: LayoutConstants.paddingMd,
                right: LayoutConstants.paddingMd,
                child: Container(
                  padding: EdgeInsets.all(LayoutConstants.paddingMd),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            widget.videoController.value.isPlaying
                                ? widget.videoController.pause()
                                : widget.videoController.play();
                          });
                        },
                        icon: Icon(
                          widget.videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),

                      Expanded(
                        child: VideoProgressIndicator(
                          widget.videoController,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: AppTheme.primaryColor,
                            bufferedColor: Colors.white.withValues(alpha: 0.3),
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tela para reordenar imagens
class _ReorderImagesScreen extends StatefulWidget {
  final List<String> images;
  final Function(List<String>) onReorder;

  const _ReorderImagesScreen({required this.images, required this.onReorder});

  @override
  State<_ReorderImagesScreen> createState() => _ReorderImagesScreenState();
}

class _ReorderImagesScreenState extends State<_ReorderImagesScreen> {
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reordenar Imagens'),
        actions: [
          TextButton(
            onPressed: () {
              widget.onReorder(_images);
              Navigator.of(context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: EdgeInsets.all(LayoutConstants.paddingMd),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final imageUrl = _images[index];

          return Card(
            key: ValueKey(imageUrl),
            margin: EdgeInsets.only(bottom: LayoutConstants.marginSm),
            child: ListTile(
              contentPadding: EdgeInsets.all(LayoutConstants.paddingSm),
              leading: Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                  child: OfflineImage(
                    networkUrl: imageUrl.startsWith('http') ? imageUrl : null,
                    localPath: !imageUrl.startsWith('http') ? imageUrl : null,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: AppTheme.surfaceVariant,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      color: AppTheme.surfaceVariant,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppTheme.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                'Imagem ${index + 1}',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: LayoutConstants.fontSizeMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: LayoutConstants.fontSizeSmall,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de posição
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: LayoutConstants.marginSm),
                  // Handle de arrastar
                  Icon(Icons.drag_handle, color: AppTheme.textSecondary),
                ],
              ),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _images.removeAt(oldIndex);
            _images.insert(newIndex, item);
          });
        },
      ),
    );
  }
}
