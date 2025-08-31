import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';

import '../../../../../domain/entities/map_pin.dart';
import '../../../../../domain/enums/pin_content_type.dart';
import '../../../../../infra/storage/map_data_storage.dart';
import '../../../../design_system/app_theme.dart';
import '../../../../design_system/layout_constants.dart';

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

  InteractiveMapData? _mapData;
  MapPin? _selectedPin;
  bool _isEditMode = false;
  bool _isLoading = false;
  VideoPlayerController? _videoController;

  // Mock data para demonstração
  final String _mockBackgroundImage = 'https://via.placeholder.com/1200x800/E8F5E8/2E7D32?text=Mapa+Interativo';

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  /// Carrega os dados do mapa do storage local
  Future<void> _loadMapData() async {
    setState(() => _isLoading = true);
    
    try {
      final mapData = await _mapStorage.loadMapData(widget.route);
      
      if (mapData == null) {
        // Cria dados iniciais se não existir
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
      _showErrorSnackBar('Erro ao carregar dados do mapa: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Salva os dados do mapa no storage local
  Future<void> _saveMapData() async {
    if (_mapData == null) return;
    
    try {
      final updatedMapData = _mapData!.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _mapStorage.saveMapData(updatedMapData);
      _mapData = updatedMapData;
      
      _showSuccessSnackBar('Dados salvos com sucesso!');
    } catch (e) {
      _showErrorSnackBar('Erro ao salvar dados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_mapData == null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Mapa principal com pins
          Positioned.fill(
            child: GestureDetector(
              onTapDown: _isEditMode ? _onMapTap : null,
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
                          // Imagem de fundo
                          Positioned.fill(
                            child: _buildBackgroundImage(),
                          ),
                          // Pins
                          ..._mapData!.pins.map((pin) => _buildPin(pin, constraints)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Header com controles
          _buildHeader(),

          // Botões fixos
          _buildFloatingButtons(),

          // Detalhes do pin selecionado
          if (_selectedPin != null && !_isEditMode)
            _buildPinDetails(_selectedPin!),
        ],
      ),
    );
  }

  /// Constrói a imagem de fundo do mapa
  Widget _buildBackgroundImage() {
    final imageUrl = _mapData!.backgroundImageUrl ?? _mockBackgroundImage;
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
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
                'Imagem do mapa não disponível',
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
    );
  }

  /// Constrói o header com título e controles
  Widget _buildHeader() {
    return Positioned(
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
            
            // Reset zoom button
            _buildControlButton(
              icon: Icons.fit_screen,
              onPressed: _resetZoom,
              tooltip: 'Ajustar à tela',
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
            child: Icon(
              _isEditMode ? Icons.check : Icons.edit,
              color: Colors.white,
            ),
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
                color: AppTheme.primaryColor,
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
              child: const Icon(
                Icons.place,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            // Pin point
            Container(
              width: 6,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
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
                  child: const Icon(
                    Icons.place,
                    color: Colors.white,
                    size: 18,
                  ),
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

  /// Constrói estado de erro
  Widget _buildErrorState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textSecondary,
            ),
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
            ElevatedButton(
              onPressed: _loadMapData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
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

  // === MÉTODOS DE AÇÃO ===

  /// Alterna modo de edição
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _selectedPin = null;
    });

    if (!_isEditMode) {
      _saveMapData();
    }

    if (_isEditMode) {
      _showEditModeDialog();
    }
  }

  /// Toque no mapa (modo edição)
  void _onMapTap(TapDownDetails details) {
    if (!_isEditMode) return;

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
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modo de Edição'),
          content: const Text(
            'Você está no modo de edição.\n\n'
            '• Toque em qualquer lugar do mapa para adicionar um novo pin\n'
            '• Toque em um pin existente para editá-lo\n'
            '• Use os botões na barra superior para gerenciar a imagem e vídeo',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
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
                        labelText: 'Descrição*',
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
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
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
                  onPressed: titleController.text.isNotEmpty &&
                      descriptionController.text.isNotEmpty &&
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
      _mapData = _mapData!.copyWith(
        pins: [..._mapData!.pins, newPin],
      );
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
                        labelText: 'Descrição*',
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
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
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
                    setState(() => _selectedPin = null);
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
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

  /// Mostra as imagens do pin
  void _showPinImages(MapPin pin) {
    if (pin.imageUrls.isEmpty) return;

    if (pin.contentType == PinContentType.singleImage) {
      _showSingleImage(pin.imageUrls.first);
    } else {
      _showImageCarousel(pin.imageUrls);
    }
  }

  /// Mostra uma única imagem
  void _showSingleImage(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: AppTheme.surfaceColor,
                  child: Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Mostra carrossel de imagens
  void _showImageCarousel(List<String> imageUrls) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            height: 400,
            child: PageView.builder(
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.surfaceColor,
                        child: Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Mostra o vídeo
  void _showVideo() {
    if (_mapData!.videoUrl == null && _mapData!.videoPath == null) return;

    final videoSource = _mapData!.videoUrl ?? _mapData!.videoPath!;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _VideoPlayerScreen(videoSource: videoSource),
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
  final String videoSource;

  const _VideoPlayerScreen({required this.videoSource});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _controller;
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
      
      await _controller.initialize();
      setState(() => _isInitialized = true);
      _controller.play();
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying 
                      ? _controller.pause() 
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}