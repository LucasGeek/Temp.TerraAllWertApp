import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';

class UserAvatar extends StatelessWidget {
  final double? radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? imageUrl;
  
  const UserAvatar({
    super.key,
    this.radius,
    this.backgroundColor,
    this.iconColor,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final avatarRadius = radius ?? context.responsive<double>(
      xs: LayoutConstants.avatarSmall,
      sm: LayoutConstants.avatarMedium,
      md: LayoutConstants.avatarLarge,
    );
    
    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: backgroundColor ?? Colors.white,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Icon(
              Icons.person,
              color: iconColor ?? AppTheme.primaryColor,
              size: context.responsive<double>(
                xs: LayoutConstants.iconMedium,
                sm: LayoutConstants.iconLarge,
                md: LayoutConstants.iconXLarge,
              ),
            )
          : null,
    );
  }
}