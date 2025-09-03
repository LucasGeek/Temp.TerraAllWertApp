import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/dashboard/widgets/organisms/main_navigation_drawer.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/notification/snackbar_notification.dart';
import '../../design_system/app_theme.dart';
import '../../responsive/breakpoints.dart';
import '../organisms/app_header.dart';
import '../organisms/responsive_sidebar.dart';

// class MainLayout extends ConsumerStatefulWidget {
//   final Widget child;
//   final String currentRoute;

//   const MainLayout({super.key, required this.child, required this.currentRoute});

//   @override
//   ConsumerState<MainLayout> createState() => _MainLayoutState();
// }

// class _MainLayoutState extends ConsumerState<MainLayout> {
//   @override
//   Widget build(BuildContext context) {
//     try {
//       final userAsyncValue = ref.watch(authControllerProvider);

//       return _buildScaffold(userAsyncValue);
//     } catch (e) {
//       AppLogger.error('MainLayout: Critical error building layout', error: e);
//       return _buildFallbackLayout();
//     }
//   }

//   Widget _buildScaffold(AsyncValue userAsyncValue) {
//     final isMobile = context.isMobile || (context.isTablet && context.isXs);

//     return Scaffold(
//       appBar: isMobile ? _buildAppBar() : null,
//       body: _buildMainBody(userAsyncValue, isMobile),
//       drawer: isMobile ? _buildMobileDrawer(userAsyncValue) : null,
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppHeader(showMenuButton: true, currentRoute: widget.currentRoute);
//   }

//   Widget _buildMainBody(AsyncValue userAsyncValue, bool isMobile) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [_buildSidebarContainer(userAsyncValue), _buildMainContent(isMobile)],
//     );
//   }

//   Widget _buildSidebarContainer(AsyncValue userAsyncValue) {
//     return ResponsiveSidebar(
//       currentRoute: widget.currentRoute,
//       user: userAsyncValue.value,
//       isLoading: userAsyncValue.isLoading,
//       onLogoutTap: () => _handleLogout(context),
//     );
//   }

//   Widget _buildMainContent(bool isMobile) {
//     return Expanded(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (!isMobile) _buildAppBar(),
//           Expanded(child: widget.child),
//         ],
//       ),
//     );
//   }

//   Widget _buildMobileDrawer(AsyncValue userAsyncValue) {
//     return MainNavigationDrawer(
//       currentRoute: widget.currentRoute,
//       user: userAsyncValue.value,
//       isLoading: userAsyncValue.isLoading,
//       onLogoutTap: () => _handleLogout(context),
//     );
//   }

//   Widget _buildFallbackLayout() {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Terra Allwert'),
//         backgroundColor: AppTheme.surfaceColor,
//         foregroundColor: AppTheme.onSurface,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
//             const SizedBox(height: 16),
//             const Text(
//               'Erro ao carregar layout',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Tente recarregar a página',
//               style: TextStyle(fontSize: 14, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _handleLogout(BuildContext context) async {
//     try {
//       AppLogger.info('User initiated logout from main layout');

//       // Validação de contexto antes de executar logout
//       if (!context.mounted) {
//         AppLogger.warning('Context not mounted during logout attempt');
//         return;
//       }

//       await ref.read(authControllerProvider.notifier).logout();

//       SnackbarNotification.showSuccess('Logout realizado com sucesso!');

//       if (context.mounted) {
//         context.go('/login');
//         AppLogger.info('Successfully navigated to login after logout');
//       }
//     } catch (error) {
//       AppLogger.error('Logout failed from main layout', error: error);

//       if (context.mounted) {
//         SnackbarNotification.showError('Erro ao fazer logout');
//       }
//     }
//   }
// }

/// Template principal do layout da aplicação
/// Implementa atomic design com validação e prevenção de erros
class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({super.key, required this.child, required this.currentRoute});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  Widget build(BuildContext context) {
    try {
      final authState = ref.watch(authProvider);

      return _buildScaffold(authState);
    } catch (e) {
      debugPrint('MainLayout: Critical error building layout - $e');
      return _buildFallbackLayout();
    }
  }

  Widget _buildScaffold(AuthState authState) {
    final isMobile = context.isMobile || (context.isTablet && context.isXs);

    return Scaffold(
      appBar: isMobile ? _buildAppBar() : null,
      body: _buildMainBody(authState, isMobile),
      drawer: isMobile ? _buildMobileDrawer(authState) : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppHeader(showMenuButton: true, currentRoute: widget.currentRoute);
  }

  Widget _buildMainBody(AuthState authState, bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_buildSidebarContainer(authState), _buildMainContent(isMobile)],
    );
  }

  Widget _buildSidebarContainer(AuthState authState) {
    return ResponsiveSidebar(
      currentRoute: widget.currentRoute,
      user: authState.user,
      isLoading: authState.isLoading,
      onLogoutTap: () => _handleLogout(context),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMobile) _buildAppBar(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(AuthState authState) {
    return MainNavigationDrawer(
      currentRoute: widget.currentRoute,
      user: authState.user,
      isLoading: authState.isLoading,
      onLogoutTap: () => _handleLogout(context),
    );
  }

  Widget _buildFallbackLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terra Allwert'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.onSurface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar layout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tente recarregar a página',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    try {
      debugPrint('User initiated logout from main layout');

      // Validação de contexto antes de executar logout
      if (!context.mounted) {
        debugPrint('Context not mounted during logout attempt');
        return;
      }

      await ref.read(authProvider.notifier).logout();

      SnackbarNotification.showSuccess('Logout realizado com sucesso!');

      if (context.mounted) {
        context.go('/login');
        debugPrint('Successfully navigated to login after logout');
      }
    } catch (error) {
      debugPrint('Logout failed from main layout: $error');

      if (context.mounted) {
        SnackbarNotification.showError('Erro ao fazer logout');
      }
    }
  }
}
