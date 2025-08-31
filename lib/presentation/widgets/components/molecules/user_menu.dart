import 'package:flutter/material.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';
import '../atoms/user_avatar.dart';
import '../atoms/responsive_text.dart';
import '../../../../domain/entities/user.dart';

class UserMenu extends StatelessWidget {
  final User? user;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;
  
  const UserMenu({
    super.key,
    required this.user,
    required this.onProfileTap,
    required this.onSettingsTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'profile':
            onProfileTap();
            break;
          case 'settings':
            onSettingsTap();
            break;
          case 'logout':
            onLogoutTap();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person_outline, 
                size: LayoutConstants.iconMedium,
              ),
              SizedBox(width: LayoutConstants.marginXs),
              Text(user?.name ?? 'Perfil'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined, 
                size: LayoutConstants.iconMedium,
              ),
              SizedBox(width: LayoutConstants.marginXs),
              Text('Configurações'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout, 
                size: LayoutConstants.iconMedium,
              ),
              SizedBox(width: LayoutConstants.marginXs),
              Text('Sair'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: LayoutConstants.marginXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const UserAvatar(),
            if (context.isDesktop) ...[
              SizedBox(width: LayoutConstants.marginXs),
              ResponsiveText.body(
                user?.name?.split(' ').first ?? 'Usuário',
                color: Colors.white,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down, 
                color: Colors.white, 
                size: LayoutConstants.iconMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}