import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';

/// Header de navegação padronizado para drawer e sidebar
/// Usado em todos os dispositivos (mobile, tablet, desktop)
class NavigationHeader extends StatelessWidget {
  const NavigationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(color: AppTheme.primaryColor),
      child: Row(
        children: [
          _buildLogo(),
          SizedBox(width: LayoutConstants.marginSm),
          _buildTitle(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: LayoutConstants.iconXLarge,
      height: LayoutConstants.iconXLarge,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Icon(
        Icons.home_work,
        color: AppTheme.primaryColor,
        size: LayoutConstants.iconLarge,
      ),
    );
  }

  Widget _buildTitle() {
    return const Expanded(
      child: Text(
        'Terra Allwert',
        style: TextStyle(color: AppTheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
