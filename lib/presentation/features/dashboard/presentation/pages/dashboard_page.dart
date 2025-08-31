import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../design_system/app_theme.dart';
import '../../../../notification/snackbar_notification.dart';
import '../../../../responsive/breakpoints.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(authControllerProvider);
    
    return Padding(
      padding: EdgeInsets.all(context.responsive<double>(
        xs: 16,
        sm: 20,
        md: 24,
        lg: 32,
      )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.responsive<double>(
                xs: 16,
                sm: 20,
                md: 24,
                lg: 28,
              )),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.waving_hand,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  userAsyncValue.when(
                    data: (user) {
                      if (user != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bem-vindo, ${user.name}!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.role.name,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return const Text(
                        'Bem-vindo!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                    loading: () => const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    error: (error, stack) => Text(
                      'Erro ao carregar dados do usuário',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Ações Rápidas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Action Cards Grid
            Flexible(
              child: GridView.count(
                crossAxisCount: context.responsive<int>(
                  xs: 1,
                  sm: 2,
                  md: 2,
                  lg: 3,
                  xl: 4,
                ),
                mainAxisSpacing: context.responsive<double>(
                  xs: 12,
                  sm: 16,
                  md: 20,
                ),
                crossAxisSpacing: context.responsive<double>(
                  xs: 12,
                  sm: 16,
                  md: 20,
                ),
                shrinkWrap: true,
                children: [
                  _ActionCard(
                    icon: Icons.business,
                    title: 'Torres',
                    subtitle: 'Visualizar torres\ndisponíveis',
                    color: Colors.blue,
                    onTap: () {
                      SnackbarNotification.showInfo('Funcionalidade em desenvolvimento');
                    },
                  ),
                  _ActionCard(
                    icon: Icons.apartment,
                    title: 'Apartamentos',
                    subtitle: 'Navegar por\napartamentos',
                    color: Colors.green,
                    onTap: () {
                      SnackbarNotification.showInfo('Funcionalidade em desenvolvimento');
                    },
                  ),
                  _ActionCard(
                    icon: Icons.favorite,
                    title: 'Favoritos',
                    subtitle: 'Ver imóveis\nfavoritos',
                    color: Colors.red,
                    onTap: () {
                      SnackbarNotification.showInfo('Funcionalidade em desenvolvimento');
                    },
                  ),
                  _ActionCard(
                    icon: Icons.settings,
                    title: 'Configurações',
                    subtitle: 'Ajustar\npreferências',
                    color: Colors.orange,
                    onTap: () {
                      SnackbarNotification.showInfo('Funcionalidade em desenvolvimento');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}