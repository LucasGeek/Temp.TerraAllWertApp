import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';
import 'navigation_sidebar.dart';
import '../../../../domain/entities/user.dart';
import '../../../providers/sidebar_provider.dart';

/// Container responsivo para sidebar com animações otimizadas
/// Implementa atomic design com controle de estado e prevenção de erros
class ResponsiveSidebar extends ConsumerWidget {
  final String currentRoute;
  final User? user;
  final bool isLoading;
  final VoidCallback onLogoutTap;

  const ResponsiveSidebar({
    super.key,
    required this.currentRoute,
    required this.user,
    this.isLoading = false,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final isMobile = context.isMobile || (context.isTablet && context.isXs);

      if (isMobile) {
        return const SizedBox.shrink();
      }

      final isExpanded = ref.watch(sidebarNotifierProvider);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Otimizado: mais suave e rápido
        curve: Curves.easeInOutCubic, // Curva mais suave
        width: isExpanded ? LayoutConstants.sidebarWidth : 0,
        child: isExpanded ? _buildSidebar() : null,
      );
    } catch (e) {
      debugPrint('ResponsiveSidebar: Error building sidebar - $e');
      return _buildFallbackSidebar();
    }
  }

  Widget _buildSidebar() {
    return NavigationSidebar(
      currentRoute: currentRoute,
      user: user,
      isLoading: isLoading,
      onLogoutTap: onLogoutTap,
    );
  }

  Widget _buildFallbackSidebar() {
    return Container(
      width: LayoutConstants.sidebarWidth,
      decoration: const BoxDecoration(color: Colors.grey),
      child: const Center(
        child: Text('Erro ao carregar sidebar', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
