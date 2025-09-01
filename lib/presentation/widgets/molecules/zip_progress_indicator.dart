import 'package:flutter/material.dart';

import '../../../infra/sync/zip_manager.dart';

/// Widget que mostra o progresso de download e extração de ZIP
class ZipProgressIndicator extends StatelessWidget {
  final Stream<ZipProgress> progressStream;
  final VoidCallback? onCancel;
  final bool showDetails;
  final Color? primaryColor;

  const ZipProgressIndicator({
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

    return StreamBuilder<ZipProgress>(
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
                // Header com fase atual e botão cancelar
                Row(
                  children: [
                    Icon(
                      _getPhaseIcon(progress.phase),
                      color: _getPhaseColor(progress.phase),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getPhaseText(progress.phase),
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onCancel != null && 
                        progress.phase != 'completed' && 
                        progress.phase != 'error')
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        onPressed: onCancel,
                        tooltip: 'Cancelar operação',
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
                      if (progress.processedFiles != null && progress.totalFiles != null)
                        Text(
                          '${progress.processedFiles}/${progress.totalFiles} arquivos',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                  
                  // Arquivo sendo processado
                  if (progress.currentFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        progress.currentFile!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                
                // Mostrar mensagem de conclusão ou erro
                if (progress.phase == 'completed') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Download e extração concluídos com sucesso!',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (progress.phase == 'error' && progress.currentFile != null) ...[
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
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            progress.currentFile!,
                            style: const TextStyle(color: Colors.red),
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

  IconData _getPhaseIcon(String phase) {
    switch (phase) {
      case 'downloading':
        return Icons.file_download_outlined;
      case 'extracting':
        return Icons.folder_zip_outlined;
      case 'cleanup':
        return Icons.cleaning_services_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.pending_outlined;
    }
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'downloading':
        return Colors.blue;
      case 'extracting':
        return Colors.orange;
      case 'cleanup':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPhaseText(String phase) {
    switch (phase) {
      case 'downloading':
        return 'Baixando arquivo ZIP...';
      case 'extracting':
        return 'Extraindo arquivos...';
      case 'cleanup':
        return 'Limpando versões antigas...';
      case 'completed':
        return 'Operação concluída';
      case 'error':
        return 'Erro na operação';
      default:
        return 'Preparando...';
    }
  }
}

/// Widget compacto que mostra apenas uma barra de progresso para ZIP
class CompactZipIndicator extends StatelessWidget {
  final Stream<ZipProgress> progressStream;
  final Color? color;
  final double height;
  final bool showPhase;

  const CompactZipIndicator({
    super.key,
    required this.progressStream,
    this.color,
    this.height = 4.0,
    this.showPhase = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<ZipProgress>(
      stream: progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(height: height);
        }

        final progress = snapshot.data!;
        
        if (progress.phase == 'completed') {
          return SizedBox(height: height);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPhase)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  _getPhaseText(progress.phase),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: (color ?? theme.primaryColor).withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPhaseColor(progress.phase)
              ),
              minHeight: height,
            ),
          ],
        );
      },
    );
  }

  String _getPhaseText(String phase) {
    switch (phase) {
      case 'downloading':
        return 'Baixando...';
      case 'extracting':
        return 'Extraindo...';
      case 'cleanup':
        return 'Limpando...';
      case 'completed':
        return 'Concluído';
      case 'error':
        return 'Erro';
      default:
        return 'Preparando...';
    }
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'downloading':
        return Colors.blue;
      case 'extracting':
        return Colors.orange;
      case 'cleanup':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Widget para mostrar informações de uma versão ZIP
class ZipVersionCard extends StatelessWidget {
  final ZipVersion version;
  final bool isActive;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const ZipVersionCard({
    super.key,
    required this.version,
    this.isActive = false,
    this.onDownload,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: isActive ? theme.primaryColor.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com versão e status
            Row(
              children: [
                Icon(
                  Icons.folder_zip,
                  color: isActive ? theme.primaryColor : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Versão ${version.version}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? theme.primaryColor : null,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ATUAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Informações da versão
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${version.fileCount} arquivos',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        _formatFileSize(version.totalSize),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    'Baixado em:\n${_formatDate(version.downloadedAt)}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            
            // Ações
            if (onDownload != null || onDelete != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onDownload != null)
                    TextButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Redownload'),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Remover'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}