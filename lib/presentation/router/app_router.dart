import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../infra/logging/app_logger.dart';
import '../features/auth/pages/login_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/dashboard/pages/search_results_page.dart';
import '../features/dynamic/pages/dynamic_page.dart';
import '../layout/widgets/organisms/main_layout.dart';
import '../providers/current_route_provider.dart';
import '../providers/auth_provider.dart';

/// Custom page transitions for better UX
class AppPageTransitions {
  /// Smooth fade transition for authentication pages
  static CustomTransitionPage<T> fadeTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }

  /// Slide transition for dynamic pages
  static CustomTransitionPage<T> slideTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = const Duration(milliseconds: 250),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

/// Notifier para refresh do router baseado no estado de auth
class _RouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterRefreshNotifier(this._ref) {
    // Escuta mudanças no estado de autenticação
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }
}

/// Router configuration with authentication
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: _RouterRefreshNotifier(ref),
    routes: [
      // Shell route with layout
      ShellRoute(
        builder: (context, state, child) {
          final currentRoute = state.uri.path;
          
          // Delay provider update to avoid modifying during build
          Future.microtask(() {
            ref.read(currentRouteProvider.notifier).state = currentRoute;
          });
          
          return MainLayout(
            currentRoute: currentRoute,
            child: child,
          );
        },
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => AppPageTransitions.fadeTransition(
              const DashboardPage(),
              state,
            ),
          ),

          // Search
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => AppPageTransitions.fadeTransition(
              const SearchResultsPage(searchData: <String, dynamic>{}),
              state,
            ),
          ),

          // Dynamic routes
          GoRoute(
            path: '/dynamic/:route',
            name: 'dynamic',
            pageBuilder: (context, state) {
              final route = state.pathParameters['route']!;
              final title = state.uri.queryParameters['title'];
              
              return AppPageTransitions.slideTransition(
                DynamicPage(route: route, title: title),
                state,
              );
            },
          ),
        ],
      ),

      // Auth routes (outside main layout)
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => AppPageTransitions.fadeTransition(
          const LoginPage(),
          state,
        ),
      ),
    ],

    // Error handling
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Route "${state.uri.path}" not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    ),

    // Redirect logic - authentication based
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoginRoute = state.uri.path == '/login';
      
      AppLogger.debug('Router redirect check for: ${state.uri.path}, auth: ${authState.status}');
      
      // Se está carregando, não redireciona
      if (authState.isLoading) {
        return null;
      }
      
      // Se não está autenticado e não está na rota de login, redireciona para login
      if (!authState.isAuthenticated && !isLoginRoute) {
        AppLogger.debug('Redirecting to login - user not authenticated');
        return '/login';
      }
      
      // Se está autenticado e está na rota de login, redireciona para dashboard
      if (authState.isAuthenticated && isLoginRoute) {
        AppLogger.debug('Redirecting to dashboard - user authenticated');
        return '/dashboard';
      }
      
      // Se está autenticado ou na rota de login, permite acesso
      return null;
    },
  );
});