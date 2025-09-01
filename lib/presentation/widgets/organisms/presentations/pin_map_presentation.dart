import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../domain/entities/map_pin.dart';
import '../../../../domain/enums/pin_content_type.dart';
import '../../../../infra/logging/app_logger.dart';
import '../../../../infra/platform/platform_service.dart';
import '../../../../infra/storage/map_data_storage.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../molecules/offline_image.dart';
import 'providers/pin_map_notifier.dart';

/// Apresentação de mapa interativo com pins editáveis
/// Permite visualização, edição e gerenciamento de pins no mapa
class PinMapPresentation extends ConsumerStatefulWidget {
  final String title;
  final String route;
  final String? backgroundImageUrl;
  final String? description;

  const PinMapPresentation({
    super.key,
    required this.title,
    required this.route,
    this.backgroundImageUrl,
    this.description,
  });

  @override
  ConsumerState<PinMapPresentation> createState() => _PinMapPresentationState();
}

class _PinMapPresentationState extends ConsumerState<PinMapPresentation> {
  final MapDataStorage _mapStorage = MapDataStorage();
  final TransformationController _transformationController = TransformationController();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Variáveis de compatibilidade (serão atualizadas pelo provider no build)
  InteractiveMapData? _mapData;
  MapPin? _selectedPin;
  bool _isEditMode = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isZoomed = false;
  VideoPlayerController? _videoController;

  // Mock data para demonstração
  final String _mockBackgroundImage =
      'https://via.placeholder.com/1200x800/E8F5E8/2E7D32?text=Mapa+Interativo';

