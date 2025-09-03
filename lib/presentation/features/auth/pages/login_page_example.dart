import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/domain_providers.dart';

/// Example of how to use Riverpod providers with Clean Architecture
/// This demonstrates proper separation between UI and business logic
class LoginPageExample extends ConsumerStatefulWidget {
  const LoginPageExample({super.key});

  @override
  ConsumerState<LoginPageExample> createState() => _LoginPageExampleState();
}

class _LoginPageExampleState extends ConsumerState<LoginPageExample> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ CORRECT: Using providers to access use cases through Clean Architecture
    final authNotifier = ref.read(authStateProvider.notifier);

    await authNotifier.login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECT: Watching authentication state through provider
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - Clean Architecture'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Authentication State Display
              _buildAuthStateDisplay(authState),

              const SizedBox(height: 24),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Email é obrigatório';
                  }
                  if (!value!.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Senha é obrigatória';
                  }
                  if (value!.length < 6) {
                    return 'Senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Entrar'),
                ),
              ),

              const SizedBox(height: 24),

              // User Info Section (if logged in)
              _buildUserInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthStateDisplay(AsyncValue authState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estado da Autenticação:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          authState.when(
            loading: () => const Row(
              children: [
                SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Carregando...'),
              ],
            ),
            error: (error, _) => Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Erro: $error', style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
            data: (user) => Row(
              children: [
                Icon(
                  user != null ? Icons.check_circle : Icons.person_off,
                  color: user != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  user != null ? 'Logado como: ${user.name ?? user.email}' : 'Não logado',
                  style: TextStyle(color: user != null ? Colors.green : Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    // ✅ CORRECT: Using provider to get current user data
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Erro ao carregar usuário: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return const Card(
            child: Padding(padding: EdgeInsets.all(16), child: Text('Nenhum usuário logado')),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informações do Usuário:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('ID: ${user.localId}'),
                Text('Nome: ${user.name}'),
                Text('Email: ${user.email}'),
                if (user.avatarUrl != null) Text('Avatar: ${user.avatarUrl}'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // ✅ CORRECT: Using provider to logout
                      ref.read(authStateProvider.notifier).logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sair'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Example of a different approach - Menu listing using providers
class MenuListExample extends ConsumerWidget {
  const MenuListExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ CORRECT: Using provider to get current enterprise first
    final enterpriseAsync = ref.watch(currentEnterpriseProvider);

    return Scaffold(
      body: enterpriseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar empresa: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentEnterpriseProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (enterprise) {
          if (enterprise == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhuma empresa encontrada'),
                ],
              ),
            );
          }

          // ✅ CORRECT: Now we can fetch menus using the enterprise ID
          final menusAsync = ref.watch(menuHierarchyProvider(enterprise.localId));

          return menusAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar menus: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(menuHierarchyProvider(enterprise.localId)),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
            data: (menus) {
              if (menus.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nenhum menu configurado'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(menuHierarchyProvider(enterprise.localId));
                },
                child: ListView.builder(
                  itemCount: menus.length,
                  itemBuilder: (context, index) {
                    final menu = menus[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(menu.name?.substring(0, 1).toUpperCase() ?? 'M'),
                        ),
                        title: Text(menu.name ?? 'Menu'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (menu.description != null) Text(menu.description!),
                            Text('ID: ${menu.localId}'),
                            Text('Ativo: ${menu.isActive ? "Sim" : "Não"}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // ✅ CORRECT: Navigate to tower list using menu ID
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TowerListExample(menuId: menu.localId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Example of Tower listing for a specific menu
class TowerListExample extends ConsumerWidget {
  final String menuId;

  const TowerListExample({super.key, required this.menuId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ CORRECT: Using provider with family parameter
    final towersAsync = ref.watch(towersByMenuProvider(menuId));

    return Scaffold(
      body: towersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar torres: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(towersByMenuProvider(menuId)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (towers) {
          if (towers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apartment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhuma torre encontrada'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(towersByMenuProvider(menuId));
            },
            child: ListView.builder(
              itemCount: towers.length,
              itemBuilder: (context, index) {
                final tower = towers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.apartment)),
                    title: Text(tower.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tower.description != null) Text(tower.description!),
                        Text('ID: ${tower.localId}'),
                        Text('Andares: ${tower.totalFloors}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Here you could navigate to tower details
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Torre selecionada: ${tower.title}')));
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
