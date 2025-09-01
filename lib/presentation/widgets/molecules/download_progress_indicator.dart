import 'package:flutter/material.dart';

import '../../../infra/download/background_downloader.dart';

/// Widget que mostra o progresso de download em tempo real
class DownloadProgressIndicator extends StatelessWidget {
  final Stream<DownloadProgress> progressStream;
  final VoidCallback? onCancel;
  final bool showDetails;
  final Color? primaryColor;

  const DownloadProgressIndicator({
    super.key,
    required this.progressStream,
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
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final progress = snapshot.data!;
        
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
                      _getStatusIcon(progress.status),
                      color: _getStatusColor(progress.status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getStatusText(progress.status),
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onCancel != null && progress.status == DownloadStatus.downloading)
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
                        '${(progress.progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        _formatBytes(progress.bytesDownloaded, progress.totalBytes),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  
                  if (progress.speed != null && progress.estimatedTimeLeft != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatSpeed(progress.speed!)}/s',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            'ETA: ${_formatDuration(progress.estimatedTimeLeft!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                
                // Mostrar erro se houver
                if (progress.error != null) ...[
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
                            progress.error!,
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
  }

  IconData _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return Icons.pending_outlined;
      case DownloadStatus.downloading:
        return Icons.file_download_outlined;
      case DownloadStatus.completed:
        return Icons.check_circle_outline;
      case DownloadStatus.failed:
        return Icons.error_outline;
      case DownloadStatus.cancelled:
        return Icons.cancel_outlined;
      case DownloadStatus.paused:
        return Icons.pause_circle_outline;
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return Colors.orange;
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.cancelled:
        return Colors.grey;
      case DownloadStatus.paused:
        return Colors.amber;
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return 'Preparando download...';
      case DownloadStatus.downloading:
        return 'Baixando arquivo...';
      case DownloadStatus.completed:
        return 'Download concluído';
      case DownloadStatus.failed:
        return 'Falha no download';
      case DownloadStatus.cancelled:
        return 'Download cancelado';
      case DownloadStatus.paused:
        return 'Download pausado';
    }
  }

  String _formatBytes(int current, int total) {
    if (total == 0) return '-- / --';
    
    return '${_formatFileSize(current)} / ${_formatFileSize(total)}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatSpeed(double bytesPerSecond) {
    return _formatFileSize(bytesPerSecond.round());
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h${duration.inMinutes.remainder(60)}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m${duration.inSeconds.remainder(60)}s';
    }
    return '${duration.inSeconds}s';
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
        
        if (progress.status == DownloadStatus.completed || 
            progress.status == DownloadStatus.cancelled) {
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