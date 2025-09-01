import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/entities/floor_plan_data.dart';
import '../../../../domain/enums/apartment_status.dart';
import '../../../../domain/enums/marker_type.dart';
import '../../../../domain/enums/sun_position.dart';
import '../../../../infra/cache/floor_plan_cache_adapter.dart';
import '../../../../infra/cache/cache_service.dart';
import '../../../../infra/upload/minio_upload_service.dart';
import '../../../../infra/sync/offline_sync_service.dart';
import '../../../../infra/graphql/graphql_client.dart';
import '../../../../infra/logging/app_logger.dart';
import '../../../../infra/storage/floor_plan_storage.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../notification/snackbar_notification.dart';
import 'providers/floor_plan_notifier.dart';

/// Apresentação de plantas de pavimento com gerenciamento completo
/// Suporta múltiplos pavimentos, marcadores e apartamentos
class FloorPlanPresentation extends ConsumerStatefulWidget {
  final String title;
  final String route;
  final String? floorNumber;
  final String? description;

  const FloorPlanPresentation({
    super.key,
    required this.title,
    required this.route,
    this.floorNumber,
    this.description,
  });

  @override
  ConsumerState<FloorPlanPresentation> createState() => _FloorPlanPresentationState();
}

class _FloorPlanPresentationState extends ConsumerState<FloorPlanPresentation> {
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final TransformationController _transformationController = TransformationController();
  final FloorPlanStorage _floorPlanStorage = FloorPlanStorage();

  // Cache services - serão inicializados no initState
  FloorPlanCacheAdapter? _floorPlanCacheAdapter;

  // Variáveis de compatibilidade (serão atualizadas pelo provider no build)
  FloorPlanData? _floorPlanData;
  Floor? _currentFloor;
  bool _isEditingMarkers = false;
  final Map<String, Uint8List> _floorImageBytesMap = {};


