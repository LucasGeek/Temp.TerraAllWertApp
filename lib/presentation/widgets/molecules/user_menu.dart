import 'package:flutter/material.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';
import '../atoms/user_avatar.dart';
import '../atoms/responsive_text.dart';
import '../../../domain/entities/user.dart';

/// Molecule: Menu do usuário seguindo SOLID principles
/// Single Responsibility: Apenas renderizar menu do usuário
/// Open/Closed: Extensível via factory methods e itens customizáveis
/// Interface Segregation: Diferentes layouts para diferentes contextos
class AppUserMenu extends StatelessWidget {
  final User? user;
  final Map<String, UserMenuAction> actions;
  final UserMenuVariant variant;
  final Color? textColor;
  final Color? backgroundColor;
  final bool showUserName;
  final bool showDropdownIcon;
  final double? avatarRadius;
  final String? fallbackName;
  
  const AppUserMenu({
    super.key,
    required this.user,
    required this.actions,
    this.variant = UserMenuVariant.popup,
    this.textColor,
    this.backgroundColor,
    this.showUserName = true,
    this.showDropdownIcon = true,
    this.avatarRadius,
    this.fallbackName,
  });

  /// Factory para menu popup padrão
  factory AppUserMenu.popup({
    Key? key,
    required User? user,
    VoidCallback? onProfileTap,
    VoidCallback? onSettingsTap,
    VoidCallback? onLogoutTap,
    Color? textColor,
    bool showUserName = true,
    String? fallbackName,
  }) => AppUserMenu(
    key: key,
    user: user,
    actions: {
      'profile': UserMenuAction(
        label: 'Perfil',
        icon: Icons.person_outline,
        onTap: onProfileTap,
      ),
      'settings': UserMenuAction(
        label: 'Configurações',
        icon: Icons.settings_outlined,
        onTap: onSettingsTap,
      ),
      'logout': UserMenuAction(
        label: 'Sair',
        icon: Icons.logout,
        onTap: onLogoutTap,
        isDangerous: true,
      ),
    },
    variant: UserMenuVariant.popup,
    textColor: textColor,
    showUserName: showUserName,
    fallbackName: fallbackName,
  );

  /// Factory para menu em linha (drawer/sidebar)
  factory AppUserMenu.inline({
    Key? key,
    required User? user,
    required Map<String, UserMenuAction> actions,
    Color? textColor,
    Color? backgroundColor,
    double? avatarRadius,
  }) => AppUserMenu(
    key: key,
    user: user,
    actions: actions,
    variant: UserMenuVariant.inline,
    textColor: textColor,
    backgroundColor: backgroundColor,
    showUserName: false,
    showDropdownIcon: false,
    avatarRadius: avatarRadius,
  );

