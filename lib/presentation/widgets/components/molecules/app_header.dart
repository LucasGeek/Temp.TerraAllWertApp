import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';
import '../atoms/app_logo.dart';
import '../atoms/responsive_text.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final bool showLogo;
  final double? height;
  
  const AppHeader({
    super.key,
    required this.title,
    this.showLogo = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final headerHeight = height ?? LayoutConstants.drawerHeaderHeight;
    
    return Container(
      height: headerHeight,
      padding: EdgeInsets.all(context.responsive<double>(
        xs: LayoutConstants.paddingMd,
        md: LayoutConstants.paddingMd,
        lg: LayoutConstants.paddingLg,
      )),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
      ),
      child: Row(
        children: [
          if (showLogo) ...[
            const AppLogo(),
            SizedBox(width: LayoutConstants.marginSm),
          ],
          Expanded(
            child: ResponsiveText.title(
              title,
              color: AppTheme.onPrimary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}