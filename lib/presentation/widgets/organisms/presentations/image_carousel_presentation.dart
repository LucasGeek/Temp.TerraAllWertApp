import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide MapType;
import 'package:uuid/uuid.dart';

import '../../../../domain/entities/carousel_data.dart';
import '../../../../domain/enums/map_type.dart';
import '../../../../infra/logging/app_logger.dart';
import '../../../../infra/platform/platform_service.dart';
import '../../../../infra/storage/carousel_data_storage.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../molecules/offline_image.dart';

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
  GoogleMapController? _mapController;
  
  CarouselData? _carouselData;
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _showControls = true; // Sempre visível agora
  
  // Mock removido - foco em estado vazio incentivando adição

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _transformationController = TransformationController();
    _loadCarouselData();
    
    // Controles sempre visíveis - removido timer
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
      _showErrorSnackBar('Aviso: Usando dados padrão - $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Salva os dados no storage local
  Future<void> _saveCarouselData() async {
    if (_carouselData == null) return;
    
    try {
      final updatedData = _carouselData!.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _carouselStorage.saveCarouselData(updatedData);
      _carouselData = updatedData;
      
      _showSuccessSnackBar('Dados salvos com sucesso!');
    } catch (e) {
      _showErrorSnackBar('Erro ao salvar dados: $e');
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
      _showErrorSnackBar('Erro ao inicializar vídeo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_carouselData == null) {
      return _buildErrorState();
    }

    // Estado vazio - incentiva adição de imagem
    if (_allImages.isEmpty && 
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
            Positioned.fill(
              child: _buildMainContent(),
            ),

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


            // Indicadores do carrossel (se múltiplas imagens)
            if (_showControls && _allImages.length > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + LayoutConstants.paddingXl,
                left: 0,
                right: 0,
                child: _buildPageIndicators(),
              ),

            // Overlay da caixa de texto
            if (_carouselData!.textBox != null)
              _buildTextBoxOverlay(_carouselData!.textBox!),
          ],
        ),
      ),
    );
  }

  /// Combina URLs online e paths locais das imagens
  List<String> get _allImages => [
    ..._carouselData!.imageUrls,
    ..._carouselData!.imagePaths,
  ];

  /// Constrói o conteúdo principal do carrossel
  Widget _buildMainContent() {
    final images = _allImages;
    
    if (images.isEmpty) {
      return _buildEmptyState();
    }

    if (images.length == 1) {
      return _buildSingleImage(images.first);
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: images.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        _resetZoom();
        _startControlsTimer();
      },
      itemBuilder: (context, index) {
        return _buildSingleImage(images[index]);
      },
    );
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

  /// Widget de imagem com tratamento de erro e loading robusto
  Widget _buildImageWidget(String imageUrl) {
    // Usa OfflineImage para tratamento robusto de erros e caching
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.of(context).size.height,
          child: OfflineImage(
            networkUrl: imageUrl.startsWith('http') ? imageUrl : null,
            localPath: !imageUrl.startsWith('http') ? imageUrl : null,
            fit: BoxFit.contain,
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
          width: constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.of(context).size.height,
          color: AppTheme.surfaceColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 3,
              ),
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
          width: constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.of(context).size.height,
          color: AppTheme.surfaceColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 80,
                color: AppTheme.textSecondary,
              ),
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
            child: Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: AppTheme.primaryColor,
            ),
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
            '🎥 Vídeos com título personalizado\n'
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
                onPressed: _addOrViewVideo,
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Adicionar Vídeo'),
                style: OutlinedButton.styleFrom(
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
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white,
            ),
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
            ElevatedButton(
              onPressed: _loadCarouselData,
              child: const Text('Tentar Novamente'),
            ),
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
          _buildControlButton(
            icon: Icons.videocam_outlined,
            onPressed: _addOrViewVideo,
            tooltip: _carouselData!.videoUrl != null || _carouselData!.videoPath != null
                ? 'Ver Vídeo'
                : 'Adicionar Vídeo',
          ),
          
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
          ),
          
          SizedBox(height: LayoutConstants.marginSm),
          
          _buildControlButton(
            icon: Icons.map_outlined,
            onPressed: _addOrEditMap,
            tooltip: _carouselData!.mapConfig != null ? 'Editar Mapa' : 'Adicionar Mapa',
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
          _buildControlButton(
            icon: Icons.zoom_in,
            onPressed: _zoomIn,
            tooltip: 'Aumentar Zoom',
          ),
          
          SizedBox(height: LayoutConstants.marginSm),
          
          _buildControlButton(
            icon: Icons.zoom_out,
            onPressed: _zoomOut,
            tooltip: 'Diminuir Zoom',
          ),
          
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


  /// Indicadores de páginas
  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _allImages.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentIndex 
                ? Colors.white 
                : Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
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
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // === MÉTODOS DE AÇÃO ===

  /// Alterna visibilidade dos controles
  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startControlsTimer();
    }
  }

  /// Timer para esconder controles
  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  /// Adiciona ou visualiza vídeo
  void _addOrViewVideo() async {
    _showVideoConfigDialog();
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
          if (hasExistingVideo)
            TextButton.icon(
              onPressed: () => _removeVideo(context),
              icon: Icon(Icons.delete, color: Colors.red),
              label: Text('Remover Vídeo', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
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
                onPressed: () => _saveVideoFromUrl(context, titleController.text, urlController.text),
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
      if (mounted) {
        setState(() {});
        Navigator.of(dialogContext).pop();
        _showSuccessSnackBar('Vídeo removido com sucesso!');
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
        if (mounted) {
          setState(() {});
          Navigator.of(dialogContext).pop();
          _showSuccessSnackBar('Vídeo adicionado com sucesso!');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao adicionar vídeo: $e');
      }
    }
  }
  
  /// Salva vídeo através de URL
  void _saveVideoFromUrl(BuildContext dialogContext, String title, String url) async {
    if (url.trim().isEmpty) {
      if (mounted) {
        _showErrorSnackBar('Por favor, insira uma URL válida');
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
        if (mounted) {
          setState(() {
            AppLogger.info('Estado atualizado após salvar vídeo');
          });
          Navigator.of(dialogContext).pop();
          _showSuccessSnackBar('Vídeo configurado com sucesso!');
        }
      } catch (e) {
        AppLogger.error('Erro ao salvar vídeo: $e');
        if (mounted) {
          _showErrorSnackBar('Erro ao salvar vídeo: $e');
        }
      }
    }
  }

  /// Seleciona vídeo da galeria
  Future<void> _pickVideo() async {
    try {
      final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _carouselData = _carouselData!.copyWith(
            videoPath: video.path,
          );
        });
        
        await _initializeVideoController();
        await _saveCarouselData();
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao selecionar vídeo: $e');
    }
  }

  /// Mostra o vídeo
  void _showVideo() {
    if (_videoController == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _VideoPlayerScreen(
          videoController: _videoController!,
          title: 'Vídeo - ${widget.title}',
        ),
      ),
    );
  }

  /// Adiciona imagens ao carrossel (usando lógica do PinMapPresentation)
  Future<void> _addImages() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty && _carouselData != null) {
        final imagePaths = <String>[];
        
        // Verificar cada imagem individualmente (como PinMapPresentation)
        for (final image in images) {
          AppLogger.debug('Imagem selecionada: ${image.path}', tag: 'ImageCarousel');
          
          // Verificar se o arquivo existe (apenas para platforms que suportam File)
          if (!PlatformService.isWeb) {
            final file = File(image.path);
            final exists = await file.exists();
            AppLogger.debug('Arquivo existe: $exists', tag: 'ImageCarousel');
            
            if (exists) {
              imagePaths.add(image.path);
            } else {
              AppLogger.warning('Arquivo não existe no path: ${image.path}', tag: 'ImageCarousel');
            }
          } else {
            AppLogger.debug('Plataforma Web - usando blob URL: ${image.path}', tag: 'ImageCarousel');
            imagePaths.add(image.path);
          }
        }
        
        if (imagePaths.isNotEmpty) {
          // Atualizar dados do carrossel
          _carouselData = _carouselData!.copyWith(
            imagePaths: [..._carouselData!.imagePaths, ...imagePaths],
            updatedAt: DateTime.now(),
          );
          
          AppLogger.debug('_carouselData atualizado com ${imagePaths.length} imagens', tag: 'ImageCarousel');
          
          // Salvar os dados atualizados
          await _saveCarouselData();
          
          // Aguardar um frame antes de chamar setState (como PinMapPresentation)
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (mounted) {
            setState(() {}); // Refresh UI explicitamente
            AppLogger.debug('setState chamado - forçando rebuild', tag: 'ImageCarousel');
            _showSuccessSnackBar('${imagePaths.length} imagem(ns) adicionada(s) com sucesso!');
          }
        } else {
          _showErrorSnackBar('Nenhuma imagem válida foi encontrada');
        }
      } else {
        AppLogger.warning('Imagens vazias ou _carouselData nulo', tag: 'ImageCarousel');
        if (images.isEmpty) AppLogger.debug('images está vazio', tag: 'ImageCarousel');
        if (_carouselData == null) AppLogger.debug('_carouselData é null', tag: 'ImageCarousel');
      }
    } catch (e) {
      AppLogger.error('Erro ao selecionar imagens: $e', tag: 'ImageCarousel');
      _showErrorSnackBar('Erro ao selecionar imagens: $e');
    }
  }

  /// Reordena imagens
  void _reorderImages() {
    if (_allImages.length <= 1) {
      _showErrorSnackBar('Precisa de pelo menos 2 imagens para reordenar');
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
    Color backgroundColor = existingTextBox != null ? Color(existingTextBox.backgroundColor) : Colors.white;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingTextBox != null ? 'Editar Caixa de Texto' : 'Adicionar Caixa de Texto'),
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
                              _buildColorPicker(fontColor, (color) => setState(() => fontColor = color)),
                            ],
                          ),
                        ),
                        SizedBox(width: LayoutConstants.marginMd),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Cor de Fundo'),
                              SizedBox(height: LayoutConstants.marginSm),
                              _buildColorPicker(backgroundColor, (color) => setState(() => backgroundColor = color)),
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
      Colors.black, Colors.white, Colors.red, Colors.green, 
      Colors.blue, Colors.yellow, Colors.orange, Colors.purple,
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
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
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
                      _showErrorSnackBar('Coordenadas inválidas');
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
      AppLogger.info('Salvando configuração do mapa: ${mapConfig.mapType.displayName} em ${mapConfig.latitude}, ${mapConfig.longitude}');
      
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
        _showSuccessSnackBar('Mapa adicionado com sucesso');
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar mapa: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao salvar mapa: $e');
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
    if (_carouselData!.imageUrls.isEmpty) return;
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Apagar Imagem'),
          content: const Text('Tem certeza que deseja apagar esta imagem?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeCurrentImage();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Apagar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Remove imagem atual
  Future<void> _removeCurrentImage() async {
    final images = List<String>.from(_carouselData!.imageUrls);
    if (images.isEmpty) return;
    
    images.removeAt(_currentIndex);
    
    // Ajusta índice se necessário
    if (_currentIndex >= images.length && images.isNotEmpty) {
      _currentIndex = images.length - 1;
    } else if (images.isEmpty) {
      _currentIndex = 0;
    }
    
    setState(() {
      _carouselData = _carouselData!.copyWith(imageUrls: images);
    });
    
    await _saveCarouselData();
  }

  // === CONTROLES DE ZOOM ===

  /// Aumenta o zoom
  void _zoomIn() {
    final matrix = _transformationController!.value.clone();
    matrix.scale(1.2);
    _transformationController!.value = matrix;
    setState(() {});
  }

  /// Diminui o zoom
  void _zoomOut() {
    final matrix = _transformationController!.value.clone();
    matrix.scale(0.8);
    _transformationController!.value = matrix;
    setState(() {});
  }

  /// Reseta o zoom
  void _resetZoom() {
    _transformationController!.value = Matrix4.identity();
    setState(() {});
  }

  // === UTILITÁRIOS ===

  /// Mostra snackbar de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Mostra snackbar de sucesso
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Tela para reprodução de vídeo
class _VideoPlayerScreen extends StatefulWidget {
  final VideoPlayerController videoController;
  final String title;

  const _VideoPlayerScreen({
    required this.videoController,
    required this.title,
  });

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    widget.videoController.play();
    _startControlsTimer();
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startControlsTimer();
    }
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
                          widget.videoController.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
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

  const _ReorderImagesScreen({
    required this.images,
    required this.onReorder,
  });

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
                  Icon(
                    Icons.drag_handle,
                    color: AppTheme.textSecondary,
                  ),
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