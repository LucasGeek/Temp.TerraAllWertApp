import 'dart:io';
import 'package:flutter/material.dart';

/// Widget para exibir imagens com suporte a cache offline
class OfflineImage extends StatelessWidget {
  final String? networkUrl;
  final String? localPath;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCaching;

  const OfflineImage({
    super.key,
    this.networkUrl,
    this.localPath,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableCaching = true,
  }) : assert(networkUrl != null || localPath != null, 'Either networkUrl or localPath must be provided');

  @override
  Widget build(BuildContext context) {
    // Se tem URL de rede, usar Image.network
    if (networkUrl != null) {
      return Image.network(
        networkUrl!,
        fit: fit,
        loadingBuilder: placeholder != null
            ? (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder!;
              }
            : null,
        errorBuilder: errorWidget != null
            ? (context, error, stackTrace) => errorWidget!
            : null,
      );
    }

    // Se tem caminho local, usar Image.file
    if (localPath != null) {
      try {
        return Image.file(
          File(localPath!),
          fit: fit,
          errorBuilder: errorWidget != null
              ? (context, error, stackTrace) => errorWidget!
              : null,
        );
      } catch (e) {
        return errorWidget ?? const Icon(Icons.error);
      }
    }

    // Fallback
    return errorWidget ?? const Icon(Icons.image_not_supported);
  }
}