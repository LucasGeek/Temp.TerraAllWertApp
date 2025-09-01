import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';
import '../atoms/primary_button.dart';
import '../../../infra/graphql/settings_service.dart';
import '../../../infra/cache/logo_cache_service.dart';
import 'package:dio/dio.dart';

class SettingsModal extends ConsumerStatefulWidget {
  const SettingsModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SettingsModal(),
    );
  }

  @override
  ConsumerState<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends ConsumerState<SettingsModal> {
  bool _isUploading = false;
  Uint8List? _selectedImageBytes;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: context.responsive<double>(
            xs: MediaQuery.of(context).size.width * 0.9,
            sm: 400,
            md: 500,
            lg: 600,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LayoutConstants.radiusMedium),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Configurações do App',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: AppTheme.onPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logo do Aplicativo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: LayoutConstants.paddingMd),
          _buildLogoSection(),
          SizedBox(height: LayoutConstants.paddingLg),
          _buildUploadSection(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              border: Border.all(color: AppTheme.outline),
            ),
            child: _selectedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.business,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
          ),
          SizedBox(height: LayoutConstants.paddingMd),
          Text(
            _selectedImageBytes != null
                ? 'Nova logo selecionada'
                : 'Logo atual do aplicativo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alterar Logo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: LayoutConstants.paddingXs),
        Text(
          'Selecione uma nova imagem para usar como logo do aplicativo.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: LayoutConstants.paddingMd),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _selectImage,
            icon: Icon(Icons.upload_file),
            label: Text('Selecionar Imagem'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.all(LayoutConstants.paddingMd),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          SizedBox(width: LayoutConstants.paddingMd),
          AppButton.primary(
            text: 'Salvar',
            isLoading: _isUploading,
            isFullWidth: false,
            onPressed: _selectedImageBytes != null && !_isUploading
                ? _uploadLogo
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _uploadLogo() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final settingsService = ref.read(settingsGraphQLServiceProvider);
      final logoCacheService = ref.read(logoCacheServiceProvider);
      
      // 1. Solicitar URL de upload assinada via GraphQL
      final uploadResult = await settingsService.uploadAppLogo(
        imageBytes: _selectedImageBytes!,
        fileName: 'app_logo_${DateTime.now().millisecondsSinceEpoch}.png',
        contentType: 'image/png',
      );

      if (!uploadResult.success) {
        throw Exception(uploadResult.error ?? 'Erro ao solicitar upload');
      }

      // 2. Fazer upload direto para MinIO se tiver uploadUrl
      if (uploadResult.uploadUrl != null && uploadResult.logoUrl != null) {
        // Upload direto para MinIO usando Dio
        final dio = Dio();
        final response = await dio.put(
          uploadResult.uploadUrl!,
          data: _selectedImageBytes!,
          options: Options(
            headers: {'Content-Type': 'image/png'},
          ),
        );
        
        if (response.statusCode! < 200 || response.statusCode! >= 300) {
          throw Exception('Erro no upload para MinIO: ${response.statusCode}');
        }
        
        // 3. Atualizar configurações do app com nova logo URL
        final updateResult = await settingsService.updateAppSettings(
          logoUrl: uploadResult.logoUrl,
        );
        
        if (!updateResult.success) {
          throw Exception(updateResult.error ?? 'Erro ao atualizar configurações');
        }
        
        // 4. Cache local da nova logo
        await logoCacheService.updateLogoCache(
          bytes: _selectedImageBytes!,
          originalFileName: 'app_logo.png',
          url: uploadResult.logoUrl,
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        _showSuccess('Logo atualizada com sucesso!');
      }
    } catch (e) {
      _showError('Erro ao atualizar logo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}