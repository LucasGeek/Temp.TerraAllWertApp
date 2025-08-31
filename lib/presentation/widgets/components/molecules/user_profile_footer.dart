import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';
import '../atoms/user_avatar.dart';
import '../../../../domain/entities/user.dart';

class UserProfileFooter extends StatelessWidget {
  final User? user;
  final VoidCallback onLogoutTap;
  final bool isLoading;
  
  const UserProfileFooter({
    super.key,
    required this.user,
    required this.onLogoutTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive<double>(
        xs: LayoutConstants.paddingMd,
        md: LayoutConstants.paddingLg,
      )),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.onPrimary.withValues(alpha: 0.2),
            width: LayoutConstants.strokeThin,
          ),
        ),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                UserAvatar(
                  radius: LayoutConstants.iconLarge,
                  backgroundColor: AppTheme.primaryColor.withValues(
                    alpha: LayoutConstants.opacityLight,
                  ),
                ),
                SizedBox(width: LayoutConstants.marginSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.name ?? 'Usuário',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: LayoutConstants.fontSizeMedium,
                          color: AppTheme.onPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: AppTheme.onPrimary.withValues(alpha: 0.8),
                          fontSize: LayoutConstants.fontSizeSmall,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onLogoutTap,
                  icon: const Icon(Icons.logout, color: AppTheme.onPrimary),
                  iconSize: LayoutConstants.iconMedium,
                  tooltip: 'Sair',
                  splashRadius: LayoutConstants.iconSplashRadius,
                ),
              ],
            ),
    );
  }
}