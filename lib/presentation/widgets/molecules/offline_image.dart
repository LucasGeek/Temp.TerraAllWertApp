import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../../infra/platform/platform_service.dart';
import '../../../infra/cache/media_cache_service.dart';
import '../../../infra/network/connectivity_service.dart';
import '../atoms/loading_indicator.dart';

/// Widget inteligente para exibição de imagens com suporte offline
/// Funciona para mobile e desktop, com fallback para paths locais
/// Para web, usa cached_network_image normalmente
class OfflineImage extends ConsumerWidget {
  final String? networkUrl;
  final String? localPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enableCaching;
  
  const OfflineImage({
    super.key,
    this.networkUrl,
    this.localPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enableCaching = true,
  }) : assert(networkUrl != null || localPath != null, 'Either networkUrl or localPath must be provided');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Para web, usa cached_network_image padrão
    if (PlatformService.isWeb) {
      return _buildWebImage(context);
    }
    
    // Para mobile/desktop, usa lógica offline-aware
    return _buildOfflineAwareImage(context, ref);
  }
  
  /// Build para plataforma web
  Widget _buildWebImage(BuildContext context) {
    if (networkUrl != null) {
      return _buildCachedNetworkImage(context);
    } else if (localPath != null) {
      // Para web, local path não funciona, mostra erro
      return _buildErrorWidget(context);
    } else {
      return _buildErrorWidget(context);
    }
  }
  
  /// Build para plataformas mobile/desktop com suporte offline
  Widget _buildOfflineAwareImage(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    // MediaCacheService usado nos métodos filhos
    
    return isOnlineAsync.when(
      data: (isOnline) => _buildImageWithConnectivityStatus(context, ref, isOnline),
      loading: () => _buildPlaceholder(context),
      error: (_, _) => _buildImageWithConnectivityStatus(context, ref, false), // Assume offline em caso de erro
    );
  }
  
  /// Build baseado no status de conectividade
  Widget _buildImageWithConnectivityStatus(BuildContext context, WidgetRef ref, bool isOnline) {
    final mediaCacheService = ref.watch(mediaCacheServiceProvider);
    
    // Prioridade: 1. Cache local, 2. Network (se online), 3. Local path, 4. Error
    
    // 1. Verifica cache local primeiro (se network URL disponível)
    if (networkUrl != null && enableCaching) {
      return FutureBuilder<File?>(
        future: mediaCacheService.getCachedFile(networkUrl!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildPlaceholder(context);
          }
          
          final cachedFile = snapshot.data;
          
          // Se tem arquivo cached, usa ele
          if (cachedFile != null) {
            return _buildFileImage(context, cachedFile);
          }
          
          // Se online e não tem cache, tenta baixar e cachear
          if (isOnline && networkUrl != null) {
            return _buildNetworkImageWithCaching(context, ref);
          }
          
          // Se offline e não tem cache, usa path local se disponível
          if (localPath != null) {
            return _buildLocalPathImage(context);
          }
          
          // Nenhuma opção disponível
          return _buildErrorWidget(context);
        },
      );
    }
    
    // 2. Se online e não usa cache, tenta network URL
    if (isOnline && networkUrl != null) {
      return _buildCachedNetworkImage(context);
    }
    
    // 3. Se offline ou sem network URL, usa path local
    if (localPath != null) {
      return _buildLocalPathImage(context);
    }
    
    // 4. Nenhuma opção disponível
    return _buildErrorWidget(context);
  }
  
  /// Build com network image e caching
  Widget _buildNetworkImageWithCaching(BuildContext context, WidgetRef ref) {
    final mediaCacheService = ref.watch(mediaCacheServiceProvider);
    
    return FutureBuilder<File?>(
      future: mediaCacheService.cacheImage(networkUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostra cached_network_image enquanto baixa para cache local
          return _buildCachedNetworkImage(context);
        }
        
        final cachedFile = snapshot.data;
        
        // Se conseguiu cachear, usa arquivo local
        if (cachedFile != null) {
          return _buildFileImage(context, cachedFile);
        }
        
        // Se não conseguiu cachear, tenta cached_network_image
        return _buildCachedNetworkImage(context);
      },
    );
  }
  
  /// Build com cached_network_image
  Widget _buildCachedNetworkImage(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: networkUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildErrorWidget(context),
      ),
    );
  }
  
  /// Build com arquivo local
  Widget _buildFileImage(BuildContext context, File file) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
      ),
    );
  }
  
  /// Build com path local
  Widget _buildLocalPathImage(BuildContext context) {
    if (localPath == null || localPath!.isEmpty) {
      return _buildErrorWidget(context);
    }
    
    final file = File(localPath!);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(context);
        }
        
        if (snapshot.data == true) {
          return _buildFileImage(context, file);
        } else {
          return _buildErrorWidget(context);
        }
      },
    );
  }
  
  /// Build placeholder
  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) {
      return placeholder!;
    }
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: AppLoadingIndicator(),
      ),
    );
  }
  
  /// Build error widget
  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) {
      return errorWidget!;
    }
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_not_supported,
        size: LayoutConstants.iconLarge,
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }
}

/// Factory methods para casos comuns
extension OfflineImageFactory on OfflineImage {
  /// Imagem com bordas arredondadas
  static Widget rounded({
    String? networkUrl,
    String? localPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double radius = 8.0,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableCaching = true,
  }) {
    return OfflineImage(
      networkUrl: networkUrl,
      localPath: localPath,
      width: width,
      height: height,
      fit: fit,
      borderRadius: BorderRadius.circular(radius),
      placeholder: placeholder,
      errorWidget: errorWidget,
      enableCaching: enableCaching,
    );
  }
  
  /// Imagem circular
  static Widget circular({
    String? networkUrl,
    String? localPath,
    double size = 50.0,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableCaching = true,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: OfflineImage(
        networkUrl: networkUrl,
        localPath: localPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: placeholder,
        errorWidget: errorWidget,
        enableCaching: enableCaching,
      ),
    );
  }
  
  /// Thumbnail pequeno
  static Widget thumbnail({
    String? networkUrl,
    String? localPath,
    double size = 100.0,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableCaching = true,
  }) {
    return OfflineImageFactory.rounded(
      networkUrl: networkUrl,
      localPath: localPath,
      width: size,
      height: size,
      radius: LayoutConstants.radiusSmall,
      placeholder: placeholder,
      errorWidget: errorWidget,
      enableCaching: enableCaching,
    );
  }
}