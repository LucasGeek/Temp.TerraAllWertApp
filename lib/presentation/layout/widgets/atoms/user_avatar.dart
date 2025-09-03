import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';

/// Atom: Avatar de usuário seguindo SOLID principles
/// Single Responsibility: Apenas renderizar avatar
/// Open/Closed: Extensível via factory methods e variantes
class AppAvatar extends StatelessWidget {
  final double? radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? imageUrl;
  final String? initials;
  final AvatarVariant variant;
  final VoidCallback? onTap;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const AppAvatar({
    super.key,
    this.radius,
    this.backgroundColor,
    this.iconColor,
    this.imageUrl,
    this.initials,
    this.variant = AvatarVariant.standard,
    this.onTap,
    this.placeholder,
    this.errorWidget,
  });

  /// Factory para avatar pequeno
  factory AppAvatar.small({
    Key? key,
    String? imageUrl,
    String? initials,
    VoidCallback? onTap,
  }) => AppAvatar(
    key: key,
    radius: LayoutConstants.avatarSmall,
    imageUrl: imageUrl,
    initials: initials,
    variant: AvatarVariant.small,
    onTap: onTap,
  );

  /// Factory para avatar médio
  factory AppAvatar.medium({
    Key? key,
    String? imageUrl,
    String? initials,
    VoidCallback? onTap,
  }) => AppAvatar(
    key: key,
    radius: LayoutConstants.avatarMedium,
    imageUrl: imageUrl,
    initials: initials,
    variant: AvatarVariant.medium,
    onTap: onTap,
  );

  /// Factory para avatar grande
  factory AppAvatar.large({
    Key? key,
    String? imageUrl,
    String? initials,
    VoidCallback? onTap,
  }) => AppAvatar(
    key: key,
    radius: LayoutConstants.avatarLarge,
    imageUrl: imageUrl,
    initials: initials,
    variant: AvatarVariant.large,
    onTap: onTap,
  );

  /// Factory para avatar responsivo
  factory AppAvatar.responsive({
    Key? key,
    String? imageUrl,
    String? initials,
    VoidCallback? onTap,
  }) => AppAvatar(
    key: key,
    imageUrl: imageUrl,
    initials: initials,
    variant: AvatarVariant.responsive,
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = _getEffectiveRadius(context);
    
    Widget avatar = CircleAvatar(
      radius: effectiveRadius,
      backgroundColor: backgroundColor ?? _getDefaultBackgroundColor(),
      child: _buildAvatarContent(context, effectiveRadius),
    );
    
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }
    
    return avatar;
  }
  
  double _getEffectiveRadius(BuildContext context) {
    if (radius != null) return radius!;
    
    switch (variant) {
      case AvatarVariant.small:
        return LayoutConstants.avatarSmall;
      case AvatarVariant.medium:
        return LayoutConstants.avatarMedium;
      case AvatarVariant.large:
        return LayoutConstants.avatarLarge;
      case AvatarVariant.responsive:
        return context.responsive<double>(
          xs: LayoutConstants.avatarSmall,
          sm: LayoutConstants.avatarMedium,
          md: LayoutConstants.avatarLarge,
          lg: LayoutConstants.avatarXLarge,
        );
      case AvatarVariant.standard:
        return LayoutConstants.avatarMedium;
    }
  }
  
  Color _getDefaultBackgroundColor() {
    return AppTheme.surfaceColor;
  }
  
  Widget _buildAvatarContent(BuildContext context, double effectiveRadius) {
    // Se temos uma imagem, usar CachedNetworkImage
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: effectiveRadius * 2,
            height: effectiveRadius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => placeholder ?? _buildPlaceholder(effectiveRadius),
            errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(effectiveRadius),
          ),
        );
      } else {
        // Para imagens locais
        return ClipRRect(
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: Image.asset(
            imageUrl!,
            width: effectiveRadius * 2,
            height: effectiveRadius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => 
                errorWidget ?? _buildErrorWidget(effectiveRadius),
          ),
        );
      }
    }
    
    // Se temos iniciais, mostrar elas
    if (initials != null && initials!.isNotEmpty) {
      return Text(
        initials!.toUpperCase(),
        style: TextStyle(
          color: iconColor ?? AppTheme.onSurface,
          fontSize: effectiveRadius * 0.6,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    
    // Fallback para ícone
    return Icon(
      Icons.person,
      color: iconColor ?? AppTheme.onSurface,
      size: effectiveRadius * 1.2,
    );
  }
  
  Widget _buildPlaceholder(double effectiveRadius) {
    return Container(
      width: effectiveRadius * 2,
      height: effectiveRadius * 2,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: effectiveRadius * 0.6,
          height: effectiveRadius * 0.6,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget(double effectiveRadius) {
    return Icon(
      Icons.person,
      color: AppTheme.textHint,
      size: effectiveRadius * 1.2,
    );
  }
}

/// Enum para variantes do avatar - Open/Closed Principle
enum AvatarVariant {
  standard,
  small,
  medium,
  large,
  responsive,
}

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppAvatar ao invés de UserAvatar')
typedef UserAvatar = AppAvatar;