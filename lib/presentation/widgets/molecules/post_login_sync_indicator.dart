import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../providers/post_login_sync_provider.dart';

/// Indicador de sincronização pós-login
/// Mostra progresso da sincronização inicial após login
class PostLoginSyncIndicator extends ConsumerWidget {
  final bool showAsOverlay;
  final bool showDetails;

  const PostLoginSyncIndicator({
    super.key,
    this.showAsOverlay = false,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowSyncIndicatorProvider);
    final progress = ref.watch(syncProgressProvider);
    final error = ref.watch(syncErrorProvider);

    if (!shouldShow && error == null) {
      return const SizedBox.shrink();
    }

    if (showAsOverlay) {
      return _buildOverlay(context, progress, error);
    } else {
      return _buildInline(context, progress, error);
    }
  }

  Widget _buildOverlay(BuildContext context, SyncProgress progress, String? error) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: EdgeInsets.all(LayoutConstants.marginLg),
          child: Padding(
            padding: EdgeInsets.all(LayoutConstants.marginLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null) ...[
                  Icon(
                    Icons.warning,
                    size: 48,
                    color: AppTheme.errorColor,
                  ),
                  SizedBox(height: LayoutConstants.marginMd),
                  Text(
                    'Erro na Sincronização',
                    style: TextStyle(
                      fontSize: LayoutConstants.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  SizedBox(height: LayoutConstants.marginSm),
                  Text(
                    'Alguns dados podem não estar atualizados.',
                    style: TextStyle(
                      fontSize: LayoutConstants.fontSizeMedium,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: progress.overallProgress,
                      strokeWidth: 4,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: LayoutConstants.marginMd),
                  Text(
                    'Sincronizando...',
                    style: TextStyle(
                      fontSize: LayoutConstants.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: LayoutConstants.marginSm),
                  Text(
                    progress.message,
                    style: TextStyle(
                      fontSize: LayoutConstants.fontSizeMedium,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (showDetails) ...[
                    SizedBox(height: LayoutConstants.marginMd),
                    _buildProgressDetails(progress),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInline(BuildContext context, SyncProgress progress, String? error) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.marginMd),
      decoration: BoxDecoration(
        color: error != null ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
        border: Border.all(
          color: error != null ? AppTheme.errorColor.withValues(alpha: 0.3) : AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (error != null) ...[
            Icon(
              Icons.warning,
              size: 24,
              color: AppTheme.errorColor,
            ),
          ] else ...[
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: progress.overallProgress,
                strokeWidth: 3,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
          SizedBox(width: LayoutConstants.marginMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error != null ? 'Erro na sincronização' : 'Sincronizando dados...',
                  style: TextStyle(
                    fontSize: LayoutConstants.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: error != null ? AppTheme.errorColor : AppTheme.textPrimary,
                  ),
                ),
                if (error == null) ...[
                  SizedBox(height: LayoutConstants.marginXs),
                  Text(
                    progress.message,
                    style: TextStyle(
                      fontSize: LayoutConstants.fontSizeSmall,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (showDetails) ...[
                    SizedBox(height: LayoutConstants.marginXs),
                    _buildProgressBar(progress),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDetails(SyncProgress progress) {
    return Column(
      children: [
        Text(
          'Passo ${progress.currentStepNumber} de ${progress.totalSteps}',
          style: TextStyle(
            fontSize: LayoutConstants.fontSizeSmall,
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: LayoutConstants.marginSm),
        _buildProgressBar(progress),
      ],
    );
  }

  Widget _buildProgressBar(SyncProgress progress) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress.overallProgress,
          backgroundColor: AppTheme.surfaceColor,
          color: AppTheme.primaryColor,
        ),
        SizedBox(height: LayoutConstants.marginXs),
        Text(
          '${(progress.overallProgress * 100).toInt()}%',
          style: TextStyle(
            fontSize: LayoutConstants.fontSizeSmall,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Indicador compacto para usar em AppBar ou status bar
class CompactSyncIndicator extends ConsumerWidget {
  const CompactSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowSyncIndicatorProvider);
    final progress = ref.watch(syncProgressProvider);
    final error = ref.watch(syncErrorProvider);

    if (!shouldShow && error == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutConstants.marginSm,
        vertical: LayoutConstants.marginXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null) ...[
            Icon(
              Icons.warning,
              size: 16,
              color: AppTheme.errorColor,
            ),
            SizedBox(width: LayoutConstants.marginXs),
            Text(
              'Erro sync',
              style: TextStyle(
                fontSize: LayoutConstants.fontSizeSmall,
                color: AppTheme.errorColor,
              ),
            ),
          ] else ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                value: progress.overallProgress,
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: LayoutConstants.marginXs),
            Text(
              'Sync...',
              style: TextStyle(
                fontSize: LayoutConstants.fontSizeSmall,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget para mostrar resultado final da sincronização
class SyncResultSnackbar extends ConsumerWidget {
  const SyncResultSnackbar({super.key});

  static void show(BuildContext context, WidgetRef ref) {
    final result = ref.read(syncResultProvider);
    
    if (result == null) return;

    final message = result.success 
        ? 'Sincronização concluída com sucesso'
        : 'Sincronização falhou: ${result.error ?? "Erro desconhecido"}';

    final icon = result.success 
        ? Icons.check_circle 
        : Icons.error;

    final color = result.success 
        ? AppTheme.successColor 
        : AppTheme.errorColor;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: LayoutConstants.marginSm),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: result.success ? 2 : 4),
        backgroundColor: color.withValues(alpha: 0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink(); // Este widget só existe para o método static
  }
}