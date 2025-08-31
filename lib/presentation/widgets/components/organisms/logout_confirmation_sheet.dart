import 'package:flutter/material.dart';

import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';

/// Bottom sheet responsivo para confirmação de logout
/// Mobile: tamanho normal, Tablet/Desktop: tamanho limitado
class LogoutConfirmationSheet extends StatelessWidget {
  final VoidCallback onConfirmLogout;
  
  const LogoutConfirmationSheet({
    super.key,
    required this.onConfirmLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile || (context.isTablet && context.isXs);
    
    if (isMobile) {
      return _buildMobileBottomSheet(context);
    } else {
      return _buildConstrainedBottomSheet(context);
    }
  }

  /// Bottom sheet para mobile (tamanho normal)
  Widget _buildMobileBottomSheet(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(LayoutConstants.paddingXl),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(LayoutConstants.radiusLarge),
          topRight: Radius.circular(LayoutConstants.radiusLarge),
        ),
      ),
      child: _buildContent(context, isMobile: true),
    );
  }

  /// Bottom sheet para tablet/desktop (tamanho limitado)
  Widget _buildConstrainedBottomSheet(BuildContext context) {
    return Center(
      child: Container(
        width: context.responsive<double>(
          xs: 340,
          md: 400,
          lg: 450,
          xl: 500,
        ),
        margin: EdgeInsets.all(LayoutConstants.marginXl),
        padding: EdgeInsets.all(LayoutConstants.paddingXl),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: LayoutConstants.shadowBlurLarge,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildContent(context, isMobile: false),
      ),
    );
  }

  /// Conteúdo comum do bottom sheet
  Widget _buildContent(BuildContext context, {required bool isMobile}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicador visual (apenas mobile)
        if (isMobile) _buildHandle(),
        if (isMobile) SizedBox(height: LayoutConstants.marginMd),
        
        // Ícone de aviso
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.logout,
            color: AppTheme.warningColor,
            size: 32,
          ),
        ),
        
        SizedBox(height: LayoutConstants.marginLg),
        
        // Título
        const Text(
          'Confirmar Logout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        
        SizedBox(height: LayoutConstants.marginSm),
        
        // Descrição
        const Text(
          'Tem certeza que deseja sair do aplicativo?',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: LayoutConstants.marginXl),
        
        // Botões
        Row(
          children: [
            // Botão Cancelar
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.all(LayoutConstants.paddingMd),
                  side: const BorderSide(color: AppTheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ),
            
            SizedBox(width: LayoutConstants.marginMd),
            
            // Botão Confirmar
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirmLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  padding: EdgeInsets.all(LayoutConstants.paddingMd),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                  ),
                ),
                child: const Text(
                  'Sair',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Espaçamento adicional para mobile
        if (isMobile) SizedBox(height: LayoutConstants.marginLg),
      ],
    );
  }

  /// Handle visual para indicar que é um bottom sheet (apenas mobile)
  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.outline,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Método estático para mostrar o bottom sheet
  static void show(BuildContext context, {required VoidCallback onConfirmLogout}) {
    final isMobile = context.isMobile || (context.isTablet && context.isXs);
    
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => LogoutConfirmationSheet(onConfirmLogout: onConfirmLogout),
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (context) => LogoutConfirmationSheet(onConfirmLogout: onConfirmLogout),
      );
    }
  }
}