  /// Factory compacto (apenas avatar)
  factory AppUserMenu.compact({
    Key? key,
    required User? user,
    required Map<String, UserMenuAction> actions,
    double? avatarRadius,
  }) => AppUserMenu(
    key: key,
    user: user,
    actions: actions,
    variant: UserMenuVariant.compact,
    showUserName: false,
    showDropdownIcon: false,
    avatarRadius: avatarRadius,
  );

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case UserMenuVariant.popup:
        return _buildPopupMenu(context);
      case UserMenuVariant.inline:
        return _buildInlineMenu(context);
      case UserMenuVariant.compact:
        return _buildCompactMenu(context);
    }
  }
  
  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        final action = actions[value];
        action?.onTap?.call();
      },
      itemBuilder: (BuildContext context) {
        final menuItems = <PopupMenuEntry<String>>[];
        
        // Adicionar itens regulares
        final regularActions = actions.entries.where((entry) => !entry.value.isDangerous);
        for (final entry in regularActions) {
          menuItems.add(_buildPopupMenuItem(entry.key, entry.value));
        }
        
        // Adicionar divisor se houver itens perigosos
        final dangerousActions = actions.entries.where((entry) => entry.value.isDangerous);
        if (dangerousActions.isNotEmpty && regularActions.isNotEmpty) {
          menuItems.add(const PopupMenuDivider());
        }
        
        // Adicionar itens perigosos
        for (final entry in dangerousActions) {
          menuItems.add(_buildPopupMenuItem(entry.key, entry.value));
        }
        
        return menuItems;
      },
      child: _buildMenuTrigger(context),
    );
  }
  
  Widget _buildInlineMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUserInfo(context),
        const SizedBox(height: 8),
        ...actions.entries.map((entry) => _buildInlineMenuItem(
          context,
          entry.key,
          entry.value,
        )),
      ],
    );
  }
  
  Widget _buildCompactMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        final action = actions[value];
        action?.onTap?.call();
      },
      itemBuilder: (BuildContext context) {
        return actions.entries.map((entry) => 
          _buildPopupMenuItem(entry.key, entry.value)
        ).toList();
      },
      child: AppAvatar.small(
        imageUrl: user?.avatar,
        initials: _getUserInitials(),
      ),
    );
  }
  
  PopupMenuItem<String> _buildPopupMenuItem(String key, UserMenuAction action) {
    return PopupMenuItem<String>(
      value: key,
      child: Row(
        children: [
          Icon(
            action.icon,
            size: LayoutConstants.iconMedium,
            color: action.isDangerous ? AppTheme.errorColor : null,
          ),
          SizedBox(width: LayoutConstants.marginXs),
          Text(
            action.label,
            style: TextStyle(
              color: action.isDangerous ? AppTheme.errorColor : null,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInlineMenuItem(BuildContext context, String key, UserMenuAction action) {
    return ListTile(
      leading: Icon(
        action.icon,
        size: LayoutConstants.iconMedium,
        color: action.isDangerous 
            ? AppTheme.errorColor 
            : (textColor ?? AppTheme.onSurface),
      ),
      title: Text(
        action.label,
        style: TextStyle(
          color: action.isDangerous 
              ? AppTheme.errorColor 
              : (textColor ?? AppTheme.onSurface),
        ),
      ),
      onTap: action.onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: LayoutConstants.paddingXs,
        vertical: 0,
      ),
    );
  }
  
  Widget _buildMenuTrigger(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutConstants.marginXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(
            radius: avatarRadius,
            imageUrl: user?.avatar,
            initials: _getUserInitials(),
          ),
          if (showUserName && context.isDesktop) ...[
            SizedBox(width: LayoutConstants.marginXs),
            AppText.body(
              _getDisplayName(),
              color: textColor ?? Colors.white,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (showDropdownIcon && context.isDesktop) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: textColor ?? Colors.white,
              size: LayoutConstants.iconMedium,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildUserInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
      ),
      child: Row(
        children: [
          AppAvatar(
            radius: avatarRadius ?? LayoutConstants.avatarMedium,
            imageUrl: user?.avatar,
            initials: _getUserInitials(),
          ),
          SizedBox(width: LayoutConstants.marginSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.body(
                  user?.name ?? fallbackName ?? 'Usuário',
                  color: textColor ?? AppTheme.onSurface,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user?.email != null) ...[
                  const SizedBox(height: 2),
                  AppText.caption(
                    user!.email,
                    color: (textColor ?? AppTheme.onSurface).withValues(alpha: 0.7),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getDisplayName() {
    if (user?.name != null) {
      return user!.name.split(' ').first;
    }
    return fallbackName ?? 'Usuário';
  }
  
  String? _getUserInitials() {
    if (user?.name != null) {
      final nameParts = user!.name.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts.first[0]}${nameParts.last[0]}';
      } else if (nameParts.isNotEmpty) {
        return nameParts.first[0];
      }
    }
    return null;
  }
}

/// Classe para ações do menu do usuário
class UserMenuAction {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDangerous;
  
  const UserMenuAction({
    required this.label,
    required this.icon,
    this.onTap,
    this.isDangerous = false,
  });
}

/// Enum para variantes do menu - Open/Closed Principle
enum UserMenuVariant {
  popup,
  inline,
  compact,
}

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppUserMenu ao invés de UserMenu')
typedef UserMenu = AppUserMenu;