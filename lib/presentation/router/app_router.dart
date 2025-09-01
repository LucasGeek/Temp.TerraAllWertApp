import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/dynamic/pages/dynamic_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/navigation/providers/navigation_provider.dart';
import '../features/navigation/providers/current_route_provider.dart';
import '../widgets/templates/main_layout.dart';
import '../../infra/logging/app_logger.dart';

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

  /// Slide from right transition for main app pages
  static CustomTransitionPage<T> slideTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: CurveTween(curve: Curves.easeIn).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  /// Scale and fade transition for dynamic pages
  static CustomTransitionPage<T> scaleTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurveTween(curve: Curves.easeOutBack).animate(animation),
          child: FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  /// No transition for shell routes (layout changes)
  static NoTransitionPage<T> noTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return NoTransitionPage<T>(
      key: state.pageKey,
      child: child,
    );
  }
}

class AppRouter {
  static GoRouter createRouter(WidgetRef ref) {
    final navigationItems = ref.watch(navigationItemsProvider);
    
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) => _handleRedirect(context, state, ref),
      routes: [
        GoRoute(
          path: '/login', 
          name: 'login', 
          builder: (context, state) => const LoginPage()
        ),
        ShellRoute(
          builder: (context, state, child) => MainLayout(
            currentRoute: state.uri.path, 
            child: child
          ),
          routes: [
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
            ..._buildDynamicRoutes(navigationItems),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: const Center(child: Text('The requested page was not found.')),
      ),
    );
  }

  static List<GoRoute> _buildDynamicRoutes(List<dynamic> navigationItems) {
    try {
      final dynamicRoutes = <GoRoute>[];

      for (final item in navigationItems) {
        // Skip dashboard route as it's already defined
        if (item.route == '/dashboard') continue;

        // Create dynamic route for each navigation item
        final route = GoRoute(
          path: item.route,
          name: item.id,
          builder: (context, state) => DynamicPage(
            route: item.route,
            title: item.label,
          ),
        );

        dynamicRoutes.add(route);
        AppLogger.debug('AppRouter: Created dynamic route ${item.route} for ${item.label}', tag: 'ROUTER');
      }

      return dynamicRoutes;
    } catch (e) {
      AppLogger.error('AppRouter: Error building dynamic routes', error: e, tag: 'ROUTER');
      return [];
    }
  }

  static String? _handleRedirect(BuildContext context, GoRouterState state, WidgetRef ref) {
    try {
      final authState = ref.read(authControllerProvider);
      final isAuthenticated = authState.value != null;
      final currentPath = state.uri.path;

      AppLogger.debug('AppRouter: Checking redirect for path: $currentPath, authenticated: $isAuthenticated', tag: 'ROUTER');

      // Se está autenticado e tenta acessar login, redireciona para dashboard
      if (isAuthenticated && currentPath == '/login') {
        AppLogger.info('AppRouter: Authenticated user tried to access login, redirecting to dashboard', tag: 'ROUTER');
        return '/dashboard';
      }

      // Se não está autenticado e não está na página de login, redireciona para login
      if (!isAuthenticated && currentPath != '/login') {
        AppLogger.info('AppRouter: Unauthenticated user tried to access protected route, redirecting to login', tag: 'ROUTER');
        return '/login';
      }

      // Redirecionar root para dashboard se autenticado, para login se não autenticado
      if (currentPath == '/') {
        final redirectTo = isAuthenticated ? '/dashboard' : '/login';
        AppLogger.info('AppRouter: Root path accessed, redirecting to $redirectTo', tag: 'ROUTER');
        return redirectTo;
      }

      return null; // No redirect needed
    } catch (e) {
      AppLogger.error('AppRouter: Error in redirect logic', error: e, tag: 'ROUTER');
      return '/login'; // Fallback to login on error
    }
  }
}

