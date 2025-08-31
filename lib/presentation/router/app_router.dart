import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../widgets/components/templates/main_layout.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(currentRoute: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/towers',
            name: 'towers',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Torres - Em desenvolvimento'))),
          ),
          GoRoute(
            path: '/apartments',
            name: 'apartments',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Apartamentos - Em desenvolvimento'))),
          ),
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Favoritos - Em desenvolvimento'))),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Perfil - Em desenvolvimento'))),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(child: Text('The requested page was not found.')),
    ),
  );
}
