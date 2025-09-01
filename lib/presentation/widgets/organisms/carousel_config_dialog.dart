import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/carousel_data.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../notification/snackbar_notification.dart';
import '../../responsive/breakpoints.dart';
import '../atoms/primary_button.dart';

/// Dialog para configuração de carousel com reordenação de imagens
class CarouselConfigDialog extends ConsumerStatefulWidget {
  final String routeId;
  final CarouselData? initialData;
  final Function(CarouselData) onSave;

  const CarouselConfigDialog({
    super.key,
    required this.routeId,
    this.initialData,
    required this.onSave,
  });

  @override
  ConsumerState<CarouselConfigDialog> createState() => _CarouselConfigDialogState();
}

class _CarouselConfigDialogState extends ConsumerState<CarouselConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _videoUrlController = TextEditingController();
  
  List<String> _imageUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _imageUrls = List.from(widget.initialData!.imageUrls);
      _videoUrlController.text = widget.initialData!.videoUrl ?? '';
    }
  }

  @override
  void dispose() {
    _videoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    
    if (isMobile) {
      return _buildMobileBottomSheet(context);
    } else {
      return _buildDesktopDialog(context);
    }
  }

  /// BottomSheet para mobile
  Widget _buildMobileBottomSheet(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(LayoutConstants.radiusLarge),
          topRight: Radius.circular(LayoutConstants.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          Flexible(
            child: _buildContent(context, isMobile: true),
          ),
        ],
      ),
    );
  }

  /// Dialog para desktop/tablet
  Widget _buildDesktopDialog(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
      ),
      child: Container(
        width: context.responsive<double>(
          xs: 400,
          md: 600,
          lg: 700,
          xl: 800,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: _buildContent(context, isMobile: false),
      ),
    );
  }

  /// Handle para arrastar no mobile
  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: EdgeInsets.only(top: LayoutConstants.paddingSm),
      decoration: BoxDecoration(
        color: AppTheme.outline,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Conteúdo principal
  Widget _buildContent(BuildContext context, {required bool isMobile}) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(LayoutConstants.paddingMd),
            child: Row(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  color: AppTheme.primaryColor,
                  size: LayoutConstants.iconLarge,
                ),
                SizedBox(width: LayoutConstants.marginSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configurar Carousel',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: LayoutConstants.fontSizeXLarge,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Adicione e reordene imagens com drag & drop',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: LayoutConstants.fontSizeSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),

          // Conteúdo scrollable
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: LayoutConstants.paddingMd),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lista de imagens reordenável
                    _buildImagesSection(),
                    SizedBox(height: LayoutConstants.marginLg),

                    // Campo de vídeo
                    _buildVideoSection(),
                    SizedBox(height: LayoutConstants.marginLg),
                  ],
                ),
              ),
            ),
          ),

          // Botões
          _buildActionButtons(context, isMobile),
        ],
      ),
    );
  }

  /// Seção de imagens com reordenação
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.reorder,
              color: AppTheme.primaryColor,
              size: LayoutConstants.iconMedium,
            ),
            SizedBox(width: LayoutConstants.marginSm),
            Text(
              'Imagens do Carousel',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: LayoutConstants.fontSizeLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            TextButton.icon(
              onPressed: _addNewImage,
              icon: Icon(Icons.add, size: 16),
              label: Text('Adicionar'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: LayoutConstants.marginSm),

        if (_imageUrls.isEmpty)
          _buildEmptyImagesState()
        else
          _buildReorderableImagesList(),
      ],
    );
  }

  /// Estado vazio de imagens
  Widget _buildEmptyImagesState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
        border: Border.all(color: AppTheme.outline, width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: LayoutConstants.marginMd),
          Text(
            'Nenhuma imagem adicionada',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: LayoutConstants.fontSizeMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: LayoutConstants.marginSm),
          Text(
            'Clique em "Adicionar" para incluir imagens no carousel',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: LayoutConstants.fontSizeSmall,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Lista reordenável de imagens
  Widget _buildReorderableImagesList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _imageUrls.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _imageUrls.removeAt(oldIndex);
          _imageUrls.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final imageUrl = _imageUrls[index];
        return _buildImageListItem(imageUrl, index);
      },
    );
  }

  /// Item da lista de imagens
  Widget _buildImageListItem(String imageUrl, int index) {
    return Card(
      key: ValueKey(imageUrl),
      margin: EdgeInsets.only(bottom: LayoutConstants.marginSm),
      child: ListTile(
        contentPadding: EdgeInsets.all(LayoutConstants.paddingSm),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
            border: Border.all(color: AppTheme.outline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.backgroundColor,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textSecondary,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppTheme.backgroundColor,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
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
            Icon(
              Icons.drag_handle,
              color: AppTheme.textSecondary,
            ),
            SizedBox(width: LayoutConstants.marginSm),
            IconButton(
              onPressed: () => _removeImage(index),
              icon: Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Remover imagem',
            ),
          ],
        ),
      ),
    );
  }

  /// Seção de vídeo
  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.video_library_outlined,
              color: AppTheme.primaryColor,
              size: LayoutConstants.iconMedium,
            ),
            SizedBox(width: LayoutConstants.marginSm),
            Text(
              'Vídeo (Opcional)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: LayoutConstants.fontSizeLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: LayoutConstants.marginSm),
        TextFormField(
          controller: _videoUrlController,
          decoration: InputDecoration(
            hintText: 'Cole a URL do vídeo aqui',
            prefixIcon: Icon(Icons.video_call_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
            ),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty && !Uri.tryParse(value)!.isAbsolute) {
              return 'URL inválida';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Botões de ação
  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (!isMobile)
            Expanded(
              child: AppButton.secondary(
                text: 'Cancelar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          if (!isMobile) SizedBox(width: LayoutConstants.marginMd),
          Expanded(
            child: AppButton.primary(
              text: 'Salvar Configuração',
              isLoading: _isLoading,
              onPressed: _imageUrls.isNotEmpty ? _saveConfiguration : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Adiciona nova imagem
  void _addNewImage() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Imagem'),
        content: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Cole a URL da imagem',
            prefixIcon: Icon(Icons.image_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _imageUrls.add(result);
      });
    }
  }

  /// Remove imagem
  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  /// Salva configuração
  void _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      SnackbarNotification.showError('Adicione pelo menos uma imagem');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final carouselData = CarouselData(
        id: widget.initialData?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        routeId: widget.routeId,
        imageUrls: _imageUrls,
        videoUrl: _videoUrlController.text.trim().isEmpty ? null : _videoUrlController.text.trim(),
        createdAt: widget.initialData?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(carouselData);
      Navigator.of(context).pop();
      SnackbarNotification.showSuccess('Carousel configurado com sucesso!');
    } catch (e) {
      SnackbarNotification.showError('Erro ao salvar configuração: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}