  @override
  void initState() {
    super.initState();
    
    // Inicializar serviços de cache
    _initializeCacheServices();
    
    // Carregar dados usando o provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(floorPlanNotifierProvider(widget.route).notifier).loadFloorPlanData();
    });
  }

  /// Inicializa os serviços de cache offline-first para plantas
  Future<void> _initializeCacheServices() async {
    try {
      // Inicializar cache service
      final cacheService = CacheService();
      await cacheService.initialize();
      
      // Obter GraphQL client do provider
      final graphqlClient = ref.read(graphQLClientProvider);
      
      // Inicializar upload service
      final uploadService = MinIOUploadService(
        cacheService: cacheService,
      );
      
      // Inicializar sync service para URLs baseadas na plataforma
      final syncService = OfflineSyncService(
        graphqlClient: graphqlClient,
      );
      
      // Inicializar adapter específico para plantas
      _floorPlanCacheAdapter = FloorPlanCacheAdapter(
        cacheService: cacheService,
        uploadService: uploadService,
        syncService: syncService,
      );
      
      AppLogger.info('FloorPlan cache services initialized successfully', tag: 'FloorPlan');
    } catch (e) {
      AppLogger.error('Failed to initialize FloorPlan cache services: $e', tag: 'FloorPlan');
      // Continue sem cache se falhar - fallback para ImagePicker
      _floorPlanCacheAdapter = null;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Carrega os dados da planta usando o provider
  Future<void> _loadFloorPlanData() async {
    await ref.read(floorPlanNotifierProvider(widget.route).notifier).loadFloorPlanData();
  }

  /// Salva os dados usando o provider
  Future<void> _saveFloorPlanData() async {
    await ref.read(floorPlanNotifierProvider(widget.route).notifier).saveFloorPlanData();
  }

  @override
  Widget build(BuildContext context) {
    // Usar o provider para obter o estado atual
    final floorPlanState = ref.watch(floorPlanStateProvider(widget.route));
    
    // Mostrar erro se houver
    if (floorPlanState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarNotification.showError(floorPlanState.error!);
        ref.read(floorPlanNotifierProvider(widget.route).notifier).clearError();
      });
    }
    
    if (floorPlanState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (floorPlanState.floorPlanData == null) {
      return _buildErrorState();
    }

    // Atualizar variáveis locais para compatibilidade com o resto do código existente
    _floorPlanData = floorPlanState.floorPlanData;
    _currentFloor = floorPlanState.currentFloor;

    // CRÍTICO: Verificar se há pavimento atual disponível
    if (_currentFloor == null || _floorPlanData!.floors.isEmpty) {
      return _buildNoFloorsState();
    }
    // _isLoading removido - agora gerenciado pelo provider
    _isEditingMarkers = floorPlanState.isEditingMarkers;
    _floorImageBytesMap.clear();
    _floorImageBytesMap.addAll(floorPlanState.floorImageBytesMap);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        mainAxisSize: MainAxisSize.min, // CRÍTICO: Previne RenderFlex overflow
        children: [
          // Header com dropdown e controles
          _buildHeader(),

          // Planta principal - usar Expanded em vez de Flexible
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      // Imagem de fundo com marcadores
                      Positioned.fill(
                        child: GestureDetector(
                          onTapDown: _isEditingMarkers ? _onFloorPlanTap : null,
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 1.0,
                            maxScale: 3.0,
                            constrained: true, // Manter como true
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: Stack(
                                fit: StackFit.expand, // Força o Stack a ocupar todo espaço
                                children: [
                                  // Imagem de fundo
                                  _buildFloorPlanImage(),

                                  // Marcadores
                                  ..._currentFloor!.markers.map(
                                    (marker) => _buildMarker(
                                      marker,
                                      BoxConstraints.tight(
                                        Size(constraints.maxWidth, constraints.maxHeight),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Controles flutuantes sobre a imagem
                      _buildFloatingControls(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o header com dropdown e controles
  Widget _buildHeader() {
    return Container(
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
          // Dropdown de pavimentos
          Flexible(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: LayoutConstants.paddingMd),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.outline),
                borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Floor>(
                  value: _currentFloor,
                  isExpanded: true,
                  onChanged: (floor) {
                    if (floor != null) {
                      ref.read(floorPlanNotifierProvider(widget.route).notifier).setCurrentFloor(floor);
                    }
                  },
                  items: _floorPlanData!.floors.map((floor) {
                    return DropdownMenuItem(
                      value: floor,
                      child: Text(
                        floor.number,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: LayoutConstants.fontSizeMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          SizedBox(width: LayoutConstants.marginSm),

          // Adicionar pavimento
          IconButton(
            onPressed: _addFloor,
            icon: Icon(Icons.add, color: AppTheme.primaryColor),
            tooltip: 'Adicionar Pavimento',
          ),

          // Excluir pavimento
          IconButton(
            onPressed: _floorPlanData!.floors.length > 1 ? _deleteCurrentFloor : null,
            icon: Icon(
              Icons.delete_outline,
              color: _floorPlanData!.floors.length > 1 ? Colors.red : Colors.grey,
            ),
            tooltip: 'Excluir Pavimento',
          ),
        ],
      ),
    );
  }

  /// Constrói a imagem da planta do pavimento
  Widget _buildFloorPlanImage() {
    // Verifica se há bytes de imagem para o pavimento atual (Web)
    final currentFloorId = _currentFloor!.id;
    if (_floorImageBytesMap.containsKey(currentFloorId)) {
      return Image.memory(
        _floorImageBytesMap[currentFloorId]!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      );
    }

    final imagePath = _currentFloor!.floorPlanImagePath;
    final imageUrl = _currentFloor!.floorPlanImageUrl;

    if (!kIsWeb && imagePath != null && imagePath.isNotEmpty) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover, // ou BoxFit.contain
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      );
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildImageError();
    }

    return imageUrl.startsWith('http')
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover, // ou BoxFit.contain
            errorBuilder: (context, error, stackTrace) => _buildImageError(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildImageLoading(loadingProgress);
            },
          )
        : kIsWeb
        ? _buildImageError()
        : Image.file(
            File(imageUrl),
            fit: BoxFit.cover, // ou BoxFit.contain
            errorBuilder: (context, error, stackTrace) => _buildImageError(),
          );
  }

  /// Estado de erro da imagem
  Widget _buildImageError() {
    return Container(
      color: AppTheme.surfaceColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture_outlined, size: 64, color: AppTheme.textSecondary),
          SizedBox(height: LayoutConstants.marginMd),
          Text(
            'Planta do pavimento não disponível',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: LayoutConstants.fontSizeLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Loading da imagem
  Widget _buildImageLoading(ImageChunkEvent loadingProgress) {
    return Container(
      color: AppTheme.surfaceColor,
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  /// Estado de erro
  Widget _buildErrorState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: LayoutConstants.marginMd),
            Text(
              'Erro ao carregar dados da planta',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: LayoutConstants.fontSizeLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: LayoutConstants.marginMd),
            ElevatedButton(onPressed: _loadFloorPlanData, child: const Text('Tentar Novamente')),
          ],
        ),
      ),
    );
  }

  /// Estado quando não há pavimentos
  Widget _buildNoFloorsState() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apartment_outlined, size: 96, color: AppTheme.textSecondary),
            SizedBox(height: LayoutConstants.marginLg),
            Text(
              'Nenhum pavimento configurado',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: LayoutConstants.fontSizeXLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: LayoutConstants.marginMd),
            Text(
              'Adicione um pavimento para começar',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: LayoutConstants.fontSizeMedium,
              ),
            ),
            SizedBox(height: LayoutConstants.marginXl),
            ElevatedButton.icon(
              onPressed: _addFloor,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                'Adicionar Primeiro Pavimento',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: LayoutConstants.paddingXl,
                  vertical: LayoutConstants.paddingMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Controles flutuantes sobre a imagem
  Widget _buildFloatingControls() {
    return Positioned(
      top: LayoutConstants.paddingMd,
      right: LayoutConstants.paddingMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Editar imagem
          _buildFloatingButton(
            icon: Icons.edit_outlined,
            onPressed: _editFloorPlanImage,
            tooltip: 'Editar Imagem',
            backgroundColor: AppTheme.primaryColor,
          ),

          SizedBox(height: LayoutConstants.marginSm),

          // Adicionar marcador
          _buildFloatingButton(
            icon: _isEditingMarkers ? Icons.check : Icons.add_location_alt,
            onPressed: _toggleMarkerEditing,
            tooltip: _isEditingMarkers ? 'Finalizar Edição' : 'Adicionar Marcador',
            backgroundColor: _isEditingMarkers ? Colors.green : AppTheme.secondaryColor,
          ),
        ],
      ),
    );
  }

  /// Botão flutuante customizado
  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color backgroundColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 24),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  /// Constrói um marcador na planta
  Widget _buildMarker(FloorMarker marker, BoxConstraints constraints) {
    final left = (marker.positionX * constraints.maxWidth) - 20;
    final top = (marker.positionY * constraints.maxHeight) - 40;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _onMarkerTap(marker),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone do marcador
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: marker.markerType == MarkerType.existingApartment
                    ? AppTheme.primaryColor
                    : AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                marker.markerType == MarkerType.existingApartment
                    ? Icons.home
                    : Icons.add_home_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),

            // Ponto do marcador
            Container(
              width: 4,
              height: 8,
              decoration: BoxDecoration(
                color: marker.markerType == MarkerType.existingApartment
                    ? AppTheme.primaryColor
                    : AppTheme.secondaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === MÉTODOS DE AÇÃO ===

  /// Adiciona um novo pavimento
  Future<void> _addFloor() async {
    final nameController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Pavimento'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do Pavimento*',
              border: OutlineInputBorder(),
              hintText: 'Ex: 2º Pavimento, Térreo, Subsolo...',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  await ref.read(floorPlanNotifierProvider(widget.route).notifier).addFloor(
                    nameController.text,
                    null, // imagePath
                    null, // imageBytes
                  );
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  /// Exclui o pavimento atual
  Future<void> _deleteCurrentFloor() async {
    if (_floorPlanData!.floors.length <= 1) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Pavimento'),
          content: Text('Tem certeza que deseja excluir o pavimento "${_currentFloor!.number}"?\n\nTodos os marcadores e a imagem deste pavimento serão perdidos.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final floorIdToDelete = _currentFloor!.id;
                Navigator.of(context).pop();
                await ref.read(floorPlanNotifierProvider(widget.route).notifier).removeFloor(floorIdToDelete);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Edita a imagem da planta do pavimento
  Future<void> _editFloorPlanImage() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Imagem do Pavimento'),
          content: const Text('Escolha uma nova imagem para a planta do pavimento.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickFloorPlanImage();
              },
              child: const Text('Selecionar Imagem'),
            ),
          ],
        );
      },
    );
  }

  /// Seleciona imagem da galeria usando cache offline-first
  Future<void> _pickFloorPlanImage() async {
    try {
      String? cachedPath;
      
      // Tentar usar cache adapter primeiro
      if (_floorPlanCacheAdapter != null && _currentFloor != null) {
        AppLogger.debug('Using FloorPlan cache adapter for image selection', tag: 'FloorPlan');
        
        cachedPath = await _floorPlanCacheAdapter!.selectAndCacheFloorPlan(
          routeId: widget.route,
          floorId: _currentFloor!.id,
        );
        
        if (cachedPath != null) {
          // Obter bytes do cache para o provider
          final cachedBytes = await _floorPlanCacheAdapter!.getCachedFloorPlan(cachedPath);
          
          if (cachedBytes != null) {
            // Atualizar através do provider
            ref.read(floorPlanNotifierProvider(widget.route).notifier).updateFloorImageBytes(
              _currentFloor!.id, 
              cachedBytes
            );
            
            await _saveFloorPlanData();
            AppLogger.info('Floor plan image cached and updated successfully', tag: 'FloorPlan');
            return;
          }
        }
      }
      
      // Fallback para métodos tradicionais se cache falhar
      AppLogger.debug('Falling back to traditional image picker for floor plan', tag: 'FloorPlan');
      
      if (kIsWeb) {
        // No Web, usa FilePicker para obter bytes
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          if (file.bytes != null) {
            // Atualizar através do provider
            ref.read(floorPlanNotifierProvider(widget.route).notifier).updateFloorImageBytes(
              _currentFloor!.id, 
              file.bytes!
            );
            
            // Persistir bytes no storage (para Web)
            await _floorPlanStorage.saveImageBytes(
              widget.route, 
              _currentFloor!.id, 
              file.bytes!
            );

            await _saveFloorPlanData();
          }
        }
      } else {
        // Em plataformas nativas, usa ImagePicker
        final image = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final imageBytes = await image.readAsBytes();
          ref.read(floorPlanNotifierProvider(widget.route).notifier).updateFloorImageBytes(
            _currentFloor!.id, 
            imageBytes
          );

          await _saveFloorPlanData();
        }
      }
    } catch (e) {
      AppLogger.error('Error selecting floor plan image: $e', tag: 'FloorPlan');
      SnackbarNotification.showError('Erro ao selecionar imagem: $e');
    }
  }

  /// Alterna modo de edição de marcadores
  void _toggleMarkerEditing() {
    ref.read(floorPlanNotifierProvider(widget.route).notifier).toggleEditingMarkers();

    if (!_isEditingMarkers) {
      _saveFloorPlanData();
    } else {
      SnackbarNotification.showInfo('Toque em qualquer lugar da planta para adicionar um marcador');
    }
  }

  /// Toque na planta (modo edição)
  void _onFloorPlanTap(TapDownDetails details) {
    if (!_isEditingMarkers) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.globalToLocal(details.globalPosition);

    // Calcular posição relativa
    final relativeX = position.dx / renderBox.size.width;
    final relativeY = position.dy / renderBox.size.height;

    // Validar se está dentro dos limites da imagem
    if (relativeX >= 0 && relativeX <= 1 && relativeY >= 0 && relativeY <= 1) {
      _showAddMarkerDialog(relativeX, relativeY);
    }
  }

  /// Dialog para adicionar marcador - VERSÃO CORRIGIDA
  Future<void> _showAddMarkerDialog(double x, double y) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    // SOLUÇÃO 1: Deixar sem valor inicial (null)
    MarkerType? markerType; // Mudança aqui - nullable
    Apartment? selectedApartment;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar Marcador'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropdown sem valor inicial
                    DropdownButtonFormField<MarkerType>(
                      value: markerType, // Pode ser null inicialmente
                      onChanged: (value) => setState(() {
                        markerType = value!;
                        selectedApartment = null;
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Marcador*',
                        border: OutlineInputBorder(),
                        hintText: 'Selecione o tipo de marcador', // Adicionar hint
                      ),
                      items: MarkerType.values.map((type) {
                        return DropdownMenuItem(
                          value: type, 
                          child: Text(type.displayName)
                        );
                      }).toList(),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    // Condicional para apartamento existente
                    if (markerType == MarkerType.existingApartment) ...[
                      DropdownButtonFormField<Apartment>(
                        value: selectedApartment,
                        onChanged: (apartment) => setState(() => selectedApartment = apartment),
                        decoration: const InputDecoration(
                          labelText: 'Selecionar Apartamento*',
                          border: OutlineInputBorder(),
                          hintText: 'Escolha um apartamento',
                        ),
                        items: _floorPlanData!.apartments.map((apartment) {
                          return DropdownMenuItem(
                            value: apartment,
                            child: Text('Apt ${apartment.number} - ${apartment.area}m²'),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: LayoutConstants.marginMd),
                    ],

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título*',
                        border: OutlineInputBorder(),
                      ),
                      // IMPORTANTE: Atualizar estado quando título muda
                      onChanged: (value) => setState(() {}),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
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
                  // LÓGICA DE VALIDAÇÃO CORRIGIDA
                  onPressed: _isAddMarkerButtonEnabled(titleController.text, markerType, selectedApartment)
                      ? () {
                          _addMarker(
                            x,
                            y,
                            titleController.text,
                            descriptionController.text,
                            markerType!, // Safe porque validamos antes
                            selectedApartment?.id,
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

  /// Método auxiliar para validar se o botão deve estar habilitado
  bool _isAddMarkerButtonEnabled(String title, MarkerType? markerType, Apartment? selectedApartment) {
    // Verificar se título está preenchido
    if (title.trim().isEmpty) return false;
    
    // Verificar se tipo de marcador foi selecionado
    if (markerType == null) return false;
    
    // Se for apartamento existente, verificar se apartamento foi selecionado
    if (markerType == MarkerType.existingApartment && selectedApartment == null) {
      return false;
    }
    
    return true;
  }

  /// Método auxiliar para validação do formulário de apartamento
  bool _isCreateApartmentValid(String number, String area) {
    if (number.trim().isEmpty) return false;
    final parsedArea = double.tryParse(area);
    return parsedArea != null && parsedArea > 0;
  }

  /// Seleciona imagem para apartamento usando cache offline-first
  Future<void> _selectApartmentImage(
    StateSetter setState, 
    Function(String?, Uint8List?, String?) onImageSelected,
  ) async {
    try {
      String? cachedPath;
      
      // Tentar usar cache adapter primeiro para imagens de referência
      if (_floorPlanCacheAdapter != null && _currentFloor != null) {
        AppLogger.debug('Using FloorPlan cache adapter for apartment image selection', tag: 'FloorPlan');
        
        final cachedPaths = await _floorPlanCacheAdapter!.selectAndCacheReferenceImages(
          routeId: widget.route,
          floorId: _currentFloor!.id,
          allowMultiple: false, // Apenas uma imagem por apartamento
        );
        
        if (cachedPaths.isNotEmpty) {
          cachedPath = cachedPaths.first;
          // Obter bytes do cache
          final cachedBytes = await _floorPlanCacheAdapter!.getCachedReferenceImage(cachedPath);
          
          if (cachedBytes != null) {
            setState(() {
              onImageSelected(cachedPath, cachedBytes, cachedPath?.split('/').last ?? 'cached_image');
            });
            AppLogger.info('Apartment image cached and selected successfully', tag: 'FloorPlan');
            return;
          }
        }
      }
      
      // Fallback para métodos tradicionais se cache falhar
      AppLogger.debug('Falling back to traditional image picker for apartment', tag: 'FloorPlan');
      
      if (kIsWeb) {
        // Web: usar FilePicker para obter bytes
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          if (file.bytes != null) {
            setState(() {
              onImageSelected(null, file.bytes, file.name);
            });
          }
        }
      } else {
        // Mobile: usar ImagePicker
        final image = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final imageBytes = await image.readAsBytes();
          setState(() {
            onImageSelected(image.path, imageBytes, image.name);
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error selecting apartment image: $e', tag: 'FloorPlan');
      SnackbarNotification.showError('Erro ao selecionar imagem: $e');
    }
  }

  /// Cria apartamento com imagem
  Future<void> _createApartmentWithImage(
    FloorMarker marker,
    String number,
    double area,
    int bedrooms,
    int suites,
    SunPosition sunPosition,
    ApartmentStatus status,
    String? imagePath,
    Uint8List? imageBytes,
  ) async {
    final newApartment = Apartment(
      id: _uuid.v4(),
      number: number,
      area: area,
      bedrooms: bedrooms,
      suites: suites,
      sunPosition: sunPosition,
      status: status,
      floorPlanImagePath: imagePath,
      createdAt: DateTime.now(),
    );

    // Salvar bytes da imagem se fornecidos (Web)
    if (imageBytes != null) {
      _floorPlanStorage.saveImageBytes(
        widget.route, 
        newApartment.id, 
        imageBytes
      );
    }

    try {
      // Primeiro, adicionar o apartamento usando o provider
      await ref.read(floorPlanNotifierProvider(widget.route).notifier).addApartment(newApartment);
      
      // Depois, atualizar o marcador usando o provider
      final updatedMarker = marker.copyWith(
        markerType: MarkerType.existingApartment,
        apartmentId: newApartment.id,
        updatedAt: DateTime.now(),
      );

      // Remover o marcador antigo e adicionar o atualizado
      await ref.read(floorPlanNotifierProvider(widget.route).notifier).removeMarker(marker.id);
      await ref.read(floorPlanNotifierProvider(widget.route).notifier).addMarker(updatedMarker);

      SnackbarNotification.showSuccess('Apartamento criado com sucesso!');
    } catch (e) {
      SnackbarNotification.showError('Erro ao criar apartamento: $e');
    }
  }

  /// Atualiza apartamento com imagem
  Future<void> _updateApartmentWithImage(
    String apartmentId,
    String number,
    double area,
    int bedrooms,
    int suites,
    SunPosition sunPosition,
    ApartmentStatus status,
    String? imagePath,
    Uint8List? imageBytes,
  ) async {
    // Salvar bytes da imagem se fornecidos (Web)
    if (imageBytes != null) {
      _floorPlanStorage.saveImageBytes(
        widget.route, 
        apartmentId, 
        imageBytes
      );
    }

    try {
      // Encontrar o apartamento atual para preservar dados não modificados
      final floorPlanState = ref.read(floorPlanStateProvider(widget.route));
      final currentApartment = floorPlanState.floorPlanData?.apartments
          .firstWhere((apt) => apt.id == apartmentId);
          
      if (currentApartment == null) {
        SnackbarNotification.showError('Apartamento não encontrado');
        return;
      }

      final updatedApartment = currentApartment.copyWith(
        number: number,
        area: area,
        bedrooms: bedrooms,
        suites: suites,
        sunPosition: sunPosition,
        status: status,
        floorPlanImagePath: imagePath,
        updatedAt: DateTime.now(),
      );

      // Usar o provider para atualizar
      await ref.read(floorPlanNotifierProvider(widget.route).notifier)
          .updateApartment(updatedApartment);

      SnackbarNotification.showSuccess('Apartamento atualizado com sucesso!');
    } catch (e) {
      SnackbarNotification.showError('Erro ao atualizar apartamento: $e');
    }
  }

  /// Adiciona um novo marcador
  void _addMarker(
    double x,
    double y,
    String title,
    String description,
    MarkerType markerType,
    String? apartmentId,
  ) {
    final newMarker = FloorMarker(
      id: _uuid.v4(),
      title: title,
      description: description.isNotEmpty ? description : null,
      positionX: x,
      positionY: y,
      markerType: markerType,
      apartmentId: apartmentId,
      createdAt: DateTime.now(),
    );

    ref.read(floorPlanNotifierProvider(widget.route).notifier).addMarker(newMarker);
  }

  /// Toque em um marcador
  void _onMarkerTap(FloorMarker marker) {
    if (_isEditingMarkers) {
      _editMarker(marker);
    } else {
      _showMarkerOptions(marker);
    }
  }

  /// Mostra opções do marcador
  void _showMarkerOptions(FloorMarker marker) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(LayoutConstants.paddingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                marker.title,
                style: TextStyle(
                  fontSize: LayoutConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              if (marker.description != null) ...[
                SizedBox(height: LayoutConstants.marginSm),
                Text(
                  marker.description!,
                  style: TextStyle(
                    fontSize: LayoutConstants.fontSizeMedium,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],

              SizedBox(height: LayoutConstants.marginLg),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (marker.apartmentId != null) {
                          _editApartment(marker.apartmentId!);
                        } else {
                          _createNewApartment(marker);
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(
                        marker.apartmentId != null ? 'Editar Apartamento' : 'Criar Apartamento',
                      ),
                    ),
                  ),

                  SizedBox(width: LayoutConstants.marginSm),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _editMarkerPosition(marker);
                      },
                      icon: const Icon(Icons.edit_location),
                      label: const Text('Editar Posição'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                    ),
                  ),

                  SizedBox(width: LayoutConstants.marginSm),

                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteMarker(marker);
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Excluir Marcador',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Edita um marcador
  void _editMarker(FloorMarker marker) {
    final titleController = TextEditingController(text: marker.title);
    final descriptionController = TextEditingController(text: marker.description ?? '');

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Marcador'),
          content: Column(
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
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                _updateMarker(marker.id, titleController.text, descriptionController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  /// Atualiza um marcador
  void _updateMarker(String markerId, String title, String description) {
    // Busca o marcador atual
    final currentMarker = _currentFloor!.markers.firstWhere((m) => m.id == markerId);
    
    // Cria o marcador atualizado
    final updatedMarker = currentMarker.copyWith(
      title: title,
      description: description.isNotEmpty ? description : null,
      updatedAt: DateTime.now(),
    );

    // Remove o antigo e adiciona o novo via provider
    ref.read(floorPlanNotifierProvider(widget.route).notifier).removeMarker(markerId);
    ref.read(floorPlanNotifierProvider(widget.route).notifier).addMarker(updatedMarker);
  }

  /// Cria novo apartamento a partir do marcador - COM UPLOAD
  void _createNewApartment(FloorMarker marker) {
    final numberController = TextEditingController();
    final areaController = TextEditingController();
    int bedrooms = 1;
    int suites = 0;
    SunPosition sunPosition = SunPosition.north;
    ApartmentStatus status = ApartmentStatus.available;
    
    // Variáveis para controle do upload
    String? selectedImagePath;
    Uint8List? selectedImageBytes;
    String? selectedImageName;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Criar Apartamento - ${marker.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Número*',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    TextField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: 'Área (m²)*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => setState(() {}),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dormitórios: $bedrooms'),
                              Slider(
                                value: bedrooms.toDouble(),
                                min: 1,
                                max: 5,
                                divisions: 4,
                                onChanged: (value) => setState(() => bedrooms = value.toInt()),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: LayoutConstants.marginMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Suítes: $suites'),
                              Slider(
                                value: suites.toDouble(),
                                min: 0,
                                max: 3,
                                divisions: 3,
                                onChanged: (value) => setState(() => suites = value.toInt()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    DropdownButtonFormField<SunPosition>(
                      value: sunPosition,
                      onChanged: (value) => setState(() => sunPosition = value!),
                      decoration: const InputDecoration(
                        labelText: 'Posição Solar',
                        border: OutlineInputBorder(),
                      ),
                      items: SunPosition.values.map((position) {
                        return DropdownMenuItem(value: position, child: Text(position.displayName));
                      }).toList(),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    DropdownButtonFormField<ApartmentStatus>(
                      value: status,
                      onChanged: (value) => setState(() => status = value!),
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ApartmentStatus.values.map((status) {
                        return DropdownMenuItem(value: status, child: Text(status.displayName));
                      }).toList(),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    // SEÇÃO DE UPLOAD DA PLANTA BAIXA
                    Container(
                      padding: EdgeInsets.all(LayoutConstants.paddingMd),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.outline),
                        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                        color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planta Baixa do Apartamento',
                            style: TextStyle(
                              fontSize: LayoutConstants.fontSizeMedium,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          
                          SizedBox(height: LayoutConstants.marginSm),
                          
                          if (selectedImageName != null) ...[
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: LayoutConstants.marginSm),
                                Expanded(
                                  child: Text(
                                    selectedImageName!,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: LayoutConstants.fontSizeSmall,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() {
                                    selectedImagePath = null;
                                    selectedImageBytes = null;
                                    selectedImageName = null;
                                  }),
                                  icon: Icon(Icons.close, color: Colors.red, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                                ),
                              ],
                            ),
                            SizedBox(height: LayoutConstants.marginSm),
                          ],
                          
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _selectApartmentImage(setState, (path, bytes, name) {
                                selectedImagePath = path;
                                selectedImageBytes = bytes;
                                selectedImageName = name;
                              }),
                              icon: Icon(
                                selectedImageName != null ? Icons.edit : Icons.upload_file,
                                size: 20,
                              ),
                              label: Text(
                                selectedImageName != null 
                                  ? 'Alterar Imagem' 
                                  : 'Selecionar Imagem',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: LayoutConstants.paddingMd,
                                  horizontal: LayoutConstants.paddingMd,
                                ),
                              ),
                            ),
                          ),
                          
                          if (selectedImageName == null) ...[
                            SizedBox(height: LayoutConstants.marginSm),
                            Text(
                              'Formatos aceitos: JPG, PNG, PDF',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: LayoutConstants.fontSizeSmall,
                              ),
                            ),
                          ],
                        ],
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
                  onPressed: _isCreateApartmentValid(numberController.text, areaController.text)
                      ? () async {
                          final navigator = Navigator.of(context);
                          final area = double.tryParse(areaController.text) ?? 0.0;
                          await _createApartmentWithImage(
                            marker,
                            numberController.text,
                            area,
                            bedrooms,
                            suites,
                            sunPosition,
                            status,
                            selectedImagePath,
                            selectedImageBytes,
                          );
                          navigator.pop();
                        }
                      : null,
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  /// Edita apartamento existente - COM UPLOAD
  void _editApartment(String apartmentId) {
    final apartment = _floorPlanData!.apartments.firstWhere((apt) => apt.id == apartmentId);

    final numberController = TextEditingController(text: apartment.number);
    final areaController = TextEditingController(text: apartment.area.toString());
    int bedrooms = apartment.bedrooms;
    int suites = apartment.suites;
    SunPosition sunPosition = apartment.sunPosition;
    ApartmentStatus status = apartment.status;
    
    // Variáveis para controle do upload
    String? selectedImagePath = apartment.floorPlanImagePath;
    Uint8List? selectedImageBytes;
    String? selectedImageName = apartment.floorPlanImagePath?.split('/').last;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Editar Apartamento ${apartment.number}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Número*',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    TextField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: 'Área (m²)*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => setState(() {}),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dormitórios: $bedrooms'),
                              Slider(
                                value: bedrooms.toDouble(),
                                min: 1,
                                max: 5,
                                divisions: 4,
                                onChanged: (value) => setState(() => bedrooms = value.toInt()),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: LayoutConstants.marginMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Suítes: $suites'),
                              Slider(
                                value: suites.toDouble(),
                                min: 0,
                                max: 3,
                                divisions: 3,
                                onChanged: (value) => setState(() => suites = value.toInt()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    DropdownButtonFormField<SunPosition>(
                      value: sunPosition,
                      onChanged: (value) => setState(() => sunPosition = value!),
                      decoration: const InputDecoration(
                        labelText: 'Posição Solar',
                        border: OutlineInputBorder(),
                      ),
                      items: SunPosition.values.map((position) {
                        return DropdownMenuItem(value: position, child: Text(position.displayName));
                      }).toList(),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    DropdownButtonFormField<ApartmentStatus>(
                      value: status,
                      onChanged: (value) => setState(() => status = value!),
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ApartmentStatus.values.map((status) {
                        return DropdownMenuItem(value: status, child: Text(status.displayName));
                      }).toList(),
                    ),

                    SizedBox(height: LayoutConstants.marginMd),

                    // SEÇÃO DE UPLOAD DA PLANTA BAIXA
                    Container(
                      padding: EdgeInsets.all(LayoutConstants.paddingMd),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.outline),
                        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                        color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planta Baixa do Apartamento',
                            style: TextStyle(
                              fontSize: LayoutConstants.fontSizeMedium,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          
                          SizedBox(height: LayoutConstants.marginSm),
                          
                          if (selectedImageName != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle, 
                                  color: Colors.green, 
                                  size: 20
                                ),
                                SizedBox(width: LayoutConstants.marginSm),
                                Expanded(
                                  child: Text(
                                    selectedImageName!,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: LayoutConstants.fontSizeSmall,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() {
                                    selectedImagePath = null;
                                    selectedImageBytes = null;
                                    selectedImageName = null;
                                  }),
                                  icon: Icon(Icons.close, color: Colors.red, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                                ),
                              ],
                            ),
                            SizedBox(height: LayoutConstants.marginSm),
                          ],
                          
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _selectApartmentImage(setState, (path, bytes, name) {
                                selectedImagePath = path;
                                selectedImageBytes = bytes;
                                selectedImageName = name;
                              }),
                              icon: Icon(
                                selectedImageName != null ? Icons.edit : Icons.upload_file,
                                size: 20,
                              ),
                              label: Text(
                                selectedImageName != null 
                                  ? 'Alterar Imagem' 
                                  : 'Selecionar Imagem',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: LayoutConstants.paddingMd,
                                  horizontal: LayoutConstants.paddingMd,
                                ),
                              ),
                            ),
                          ),
                          
                          if (selectedImageName == null) ...[
                            SizedBox(height: LayoutConstants.marginSm),
                            Text(
                              'Formatos aceitos: JPG, PNG, PDF',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: LayoutConstants.fontSizeSmall,
                              ),
                            ),
                          ],
                        ],
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
                  onPressed: _isCreateApartmentValid(numberController.text, areaController.text)
                      ? () async {
                          final navigator = Navigator.of(context);
                          final area = double.tryParse(areaController.text) ?? 0.0;
                          await _updateApartmentWithImage(
                            apartmentId,
                            numberController.text,
                            area,
                            bedrooms,
                            suites,
                            sunPosition,
                            status,
                            selectedImagePath,
                            selectedImageBytes,
                          );
                          navigator.pop();
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


  /// Edita posição do marcador
  void _editMarkerPosition(FloorMarker marker) {
    final xController = TextEditingController(text: marker.positionX.toStringAsFixed(3));
    final yController = TextEditingController(text: marker.positionY.toStringAsFixed(3));

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Posição do Marcador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Coordenadas (valores entre 0 e 1)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: LayoutConstants.fontSizeSmall,
                ),
              ),

              SizedBox(height: LayoutConstants.marginMd),

              TextField(
                controller: xController,
                decoration: const InputDecoration(
                  labelText: 'Posição X*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),

              SizedBox(height: LayoutConstants.marginMd),

              TextField(
                controller: yController,
                decoration: const InputDecoration(
                  labelText: 'Posição Y*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final x = double.tryParse(xController.text) ?? 0.0;
                final y = double.tryParse(yController.text) ?? 0.0;

                if (x >= 0 && x <= 1 && y >= 0 && y <= 1) {
                  _updateMarkerPosition(marker.id, x, y);
                  Navigator.of(context).pop();
                } else {
                  SnackbarNotification.showError('Coordenadas devem estar entre 0 e 1');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  /// Atualiza posição do marcador
  void _updateMarkerPosition(String markerId, double x, double y) {
    // Busca o marcador atual
    final currentMarker = _currentFloor!.markers.firstWhere((m) => m.id == markerId);
    
    // Cria o marcador com posição atualizada
    final updatedMarker = currentMarker.copyWith(
      positionX: x, 
      positionY: y, 
      updatedAt: DateTime.now()
    );

    // Remove o antigo e adiciona o novo via provider
    ref.read(floorPlanNotifierProvider(widget.route).notifier).removeMarker(markerId);
    ref.read(floorPlanNotifierProvider(widget.route).notifier).addMarker(updatedMarker);

    SnackbarNotification.showSuccess('Posição atualizada com sucesso!');
  }

  /// Exclui um marcador
  void _deleteMarker(FloorMarker marker) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Marcador'),
          content: Text('Tem certeza que deseja excluir o marcador "${marker.title}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(floorPlanNotifierProvider(widget.route).notifier).removeMarker(marker.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // === UTILITÁRIOS ===

}