// Provider for the router that rebuilds when navigation items change
final routerProvider = Provider<GoRouter>((ref) {
  // Watch navigation items to rebuild router when they change
  final navigationItems = ref.watch(navigationItemsProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) => _redirectHandler(context, state, ref),
    routes: [
      GoRoute(
        path: '/login', 
        name: 'login', 
        pageBuilder: (context, state) => AppPageTransitions.fadeTransition(
          const LoginPage(),
          state,
        ),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) => AppPageTransitions.noTransition(
          MainLayout(
            currentRoute: state.uri.path, 
            child: child
          ),
          state,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => AppPageTransitions.slideTransition(
              const DashboardPage(),
              state,
            ),
          ),
          ..._buildDynamicRoutesFromItems(navigationItems),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(child: Text('The requested page was not found.')),
    ),
  );
});

String? _redirectHandler(BuildContext context, GoRouterState state, Ref ref) {
  try {
    final authState = ref.read(authControllerProvider);
    final isAuthenticated = authState.value != null;
    final currentPath = state.uri.path;
    final navigationItems = ref.read(navigationItemsProvider);
    final currentRoute = ref.read(currentRouteProvider);

    AppLogger.debug('AppRouter: Checking redirect for path: $currentPath, authenticated: $isAuthenticated', tag: 'ROUTER');

    // Se não está autenticado, redireciona para login
    if (!isAuthenticated) {
      if (currentPath != '/login') {
        AppLogger.info('AppRouter: Unauthenticated user tried to access protected route, redirecting to login', tag: 'ROUTER');
        return '/login';
      }
      return null;
    }

    // Se está autenticado e tenta acessar login, determina onde redirecionar
    if (currentPath == '/login') {
      String redirectTo;
      
      if (navigationItems.isNotEmpty) {
        // Se há menus criados, redireciona para o menu selecionado ou o primeiro
        redirectTo = currentRoute ?? navigationItems.first.route;
        AppLogger.info('AppRouter: Authenticated user tried to access login, redirecting to selected menu: $redirectTo', tag: 'ROUTER');
      } else {
        // Se não há menus, redireciona para dashboard
        redirectTo = '/dashboard';
        AppLogger.info('AppRouter: Authenticated user tried to access login, no menus found, redirecting to dashboard', tag: 'ROUTER');
      }
      
      return redirectTo;
    }

    // Redirecionar root path
    if (currentPath == '/') {
      String redirectTo;
      
      if (navigationItems.isNotEmpty) {
        // Se há menus criados, redireciona para o menu selecionado ou o primeiro
        redirectTo = currentRoute ?? navigationItems.first.route;
        AppLogger.info('AppRouter: Root path accessed, redirecting to menu: $redirectTo', tag: 'ROUTER');
      } else {
        // Se não há menus, redireciona para dashboard
        redirectTo = '/dashboard';
        AppLogger.info('AppRouter: Root path accessed, no menus found, redirecting to dashboard', tag: 'ROUTER');
      }
      
      return redirectTo;
    }

    return null; // No redirect needed
  } catch (e) {
    AppLogger.error('AppRouter: Error in redirect logic', error: e, tag: 'ROUTER');
    return '/login'; // Fallback to login on error
  }
}

List<GoRoute> _buildDynamicRoutesFromItems(List<dynamic> navigationItems) {
  try {
    final dynamicRoutes = <GoRoute>[];

    for (final item in navigationItems) {
      // Skip dashboard route as it's already defined
      if (item.route == '/dashboard') continue;

      // Create dynamic route for each navigation item with scale transition
      final route = GoRoute(
        path: item.route,
        name: item.id,
        pageBuilder: (context, state) => AppPageTransitions.scaleTransition(
          DynamicPage(
            route: item.route,
            title: item.label,
          ),
          state,
        ),
      );

      dynamicRoutes.add(route);
      AppLogger.debug('AppRouter: Created dynamic route ${item.route} for ${item.label}', tag: 'ROUTER');
    }

    return dynamicRoutes;
  } catch (e) {
    AppLogger.error('AppRouter: Error building dynamic routes', error: e, tag: 'ROUTER');
    return [];
  }
}
