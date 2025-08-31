import 'package:flutter/material.dart';
import '../../notification/snackbar_notification.dart';

class SnackbarDemo extends StatelessWidget {
  const SnackbarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snackbar Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Demonstração dos Snackbars',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              _buildDemoButton(
                context,
                'Sucesso',
                Colors.green,
                () => SnackbarNotification.showSuccess('Operação realizada com sucesso!'),
              ),
              const SizedBox(height: 16),
              
              _buildDemoButton(
                context,
                'Erro',
                Colors.red,
                () => SnackbarNotification.showError('Ocorreu um erro na operação.'),
              ),
              const SizedBox(height: 16),
              
              _buildDemoButton(
                context,
                'Informação',
                Colors.blue,
                () => SnackbarNotification.showInfo('Esta é uma mensagem informativa.'),
              ),
              const SizedBox(height: 16),
              
              _buildDemoButton(
                context,
                'Aviso',
                Colors.orange,
                () => SnackbarNotification.showWarning('Atenção: verifique os dados inseridos.'),
              ),
              const SizedBox(height: 16),
              
              _buildDemoButton(
                context,
                'Loading',
                Colors.purple,
                () => SnackbarNotification.showLoading('Carregando...'),
              ),
              const SizedBox(height: 16),
              
              _buildDemoButton(
                context,
                'Esconder Loading',
                Colors.grey,
                () => SnackbarNotification.hideLoading(),
              ),
              
              const SizedBox(height: 32),
              const Text(
                'Teste em diferentes tamanhos de tela:\n'
                '• Mobile: Ocupa toda largura\n'
                '• Tablet+: Centralizado e limitado',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}