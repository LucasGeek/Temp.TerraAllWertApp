import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dashboard/widgets/organisms/main_navigation_drawer.dart';
import '../../../providers/sidebar_provider.dart';
import '../../responsive/breakpoints.dart';
import '../organisms/responsive_sidebar.dart';
import '../organisms/standard_app_bar.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return _buildScaffold();
  }

  /// Constrói o Scaffold principal
  Widget _buildScaffold() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: !context.isDesktop ? _buildAppBar() : null,
      drawer: !context.isDesktop
          ? MainNavigationDrawer(
              currentRoute: widget.currentRoute,
              user: null, // TODO: implementar usuário logado
              onLogoutTap: () {}, // TODO: implementar logout
            )
          : null,
      body: context.isDesktop
          ? Row(
              children: [
                ResponsiveSidebar(
                  currentRoute: widget.currentRoute,
                  user: null, // TODO: implementar usuário logado
                  onLogoutTap: () {}, // TODO: implementar logout
                ),
                Expanded(
                  child: Column(
                    children: [
                      StandardAppBar(
                        title: _getPageTitle(widget.currentRoute),
                        showDrawerButton: false,
                        automaticallyImplyLeading: false,
                        leading: _buildSidebarToggle(),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              // TODO: Implementar busca
                            },
                            tooltip: 'Buscar',
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            )
          : widget.child,
    );
  }

  /// Constrói o AppBar para mobile
  PreferredSizeWidget _buildAppBar() {
    final isDrawerOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;

    return AppBar(
      title: Text(_getPageTitle(widget.currentRoute)),
      leading: IconButton(
        icon: Icon(isDrawerOpen ? Icons.close : Icons.menu),
        onPressed: () {
          if (isDrawerOpen) {
            Navigator.of(context).pop();
          } else {
            _scaffoldKey.currentState?.openDrawer();
          }
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: Implementar busca
          },
          tooltip: 'Buscar',
          splashRadius: 20,
        ),
      ],
    );
  }

  /// Constrói o botão de toggle para desktop sidebar
  Widget _buildSidebarToggle() {
    final isExpanded = ref.watch(sidebarNotifierProvider);

    return IconButton(
      icon: Icon(
        isExpanded ? Icons.menu_open : Icons.menu,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () {
        ref.read(sidebarNotifierProvider.notifier).toggle();
      },
      tooltip: isExpanded ? 'Fechar menu' : 'Abrir menu',
      splashRadius: 20,
    );
  }

  /// Determina o título da página baseado na rota
  String _getPageTitle(String route) {
    switch (route) {
      case '/dashboard':
        return 'Dashboard';
      case '/login':
        return 'Login';
      default:
        return 'Terra Allwert';
    }
  }
}
