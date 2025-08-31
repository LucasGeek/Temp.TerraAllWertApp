import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../../domain/entities/floor_plan_data.dart';
import '../../../../../domain/enums/apartment_status.dart';
import '../../../../../domain/enums/sun_position.dart';
import '../../../../../domain/enums/marker_type.dart';
import '../../../../../infra/storage/floor_plan_storage.dart';
import '../../../../design_system/app_theme.dart';
import '../../../../design_system/layout_constants.dart';

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
  final FloorPlanStorage _floorPlanStorage = FloorPlanStorage();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final TransformationController _transformationController = TransformationController();

  FloorPlanData? _floorPlanData;
  Floor? _currentFloor;
  bool _isLoading = false;
  bool _isEditingMarkers = false;

  // Mock data para demonstração
  final String _mockFloorPlan = 'https://via.placeholder.com/1000x700/F5F5F5/333333?text=Planta+do+Pavimento';

  @override
  void initState() {
    super.initState();
    _loadFloorPlanData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Carrega os dados da planta do storage local
  Future<void> _loadFloorPlanData() async {
    setState(() => _isLoading = true);
    
    try {
      final floorPlanData = await _floorPlanStorage.loadFloorPlanData(widget.route);
      
      if (floorPlanData == null) {
        // Cria dados iniciais com um pavimento padrão
        final defaultFloor = Floor(
          id: _uuid.v4(),
          number: widget.floorNumber ?? '1º Pavimento',
          floorPlanImageUrl: _mockFloorPlan,
          createdAt: DateTime.now(),
        );
        
        _floorPlanData = FloorPlanData(
          id: _uuid.v4(),
          routeId: widget.route,
          floors: [defaultFloor],
          createdAt: DateTime.now(),
        );
        _currentFloor = defaultFloor;
      } else {
        _floorPlanData = floorPlanData;
        _currentFloor = floorPlanData.floors.isNotEmpty ? floorPlanData.floors.first : null;
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar dados da planta: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Salva os dados no storage local
  Future<void> _saveFloorPlanData() async {
    if (_floorPlanData == null) return;
    
    try {
      final updatedData = _floorPlanData!.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _floorPlanStorage.saveFloorPlanData(updatedData);
      _floorPlanData = updatedData;
      
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

    if (_floorPlanData == null || _currentFloor == null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header com dropdown e controles
          _buildHeader(),
          
          // Planta principal
          Expanded(
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
                                  child: _buildFloorPlanImage(),
                                ),
                                
                                // Marcadores
                                ..._currentFloor!.markers.map((marker) => 
                                  _buildMarker(marker, constraints)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Controles flutuantes sobre a imagem
                _buildFloatingControls(),
              ],
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
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
            iconSize: LayoutConstants.iconLarge,
          ),
          
          SizedBox(width: LayoutConstants.marginSm),
          
          // Dropdown de pavimentos
          Expanded(
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
                  onChanged: (floor) => setState(() => _currentFloor = floor),
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
    final imageUrl = _currentFloor!.floorPlanImageUrl ?? _mockFloorPlan;
    
    return imageUrl.startsWith('http')
        ? Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildImageError(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildImageLoading(loadingProgress);
            },
          )
        : Image.file(
            File(imageUrl),
            fit: BoxFit.contain,
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
          Icon(
            Icons.architecture_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textSecondary,
            ),
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
            ElevatedButton(
              onPressed: _loadFloorPlanData,
              child: const Text('Tentar Novamente'),
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
          icon: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newFloor = Floor(
                    id: _uuid.v4(),
                    number: nameController.text,
                    floorPlanImageUrl: _mockFloorPlan,
                    createdAt: DateTime.now(),
                  );
                  
                  setState(() {
                    _floorPlanData = _floorPlanData!.copyWith(
                      floors: [..._floorPlanData!.floors, newFloor],
                    );
                    _currentFloor = newFloor;
                  });
                  
                  _saveFloorPlanData();
                  Navigator.of(context).pop();
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
          content: Text('Tem certeza que deseja excluir o pavimento "${_currentFloor!.number}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final floors = _floorPlanData!.floors.where((f) => f.id != _currentFloor!.id).toList();
                
                setState(() {
                  _floorPlanData = _floorPlanData!.copyWith(floors: floors);
                  _currentFloor = floors.first;
                });
                
                _saveFloorPlanData();
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

  /// Edita a imagem da planta do pavimento
  Future<void> _editFloorPlanImage() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Imagem do Pavimento'),
          content: const Text('Escolha uma nova imagem para a planta do pavimento.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
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

  /// Seleciona imagem da galeria
  Future<void> _pickFloorPlanImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final updatedFloors = _floorPlanData!.floors.map((floor) {
          if (floor.id == _currentFloor!.id) {
            return floor.copyWith(
              floorPlanImagePath: image.path,
              updatedAt: DateTime.now(),
            );
          }
          return floor;
        }).toList();
        
        setState(() {
          _floorPlanData = _floorPlanData!.copyWith(floors: updatedFloors);
          _currentFloor = updatedFloors.firstWhere((f) => f.id == _currentFloor!.id);
        });
        
        await _saveFloorPlanData();
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao selecionar imagem: $e');
    }
  }

  /// Alterna modo de edição de marcadores
  void _toggleMarkerEditing() {
    setState(() {
      _isEditingMarkers = !_isEditingMarkers;
    });
    
    if (!_isEditingMarkers) {
      _saveFloorPlanData();
    } else {
      _showInfoSnackBar('Toque em qualquer lugar da planta para adicionar um marcador');
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

  /// Dialog para adicionar marcador
  Future<void> _showAddMarkerDialog(double x, double y) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    MarkerType markerType = MarkerType.newApartment;
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
                    DropdownButtonFormField<MarkerType>(
                      value: markerType,
                      onChanged: (value) => setState(() {
                        markerType = value!;
                        selectedApartment = null;
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Marcador',
                        border: OutlineInputBorder(),
                      ),
                      items: MarkerType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                    ),
                    
                    SizedBox(height: LayoutConstants.marginMd),
                    
                    if (markerType == MarkerType.existingApartment) ...[
                      DropdownButtonFormField<Apartment>(
                        value: selectedApartment,
                        onChanged: (apartment) => setState(() => selectedApartment = apartment),
                        decoration: const InputDecoration(
                          labelText: 'Selecionar Apartamento',
                          border: OutlineInputBorder(),
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
                  onPressed: titleController.text.isNotEmpty &&
                      (markerType == MarkerType.newApartment || selectedApartment != null)
                      ? () {
                          _addMarker(
                            x,
                            y,
                            titleController.text,
                            descriptionController.text,
                            markerType,
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

    final updatedFloors = _floorPlanData!.floors.map((floor) {
      if (floor.id == _currentFloor!.id) {
        return floor.copyWith(
          markers: [...floor.markers, newMarker],
          updatedAt: DateTime.now(),
        );
      }
      return floor;
    }).toList();

    setState(() {
      _floorPlanData = _floorPlanData!.copyWith(floors: updatedFloors);
      _currentFloor = updatedFloors.firstWhere((f) => f.id == _currentFloor!.id);
    });
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
                      label: Text(marker.apartmentId != null ? 'Editar Apartamento' : 'Criar Apartamento'),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateMarker(
                  marker.id,
                  titleController.text,
                  descriptionController.text,
                );
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
    final updatedFloors = _floorPlanData!.floors.map((floor) {
      if (floor.id == _currentFloor!.id) {
        final updatedMarkers = floor.markers.map((marker) {
          if (marker.id == markerId) {
            return marker.copyWith(
              title: title,
              description: description.isNotEmpty ? description : null,
              updatedAt: DateTime.now(),
            );
          }
          return marker;
        }).toList();
        
        return floor.copyWith(
          markers: updatedMarkers,
          updatedAt: DateTime.now(),
        );
      }
      return floor;
    }).toList();

    setState(() {
      _floorPlanData = _floorPlanData!.copyWith(floors: updatedFloors);
      _currentFloor = updatedFloors.firstWhere((f) => f.id == _currentFloor!.id);
    });
    
    _saveFloorPlanData();
  }

  /// Cria novo apartamento a partir do marcador
  void _createNewApartment(FloorMarker marker) {
    final numberController = TextEditingController();
    final areaController = TextEditingController();
    int bedrooms = 1;
    int suites = 0;
    SunPosition sunPosition = SunPosition.north;
    ApartmentStatus status = ApartmentStatus.available;

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
                    ),
                    
                    SizedBox(height: LayoutConstants.marginMd),
                    
                    TextField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: 'Área (m²)*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                        return DropdownMenuItem(
                          value: position,
                          child: Text(position.displayName),
                        );
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
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }).toList(),
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
                  onPressed: numberController.text.isNotEmpty &&
                      areaController.text.isNotEmpty
                      ? () {
                          final area = double.tryParse(areaController.text) ?? 0.0;
                          if (area > 0) {
                            _createApartment(
                              marker,
                              numberController.text,
                              area,
                              bedrooms,
                              suites,
                              sunPosition,
                              status,
                            );
                            Navigator.of(context).pop();
                          }
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

  /// Cria um novo apartamento
  void _createApartment(
    FloorMarker marker,
    String number,
    double area,
    int bedrooms,
    int suites,
    SunPosition sunPosition,
    ApartmentStatus status,
  ) {
    final newApartment = Apartment(
      id: _uuid.v4(),
      number: number,
      area: area,
      bedrooms: bedrooms,
      suites: suites,
      sunPosition: sunPosition,
      status: status,
      createdAt: DateTime.now(),
    );

    // Atualiza o marcador para referenciar o apartamento
    final updatedFloors = _floorPlanData!.floors.map((floor) {
      if (floor.id == _currentFloor!.id) {
        final updatedMarkers = floor.markers.map((m) {
          if (m.id == marker.id) {
            return m.copyWith(
              markerType: MarkerType.existingApartment,
              apartmentId: newApartment.id,
              updatedAt: DateTime.now(),
            );
          }
          return m;
        }).toList();
        
        return floor.copyWith(markers: updatedMarkers);
      }
      return floor;
    }).toList();

    setState(() {
      _floorPlanData = _floorPlanData!.copyWith(
        floors: updatedFloors,
        apartments: [..._floorPlanData!.apartments, newApartment],
      );
      _currentFloor = updatedFloors.firstWhere((f) => f.id == _currentFloor!.id);
    });
    
    _saveFloorPlanData();
    _showSuccessSnackBar('Apartamento criado com sucesso!');
  }

  /// Edita apartamento existente
  void _editApartment(String apartmentId) {
    final apartment = _floorPlanData!.apartments.firstWhere((apt) => apt.id == apartmentId);
    
    final numberController = TextEditingController(text: apartment.number);
    final areaController = TextEditingController(text: apartment.area.toString());
    int bedrooms = apartment.bedrooms;
    int suites = apartment.suites;
    SunPosition sunPosition = apartment.sunPosition;
    ApartmentStatus status = apartment.status;

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
                    ),
                    
                    SizedBox(height: LayoutConstants.marginMd),
                    
                    TextField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: 'Área (m²)*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                        return DropdownMenuItem(
                          value: position,
                          child: Text(position.displayName),
                        );
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
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }).toList(),
                    ),
                    
                    SizedBox(height: LayoutConstants.marginMd),
                    
                    ElevatedButton.icon(
                      onPressed: () => _uploadFloorPlan(apartmentId),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Planta Baixa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
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
                  onPressed: () {
                    final area = double.tryParse(areaController.text) ?? 0.0;
                    if (numberController.text.isNotEmpty && area > 0) {
                      _updateApartment(
                        apartmentId,
                        numberController.text,
                        area,
                        bedrooms,
                        suites,
                        sunPosition,
                        status,
                      );
                      Navigator.of(context).pop();
                    }
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

  /// Atualiza um apartamento
  void _updateApartment(
    String apartmentId,
    String number,
    double area,
    int bedrooms,
    int suites,
    SunPosition sunPosition,
    ApartmentStatus status,
  ) {
    final updatedApartments = _floorPlanData!.apartments.map((apt) {
      if (apt.id == apartmentId) {
        return apt.copyWith(
          number: number,
          area: area,
          bedrooms: bedrooms,
          suites: suites,
          sunPosition: sunPosition,
          status: status,
          updatedAt: DateTime.now(),
        );
      }
      return apt;
    }).toList();

    setState(() {
      _floorPlanData = _floorPlanData!.copyWith(apartments: updatedApartments);
    });
    
    _saveFloorPlanData();
    _showSuccessSnackBar('Apartamento atualizado com sucesso!');
  }

  /// Upload de planta baixa do apartamento
  Future<void> _uploadFloorPlan(String apartmentId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;
        
        if (filePath != null) {
          final updatedApartments = _floorPlanData!.apartments.map((apt) {
            if (apt.id == apartmentId) {
              return apt.copyWith(
                floorPlanImagePath: filePath,
                updatedAt: DateTime.now(),
              );
            }
            return apt;
          }).toList();

          setState(() {
            _floorPlanData = _floorPlanData!.copyWith(apartments: updatedApartments);
          });
          
          await _saveFloorPlanData();
          _showSuccessSnackBar('Planta baixa salva com sucesso!');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao fazer upload: $e');
    }
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final x = double.tryParse(xController.text) ?? 0.0;
                final y = double.tryParse(yController.text) ?? 0.0;
                
                if (x >= 0 && x <= 1 && y >= 0 && y <= 1) {
                  _updateMarkerPosition(marker.id, x, y);
                  Navigator.of(context).pop();
                } else {
                  _showErrorSnackBar('Coordenadas devem estar entre 0 e 1');
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
    final updatedFloors = _floorPlanData!.floors.map((floor) {
      if (floor.id == _currentFloor!.id) {
        final updatedMarkers = floor.markers.map((marker) {
          if (marker.id == markerId) {
            return marker.copyWith(
              positionX: x,
              positionY: y,
              updatedAt: DateTime.now(),
            );
          }
          return marker;
        }).toList();
        
        return floor.copyWith(markers: updatedMarkers);
      }
      return floor;
    }).toList();

    setState(() {
      _floorPlanData = _floorPlanData!.copyWith(floors: updatedFloors);
      _currentFloor = updatedFloors.firstWhere((f) => f.id == _currentFloor!.id);
    });
    
    _saveFloorPlanData();
    _showSuccessSnackBar('Posição atualizada com sucesso!');
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedFloors = _floorPlanData!.floors.map((floor) {
                  if (floor.id == _currentFloor!.id) {
                    return floor.copyWith(
                      markers: floor.markers.where((m) => m.id != marker.id).toList(),
                    );
                  }
                  return floor;
                }).toList();

                setState(() {
                  _floorPlanData = _floorPlanData!.copyWith(floors: updatedFloors);
                  _currentFloor = updatedFloors.firstWhere((f) => f.id == _currentFloor!.id);
                });
                
                _saveFloorPlanData();
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

  /// Mostra snackbar de info
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}