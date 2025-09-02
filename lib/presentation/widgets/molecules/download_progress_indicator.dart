import 'package:flutter/material.dart';

import '../../../infra/downloads/background_download_service.dart';

/// Widget que mostra o progresso de download em tempo real
class DownloadProgressIndicator extends StatelessWidget {
  final Stream<DownloadProgress> progressStream;
  final Stream<DownloadStatus>? statusStream;
  final VoidCallback? onCancel;
  final bool showDetails;
  final Color? primaryColor;

  const DownloadProgressIndicator({
    super.key,
    required this.progressStream,
    this.statusStream,
    this.onCancel,
    this.showDetails = true,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = primaryColor ?? theme.primaryColor;

    return StreamBuilder<DownloadProgress>(
      stream: progressStream,
      builder: (context, progressSnapshot) {
        if (!progressSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final progress = progressSnapshot.data!;
        
        return StreamBuilder<DownloadStatus?>(
          stream: statusStream,
          initialData: null,
          builder: (context, statusSnapshot) {
            final status = statusSnapshot.data ?? DownloadStatus.running;
            
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com título e botão cancelar
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getStatusText(status),
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onCancel != null && status == DownloadStatus.running)
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined),
                            onPressed: onCancel,
                            tooltip: 'Cancelar download',
                            iconSize: 20,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Barra de progresso
                    LinearProgressIndicator(
                      value: progress.progress,
                      backgroundColor: color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    
                    if (showDetails) ...[
                      const SizedBox(height: 8),
                      
                      // Detalhes do progresso
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            progress.formattedProgress,
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            progress.formattedFileSize,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      
                      if (progress.networkSpeed > 0 && progress.timeRemaining != Duration.zero)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                progress.formattedNetworkSpeed,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                'ETA: ${progress.formattedTimeRemaining}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    
                    // Mostrar erro se status for failed
                    if (status == DownloadStatus.failed) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Falha no download',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.enqueued:
        return Icons.pending_outlined;
      case DownloadStatus.running:
        return Icons.file_download_outlined;
      case DownloadStatus.completed:
        return Icons.check_circle_outline;
      case DownloadStatus.failed:
        return Icons.error_outline;
      case DownloadStatus.cancelled:
        return Icons.cancel_outlined;
      case DownloadStatus.paused:
        return Icons.pause_circle_outline;
      case DownloadStatus.retrying:
        return Icons.refresh_outlined;
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.enqueued:
        return Colors.orange;
      case DownloadStatus.running:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.cancelled:
        return Colors.grey;
      case DownloadStatus.paused:
        return Colors.amber;
      case DownloadStatus.retrying:
        return Colors.orange;
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.enqueued:
        return 'Preparando download...';
      case DownloadStatus.running:
        return 'Baixando arquivo...';
      case DownloadStatus.completed:
        return 'Download concluído';
      case DownloadStatus.failed:
        return 'Falha no download';
      case DownloadStatus.cancelled:
        return 'Download cancelado';
      case DownloadStatus.paused:
        return 'Download pausado';
      case DownloadStatus.retrying:
        return 'Tentando novamente...';
    }
  }
}

/// Widget compacto que mostra apenas uma barra de progresso simples
class CompactDownloadIndicator extends StatelessWidget {
  final Stream<DownloadProgress> progressStream;
  final Color? color;
  final double height;

  const CompactDownloadIndicator({
    super.key,
    required this.progressStream,
    this.color,
    this.height = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<DownloadProgress>(
      stream: progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(height: height);
        }

        final progress = snapshot.data!;
        
        // Assumir que se progress >= 1, está completo
        if (progress.progress >= 1.0) {
          return SizedBox(height: height);
        }

        return LinearProgressIndicator(
          value: progress.progress,
          backgroundColor: (color ?? theme.primaryColor).withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? theme.primaryColor
          ),
          minHeight: height,
        );
      },
    );
  }
}