  @override
  void initState() {
    super.initState();
    
    // Carregar dados usando o provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pinMapNotifierProvider(widget.route).notifier).loadMapData();
    });
    
    // Listener para detectar zoom
    _transformationController.addListener(_onTransformationChanged);
  }
  
  void _onTransformationChanged() {
    final matrix = _transformationController.value;
    final currentScale = matrix.getMaxScaleOnAxis();
    final isCurrentlyZoomed = currentScale > 1.0;
    
    if (isCurrentlyZoomed != _isZoomed) {
      ref.read(pinMapNotifierProvider(widget.route).notifier).setZoomed(isCurrentlyZoomed);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  /// Carrega os dados do mapa do storage local
  Future<void> _loadMapData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final mapData = await _mapStorage.loadMapData(widget.route);

      if (mapData == null) {
        // Cria dados iniciais se não existir - não é erro, é menu novo
        _mapData = InteractiveMapData(
          id: _uuid.v4(),
          routeId: widget.route,
          backgroundImageUrl: widget.backgroundImageUrl ?? _mockBackgroundImage,
          pins: [],
          createdAt: DateTime.now(),
        );
      } else {
        _mapData = mapData;
      }
    } catch (e) {
      // Em caso de erro, ainda cria dados iniciais para menus novos
      _mapData = InteractiveMapData(
        id: _uuid.v4(),
        routeId: widget.route,
        backgroundImageUrl: widget.backgroundImageUrl ?? _mockBackgroundImage,
        pins: [],
        createdAt: DateTime.now(),
      );
      _showErrorSnackBar('Aviso: Usando dados padrão - $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Salva os dados do mapa no storage local
  Future<void> _saveMapData() async {
    if (_mapData == null) return;

    try {
      final updatedMapData = _mapData!.copyWith(updatedAt: DateTime.now());

      await _mapStorage.saveMapData(updatedMapData);
      _mapData = updatedMapData;

      _showSuccessSnackBar('Dados salvos com sucesso!');
    } catch (e) {
      _showErrorSnackBar('Erro ao salvar dados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar o provider para obter o estado atual
    final pinMapState = ref.watch(pinMapStateProvider(widget.route));
    
    // Atualizar variáveis locais para compatibilidade com o resto do código existente
    _mapData = pinMapState.mapData;
    _selectedPin = pinMapState.selectedPin;
    _isEditMode = pinMapState.isEditMode;
    _isLoading = pinMapState.isLoading;
    _hasError = pinMapState.hasError;
    _isZoomed = pinMapState.isZoomed;
    _videoController = pinMapState.videoController;
    
    if (pinMapState.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: LayoutConstants.marginMd),
              Text(
                'Carregando mapa interativo...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: LayoutConstants.fontSizeMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Só mostra erro se realmente houve um erro de carregamento
    if (_hasError || _mapData == null) {
      return _buildErrorState();
    }

    // Se o mapa está vazio E não tem imagem de fundo customizada E não está no modo edição, mostra estado vazio informativo
    final hasCustomBackgroundImage =
        _mapData!.backgroundImageUrl != null &&
        _mapData!.backgroundImageUrl!.isNotEmpty &&
        _mapData!.backgroundImageUrl != _mockBackgroundImage;

    if (_mapData!.pins.isEmpty && !hasCustomBackgroundImage && !_isEditMode) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Mapa principal com pins
          Positioned.fill(
            child: MouseRegion(
              cursor: _isEditMode ? SystemMouseCursors.copy : SystemMouseCursors.basic,
              child: GestureDetector(
                onTapDown: _isEditMode ? _onMapTap : null,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 4.0, // Permite zoom até 4x
                  constrained: true, // Usa constraints do pai
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Usar dimensões seguras para evitar constraints infinitos
                      final safeWidth = constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : MediaQuery.of(context).size.width;
                      final safeHeight = constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : MediaQuery.of(context).size.height;

                      return SizedBox(
                        width: safeWidth,
                        height: safeHeight,
                        child: Stack(
                          children: [
                            // Imagem de fundo
                            Positioned.fill(child: _buildBackgroundImage()),
                            // Pins (ocultos durante zoom)
                            if (!_isZoomed)
                              ..._mapData!.pins.map(
                                (pin) =>
                                    _buildPin(pin, BoxConstraints.tight(Size(safeWidth, safeHeight))),
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

          // Controles superiores esquerdos (minimizados)
          if (_isEditMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + LayoutConstants.paddingMd,
              left: LayoutConstants.paddingMd,
              child: _buildTopLeftControls(),
            ),

          // Botões fixos
          _buildFloatingButtons(),

          // Detalhes do pin selecionado
          if (_selectedPin != null && !_isEditMode) _buildPinDetails(_selectedPin!),
        ],
      ),
    );
  }

  /// Constrói a imagem de fundo do mapa
  Widget _buildBackgroundImage() {
    final imageUrl = _mapData!.backgroundImageUrl ?? _mockBackgroundImage;
    final isMockImage = imageUrl == _mockBackgroundImage;

    AppLogger.debug('BUILD imageUrl: $imageUrl', tag: 'PinMap');
    AppLogger.debug('BUILD _mockBackgroundImage: $_mockBackgroundImage', tag: 'PinMap');
    AppLogger.debug('BUILD isMockImage: $isMockImage', tag: 'PinMap');
    AppLogger.debug('BUILD _isEditMode: $_isEditMode', tag: 'PinMap');

    // Se for imagem mock e estiver em modo edição, mostra instruções
    if (isMockImage && _isEditMode) {
      return Container(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        child: Stack(
          children: [
            // Pattern de fundo para indicar área tocável
            CustomPaint(size: Size.infinite, painter: _GridPainter()),

            // Instruções centralizadas
            Center(
              child: Container(
                padding: EdgeInsets.all(LayoutConstants.paddingLg),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, size: 48, color: AppTheme.primaryColor),
                    SizedBox(height: LayoutConstants.marginMd),
                    Text(
                      'Toque aqui para adicionar pins',
                      style: TextStyle(
                        fontSize: LayoutConstants.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: LayoutConstants.marginSm),
                    Text(
                      'Ou clique no botão 🖼️ no AppBar\npara adicionar uma imagem de fundo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: LayoutConstants.fontSizeMedium,
                        color: AppTheme.textSecondary,
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

    // Para web, blob URLs devem ser passados como networkUrl
    final isHttpUrl = imageUrl.startsWith('http');
    final isBlobUrl = imageUrl.startsWith('blob:');
    final shouldUseNetworkUrl = isHttpUrl || (PlatformService.isWeb && isBlobUrl);

    AppLogger.debug(
      'BUILD: isHttpUrl=$isHttpUrl, isBlobUrl=$isBlobUrl, shouldUseNetworkUrl=$shouldUseNetworkUrl',
      tag: 'PinMap',
    );

    return OfflineImage(
      key: ValueKey(imageUrl), // Force rebuild quando URL muda
      networkUrl: shouldUseNetworkUrl ? imageUrl : null,
      localPath: !shouldUseNetworkUrl ? imageUrl : null,
      fit: BoxFit.fill,
      placeholder: Container(
        color: AppTheme.surfaceColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3),
              SizedBox(height: LayoutConstants.marginMd),
              Text(
                'Carregando mapa...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: LayoutConstants.fontSizeMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      errorWidget: Container(
        color: AppTheme.surfaceColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: AppTheme.primaryColor),
            SizedBox(height: LayoutConstants.marginMd),
            Text(
              'Imagem do mapa não disponível',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: LayoutConstants.fontSizeLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: LayoutConstants.marginSm),
            Text(
              'Usando visualização padrão de mapa',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: LayoutConstants.fontSizeMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói os botões flutuantes fixos
  Widget _buildFloatingButtons() {
    return Positioned(
      right: LayoutConstants.paddingMd,
      bottom: MediaQuery.of(context).padding.bottom + LayoutConstants.paddingXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão Ver Vídeo
          if (_mapData!.videoUrl != null || _mapData!.videoPath != null)
            FloatingActionButton(
              heroTag: 'video',
              onPressed: _showVideo,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.play_arrow, color: Colors.white),
            ),

          if (_mapData!.videoUrl != null || _mapData!.videoPath != null)
            SizedBox(height: LayoutConstants.marginMd),

          // Botão Editar
          FloatingActionButton(
            heroTag: 'edit',
            onPressed: _toggleEditMode,
            backgroundColor: _isEditMode ? Colors.green : AppTheme.secondaryColor,
            child: Icon(_isEditMode ? Icons.check : Icons.edit, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Constrói um pin no mapa
  Widget _buildPin(MapPin pin, BoxConstraints constraints) {
    final left = (pin.positionX * constraints.maxWidth) - 24;
    final top = (pin.positionY * constraints.maxHeight) - 48;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _onPinTap(pin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pin icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _selectedPin?.id == pin.id ? AppTheme.secondaryColor : AppTheme.primaryColor,
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
              child: const Icon(Icons.place, color: Colors.white, size: 24),
            ),

            // Pin point
            Container(
              width: 6,
              height: 12,
              decoration: BoxDecoration(
                color: _selectedPin?.id == pin.id ? AppTheme.secondaryColor : AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
              ),
            ),

            // Título do pin sempre visível
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: 120),
              padding: EdgeInsets.symmetric(
                horizontal: LayoutConstants.paddingSm,
                vertical: LayoutConstants.paddingXs,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                border: Border.all(
                  color: _selectedPin?.id == pin.id
                      ? AppTheme.secondaryColor.withValues(alpha: 0.3)
                      : AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                pin.title,
                style: TextStyle(
                  fontSize: LayoutConstants.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: _selectedPin?.id == pin.id
                      ? AppTheme.secondaryColor
                      : AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói os detalhes do pin selecionado
  Widget _buildPinDetails(MapPin pin) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + LayoutConstants.paddingMd,
      left: LayoutConstants.paddingMd,
      right: LayoutConstants.paddingMd,
      child: Container(
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
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.place, color: Colors.white, size: 18),
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
                  onPressed: () => ref.read(pinMapNotifierProvider(widget.route).notifier).clearSelection(),
                  icon: Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),

            SizedBox(height: LayoutConstants.marginSm),

            Text(
              pin.description,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: LayoutConstants.fontSizeMedium,
              ),
            ),

            SizedBox(height: LayoutConstants.marginMd),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPinImages(pin),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Visualizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                SizedBox(width: LayoutConstants.marginSm),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editPin(pin),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                SizedBox(width: LayoutConstants.marginSm),

                IconButton(
                  onPressed: () => _deletePin(pin),
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Excluir',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói estado vazio informativo para novos menus Pins
  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Imagem de fundo com overlay
          Positioned.fill(
            child: Stack(
              children: [
                _buildBackgroundImage(),
                Container(color: AppTheme.backgroundColor.withValues(alpha: 0.85)),
              ],
            ),
          ),


          // Conteúdo central
          Positioned.fill(
            child: Padding(
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
                    child: Icon(Icons.map_outlined, size: 80, color: AppTheme.primaryColor),
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

                  // Subtítulo explicativo
                  Text(
                    'Este é um novo mapa interativo. Para começar:\n\n'
                    '1. Clique em "Começar a Editar" abaixo\n'
                    '2. Adicione uma imagem de fundo do mapa\n'
                    '3. Toque na imagem para adicionar pins',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: LayoutConstants.fontSizeMedium,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: LayoutConstants.marginXl),

                  // Botão de ação principal
                  ElevatedButton.icon(
                    onPressed: _toggleEditMode,
                    icon: const Icon(Icons.edit),
                    label: const Text('Começar a Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: LayoutConstants.paddingXl,
                        vertical: LayoutConstants.paddingMd,
                      ),
                    ),
                  ),

                  SizedBox(height: LayoutConstants.marginMd),

                  // Botão secundário
                  OutlinedButton.icon(
                    onPressed: _showEmptyMapInstructions,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Como usar mapas com pins'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: LayoutConstants.paddingLg,
                        vertical: LayoutConstants.paddingMd,
                      ),
                    ),
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
                            'Dica: Cada pin pode conter imagens, textos e informações detalhadas sobre pontos específicos',
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
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói estado de erro
  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: LayoutConstants.marginMd),
            Text(
              'Erro ao carregar dados do mapa',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: LayoutConstants.fontSizeLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: LayoutConstants.marginMd),
            ElevatedButton(onPressed: _loadMapData, child: const Text('Tentar Novamente')),
          ],
        ),
      ),
    );
  }

  /// Constrói controles superiores esquerdos minimizados
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
            icon: Icons.image,
            onPressed: _changeBackgroundImage,
            tooltip: 'Alterar imagem de fundo',
          ),
          
          SizedBox(height: LayoutConstants.marginSm),
          
          _buildControlButton(
            icon: Icons.videocam,
            onPressed: _uploadVideo,
            tooltip: 'Adicionar vídeo',
          ),
          
          SizedBox(height: LayoutConstants.marginSm),
          
          _buildControlButton(
            icon: Icons.fit_screen,
            onPressed: _resetZoom,
            tooltip: 'Ajustar à tela',
          ),
        ],
      ),
    );
  }

  /// Constrói botão de controle
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
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 20),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // === MÉTODOS DE AÇÃO ===

  /// Alterna modo de edição
  void _toggleEditMode() {
    ref.read(pinMapNotifierProvider(widget.route).notifier).toggleEditMode();

    if (!_isEditMode) {
      ref.read(pinMapNotifierProvider(widget.route).notifier).saveMapData();
    }

    if (_isEditMode) {
      _showEditModeDialog();
    }
  }

  /// Toque no mapa (modo edição)
  void _onMapTap(TapDownDetails details) {
    if (!_isEditMode) return;

    // Verificar se há imagem de fundo customizada
    final hasCustomBackgroundImage =
        _mapData!.backgroundImageUrl != null &&
        _mapData!.backgroundImageUrl!.isNotEmpty &&
        _mapData!.backgroundImageUrl != _mockBackgroundImage;

    // Se não há imagem customizada, abre modal para alterar imagem de fundo
    if (!hasCustomBackgroundImage) {
      _changeBackgroundImage();
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.globalToLocal(details.globalPosition);

    // Calcular posição relativa
    final relativeX = position.dx / renderBox.size.width;
    final relativeY = position.dy / renderBox.size.height;

    _showAddPinDialog(relativeX, relativeY);
  }

  /// Toque em um pin
  void _onPinTap(MapPin pin) {
    if (_isEditMode) {
      _editPin(pin);
    } else {
      setState(() {
        _selectedPin = _selectedPin?.id == pin.id ? null : pin;
      });
    }
  }

  /// Reset do zoom
  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  // === DIALOGS E MODALS ===

  /// Mostra dialog do modo de edição
  Future<void> _showEditModeDialog() async {
    final hasBackgroundImage =
        _mapData?.backgroundImageUrl != null &&
        _mapData!.backgroundImageUrl!.isNotEmpty &&
        _mapData!.backgroundImageUrl != _mockBackgroundImage;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: AppTheme.primaryColor),
              SizedBox(width: LayoutConstants.marginSm),
              const Text('Modo de Edição Ativo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasBackgroundImage) ...[
                Container(
                  padding: EdgeInsets.all(LayoutConstants.paddingMd),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      SizedBox(width: LayoutConstants.marginSm),
                      Expanded(
                        child: Text(
                          'Primeira etapa: Adicione uma imagem de fundo',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: LayoutConstants.marginMd),
                Text(
                  '1. Clique no botão 🖼️ no AppBar (parte superior) para adicionar uma imagem de fundo do mapa\n'
                  '2. Após adicionar a imagem, você poderá tocar nela para adicionar pins',
                  style: TextStyle(fontSize: LayoutConstants.fontSizeMedium, height: 1.4),
                ),
              ] else ...[
                Text(
                  'Agora você pode:\n'
                  '• Tocar na imagem do mapa para adicionar pins\n'
                  '• Tocar em pins existentes para editá-los\n'
                  '• Usar o botão 🖼️ no AppBar para trocar a imagem de fundo',
                  style: TextStyle(fontSize: LayoutConstants.fontSizeMedium, height: 1.4),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendi')),
          ],
        );
      },
    );
  }

  /// Mostra dialog para adicionar pin
  Future<void> _showAddPinDialog(double x, double y) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    PinContentType contentType = PinContentType.singleImage;
    List<String> imageUrls = [];

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar Pin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título*',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    DropdownButtonFormField<PinContentType>(
                      value: contentType,
                      onChanged: (value) => setState(() => contentType = value!),
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Conteúdo',
                        border: OutlineInputBorder(),
                      ),
                      items: PinContentType.values.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type.displayName));
                      }).toList(),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final images = await _pickImages(contentType);
                        setState(() => imageUrls = images);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: Text(
                        imageUrls.isEmpty
                            ? 'Selecionar Imagens*'
                            : '${imageUrls.length} imagem(s) selecionada(s)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      titleController.text.isNotEmpty &&
                          imageUrls.isNotEmpty
                      ? () {
                          _addPin(
                            x,
                            y,
                            titleController.text,
                            descriptionController.text,
                            contentType,
                            imageUrls,
                          );
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Adiciona um novo pin
  void _addPin(
    double x,
    double y,
    String title,
    String description,
    PinContentType contentType,
    List<String> imageUrls,
  ) {
    final newPin = MapPin(
      id: _uuid.v4(),
      title: title,
      description: description,
      positionX: x,
      positionY: y,
      contentType: contentType,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    setState(() {
      _mapData = _mapData!.copyWith(pins: [..._mapData!.pins, newPin]);
    });
  }

  /// Edita um pin existente
  void _editPin(MapPin pin) {
    final titleController = TextEditingController(text: pin.title);
    final descriptionController = TextEditingController(text: pin.description);
    PinContentType contentType = pin.contentType;
    List<String> imageUrls = List.from(pin.imageUrls);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Pin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título*',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    DropdownButtonFormField<PinContentType>(
                      value: contentType,
                      onChanged: (value) => setState(() => contentType = value!),
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Conteúdo',
                        border: OutlineInputBorder(),
                      ),
                      items: PinContentType.values.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type.displayName));
                      }).toList(),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final images = await _pickImages(contentType);
                        setState(() => imageUrls = images);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: Text('${imageUrls.length} imagem(s) selecionada(s)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updatePin(
                      pin.id,
                      titleController.text,
                      descriptionController.text,
                      contentType,
                      imageUrls,
                    );
                    Navigator.of(context).pop();
                    ref.read(pinMapNotifierProvider(widget.route).notifier).clearSelection();
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

  /// Atualiza um pin existente
  void _updatePin(
    String pinId,
    String title,
    String description,
    PinContentType contentType,
    List<String> imageUrls,
  ) {
    setState(() {
      _mapData = _mapData!.copyWith(
        pins: _mapData!.pins.map((pin) {
          if (pin.id == pinId) {
            return pin.copyWith(
              title: title,
              description: description,
              contentType: contentType,
              imageUrls: imageUrls,
              updatedAt: DateTime.now(),
            );
          }
          return pin;
        }).toList(),
      );
    });
  }

  /// Exclui um pin
  void _deletePin(MapPin pin) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Pin'),
          content: Text('Tem certeza que deseja excluir o pin "${pin.title}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _mapData = _mapData!.copyWith(
                    pins: _mapData!.pins.where((p) => p.id != pin.id).toList(),
                  );
                  _selectedPin = null;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Mostra as imagens do pin em tela fullscreen
  void _showPinImages(MapPin pin) {
    // Combinar URLs e paths locais
    final allImageUrls = <String>[
      ...pin.imageUrls,
      ...pin.imagePaths,
    ].where((url) => url.isNotEmpty).toList();

    if (allImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Este pin não possui imagens'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Navegar para tela fullscreen com o modal
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _FullScreenImageModal(
          imageUrls: allImageUrls,
          title: pin.title,
          description: pin.description,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }



  /// Mostra o vídeo em tela fullscreen
  void _showVideo() {
    if (_mapData!.videoUrl == null && _mapData!.videoPath == null) return;

    final videoSource = _mapData!.videoUrl ?? _mapData!.videoPath!;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _VideoPlayerScreen(videoSource: videoSource),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // === UTILITÁRIOS ===

  /// Seleciona imagens
  Future<List<String>> _pickImages(PinContentType contentType) async {
    try {
      if (contentType == PinContentType.singleImage) {
        final image = await _imagePicker.pickImage(source: ImageSource.gallery);
        return image != null ? [image.path] : [];
      } else {
        final images = await _imagePicker.pickMultiImage();
        return images.map((image) => image.path).toList();
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao selecionar imagens: $e');
      return [];
    }
  }

  /// Altera a imagem de fundo do mapa
  Future<void> _changeBackgroundImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress for performance
        maxWidth: 1920, // Limit size for performance
        maxHeight: 1080,
      );

      if (image != null && _mapData != null) {
        AppLogger.debug('Imagem selecionada: ${image.path}', tag: 'PinMap');

        // Verificar se o arquivo existe (apenas para platforms que suportam File)
        if (!PlatformService.isWeb) {
          final file = File(image.path);
          final exists = await file.exists();
          AppLogger.debug('Arquivo existe: $exists', tag: 'PinMap');

          if (!exists) {
            AppLogger.warning('Arquivo não existe no path: ${image.path}', tag: 'PinMap');
            _showErrorSnackBar('Arquivo de imagem não encontrado');
            return;
          }
        } else {
          AppLogger.debug('Plataforma Web - usando blob URL: ${image.path}', tag: 'PinMap');
        }

        // Atualizar a imagem de fundo nos dados do mapa
        _mapData = _mapData!.copyWith(
          backgroundImageUrl: image.path, // Use local path ou blob URL
          updatedAt: DateTime.now(),
        );

        AppLogger.debug('_mapData atualizado: ${_mapData!.backgroundImageUrl}', tag: 'PinMap');
        AppLogger.debug('_mockBackgroundImage: $_mockBackgroundImage', tag: 'PinMap');
        AppLogger.debug(
          'São diferentes? ${_mapData!.backgroundImageUrl != _mockBackgroundImage}',
          tag: 'PinMap',
        );

        // Salvar os dados atualizados
        await _saveMapData();

        // Aguardar um frame antes de chamar setState
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          setState(() {}); // Refresh UI
          AppLogger.debug('setState chamado - forçando rebuild', tag: 'PinMap');
          _showSuccessSnackBar('Imagem de fundo alterada com sucesso!');
        }
      } else {
        AppLogger.warning('Imagem nula ou _mapData nulo', tag: 'PinMap');
        if (image == null) AppLogger.debug('image é null', tag: 'PinMap');
        if (_mapData == null) AppLogger.debug('_mapData é null', tag: 'PinMap');
      }
    } catch (e) {
      AppLogger.error('Erro ao alterar imagem de fundo: $e', tag: 'PinMap');
      _showErrorSnackBar('Erro ao alterar imagem de fundo: $e');
    }
  }

  /// Upload de vídeo para o mapa
  Future<void> _uploadVideo() async {
    _showVideoConfigDialog();
  }
  
  /// Modal para configuração de vídeo com título e opção de remover
  void _showVideoConfigDialog() {
    final hasExistingVideo = _mapData?.videoUrl != null || _mapData?.videoPath != null;
    final titleController = TextEditingController(text: _mapData?.videoTitle ?? '');
    final urlController = TextEditingController(text: _mapData?.videoUrl ?? '');
    
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
    if (_mapData != null) {
      _mapData = _mapData!.copyWith(
        videoPath: null,
        videoUrl: null,
        videoTitle: null,
        updatedAt: DateTime.now(),
      );
      
      await _saveMapData();
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
      
      if (video != null && _mapData != null && mounted) {
        _mapData = _mapData!.copyWith(
          videoPath: video.path,
          videoUrl: null,
          videoTitle: title.trim().isEmpty ? 'Vídeo do mapa' : title.trim(),
          updatedAt: DateTime.now(),
        );
        
        await _saveMapData();
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
    
    if (_mapData != null && mounted) {
      _mapData = _mapData!.copyWith(
        videoUrl: url.trim(),
        videoPath: null,
        videoTitle: title.trim().isEmpty ? 'Vídeo do mapa' : title.trim(),
        updatedAt: DateTime.now(),
      );
      
      await _saveMapData();
      if (mounted) {
        setState(() {});
        Navigator.of(dialogContext).pop();
        _showSuccessSnackBar('Vídeo configurado com sucesso!');
      }
    }
  }

  /// Mostra snackbar de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  /// Mostra snackbar de sucesso
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  /// Mostra instruções sobre como usar mapas com pins
  Future<void> _showEmptyMapInstructions() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.map, color: AppTheme.primaryColor),
              SizedBox(width: LayoutConstants.marginSm),
              const Text('Como usar Mapas com Pins'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionStep(
                  '1',
                  'Modo de Edição',
                  'Clique no botão de edição (✏️) para começar a adicionar pins',
                ),

                SizedBox(height: LayoutConstants.marginMd),

                _buildInstructionStep(
                  '2',
                  'Adicionar Pins',
                  'Toque em qualquer lugar do mapa para adicionar um pin com informações',
                ),

                SizedBox(height: LayoutConstants.marginMd),

                _buildInstructionStep(
                  '3',
                  'Conteúdo dos Pins',
                  'Cada pin pode conter título, descrição, imagens e diferentes tipos de apresentação',
                ),

                SizedBox(height: LayoutConstants.marginMd),

                _buildInstructionStep(
                  '4',
                  'Visualizar',
                  'Saia do modo de edição para tocar nos pins e ver as informações',
                ),

                SizedBox(height: LayoutConstants.marginMd),

                Container(
                  padding: EdgeInsets.all(LayoutConstants.paddingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.primaryColor,
                        size: LayoutConstants.iconMedium,
                      ),
                      SizedBox(width: LayoutConstants.marginSm),
                      Expanded(
                        child: Text(
                          'Ideal para plantas baixas, mapas de localização, ou qualquer imagem onde você precisa destacar pontos específicos.',
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendi')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toggleEditMode();
              },
              child: const Text('Começar Agora'),
            ),
          ],
        );
      },
    );
  }

  /// Constrói um passo das instruções
  Widget _buildInstructionStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
          child: Center(
            child: Text(
              number,
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(width: LayoutConstants.marginMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: LayoutConstants.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: LayoutConstants.fontSizeSmall,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tela para reprodução de vídeo
class _VideoPlayerScreen extends StatefulWidget {
  final String videoSource;

  const _VideoPlayerScreen({required this.videoSource});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoSource.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoSource));
      } else {
        _controller = VideoPlayerController.file(File(widget.videoSource));
      }

      await _controller!.initialize();
      setState(() => _isInitialized = true);
      _controller!.play();
    } catch (e) {
      AppLogger.error('Erro ao inicializar vídeo: $e', tag: 'VideoPlayer');
      // Handle error with better feedback
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: Center(
        child: _isInitialized && _controller != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            : _controller == null && !_isInitialized
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Erro ao carregar vídeo',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Verifique a URL ou tente novamente',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
      ),
      floatingActionButton: _isInitialized && _controller != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                });
              },
              child: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }

}

/// Modal fullscreen para visualização de imagens com carousel
class _FullScreenImageModal extends StatefulWidget {
  final List<String> imageUrls;
  final String title;
  final String description;

  const _FullScreenImageModal({
    required this.imageUrls,
    required this.title,
    required this.description,
  });

  @override
  State<_FullScreenImageModal> createState() => _FullScreenImageModalState();
}

class _FullScreenImageModalState extends State<_FullScreenImageModal> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = widget.imageUrls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasMultipleImages)
              Text(
                '${_currentIndex + 1} de ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
        actions: [
          if (hasMultipleImages && _currentIndex > 0)
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
              onPressed: _previousImage,
            ),
          if (hasMultipleImages && _currentIndex < widget.imageUrls.length - 1)
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
              onPressed: _nextImage,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Carousel de imagens
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              final imageUrl = widget.imageUrls[index];
              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  maxScale: 3.0,
                  minScale: 0.8,
                  child: OfflineImage(
                    key: ValueKey(imageUrl),
                    networkUrl:
                        imageUrl.startsWith('http') ||
                            (PlatformService.isWeb && imageUrl.startsWith('blob:'))
                        ? imageUrl
                        : null,
                    localPath:
                        !(imageUrl.startsWith('http') ||
                            (PlatformService.isWeb && imageUrl.startsWith('blob:')))
                        ? imageUrl
                        : null,
                    fit: BoxFit.contain,
                    placeholder: Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                    errorWidget: Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_not_supported, color: Colors.white54, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'Imagem não encontrada',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: LayoutConstants.fontSizeMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Indicadores de páginas (dots) - apenas se múltiplas imagens
          if (hasMultipleImages)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),

          // Descrição no bottom (se houver)
          if (widget.description.isNotEmpty)
            Positioned(
              bottom: hasMultipleImages ? 80 : 40,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(LayoutConstants.paddingMd),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
                ),
                child: Text(
                  widget.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Navegação por gestos - setas laterais para múltiplas imagens
          if (hasMultipleImages) ...[
            // Área clicável esquerda
            if (_currentIndex > 0)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 60,
                child: GestureDetector(
                  onTap: _previousImage,
                  child: Container(
                    color: Colors.transparent,
                    child: const Center(
                      child: Icon(Icons.chevron_left, color: Colors.white54, size: 48),
                    ),
                  ),
                ),
              ),

            // Área clicável direita
            if (_currentIndex < widget.imageUrls.length - 1)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 60,
                child: GestureDetector(
                  onTap: _nextImage,
                  child: Container(
                    color: Colors.transparent,
                    child: const Center(
                      child: Icon(Icons.chevron_right, color: Colors.white54, size: 48),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}

/// Custom painter para desenhar grid no fundo
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    const spacing = 40.0;

    // Linhas verticais
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Linhas horizontais
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
