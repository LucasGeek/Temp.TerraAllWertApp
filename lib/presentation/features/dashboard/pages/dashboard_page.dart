import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../layout/design_system/app_theme.dart';
import '../../../layout/design_system/layout_constants.dart';
import '../../../providers/menu_provider.dart';
import '../widgets/organisms/create_menu_dialog.dart';
import '../widgets/organisms/dashboard_menus_grid.dart';
import '../widgets/organisms/empty_dashboard_state.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuProvider);

    // Carregar menus na primeira vez
    ref.listen(menuProvider, (previous, next) {
      if (previous?.status == MenuStatus.initial && next.status == MenuStatus.initial) {
        Future.microtask(() {
          ref.read(menuProvider.notifier).loadVisibleMenus();
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(LayoutConstants.paddingMd),
          child: _buildContent(context, ref, menuState),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMenuDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Criar Menu'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimary,
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, MenuState menuState) {
    switch (menuState.status) {
      case MenuStatus.initial:
        // Trigger loading on first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(menuProvider.notifier).loadVisibleMenus();
        });
        return const Center(child: CircularProgressIndicator());

      case MenuStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case MenuStatus.empty:
        return const EmptyDashboardState();

      case MenuStatus.error:
        return _buildErrorState(context, ref, menuState.error);

      case MenuStatus.loaded:
        return DashboardMenusGrid(menus: menuState.menus);
    }
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String? error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(LayoutConstants.paddingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar menus',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Ocorreu um erro inesperado',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(menuProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateMenuDialog(BuildContext context, WidgetRef ref) async {
    final result = await CreateMenuDialog.show(context);

    // Se foi criado com sucesso, recarregar os menus
    if (result == true) {
      ref.read(menuProvider.notifier).refresh();
    }
  }
}
