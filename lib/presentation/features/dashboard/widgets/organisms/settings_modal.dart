import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';
import '../../../../layout/widgets/atoms/primary_button.dart';

/// Organism: Modal de configurações do aplicativo
class SettingsModal extends ConsumerStatefulWidget {
  const SettingsModal({super.key});
  
  /// Método estático para mostrar o modal
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const SettingsModal(),
    );
  }

  @override
  ConsumerState<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends ConsumerState<SettingsModal> {
  // Configurações de Aparência
  bool _darkMode = false;
  String _selectedLanguage = 'pt_BR';
  double _fontSize = 14.0;
  
  // Configurações de Notificações
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _soundAlerts = true;
  
  // Configurações de Sincronização
  bool _autoSync = true;
  String _syncInterval = '15min';
  bool _syncOnlyWifi = false;
  
  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      child: Container(
        width: isDesktop ? 700 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: isDesktop ? 700 : MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                child: _buildContent(context),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(LayoutConstants.radiusMedium),
          topRight: Radius.circular(LayoutConstants.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings,
            color: AppTheme.onPrimary,
            size: LayoutConstants.iconLarge,
          ),
          SizedBox(width: LayoutConstants.marginSm),
          Expanded(
            child: Text(
              'Configurações',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close, color: AppTheme.onPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção da Empresa
          _buildCompanySection(context),
          
          SizedBox(height: LayoutConstants.marginLg),
          Divider(color: AppTheme.outline.withValues(alpha: 0.2)),
          SizedBox(height: LayoutConstants.marginLg),
          
          // Seção de Aparência
          _buildSectionHeader(context, 'Aparência', Icons.palette),
          SizedBox(height: LayoutConstants.marginMd),
          
          _buildSwitchTile(
            context: context,
            title: 'Modo Escuro',
            subtitle: 'Ativa o tema escuro do aplicativo',
            icon: Icons.dark_mode,
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          
          SizedBox(height: LayoutConstants.marginMd),
          
          _buildDropdownTile(
            context: context,
            title: 'Idioma',
            subtitle: 'Selecione o idioma do aplicativo',
            icon: Icons.language,
            value: _selectedLanguage,
            items: const [
              {'value': 'pt_BR', 'label': 'Português (Brasil)'},
              {'value': 'en_US', 'label': 'English (US)'},
              {'value': 'es_ES', 'label': 'Español'},
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedLanguage = value;
                });
              }
            },
          ),
          
          SizedBox(height: LayoutConstants.marginMd),
          
          _buildSliderTile(
            context: context,
            title: 'Tamanho da Fonte',
            subtitle: 'Ajuste o tamanho do texto',
            icon: Icons.text_fields,
            value: _fontSize,
            min: 12.0,
            max: 20.0,
            divisions: 8,
            onChanged: (value) {
              setState(() {
                _fontSize = value;
              });
            },
          ),
          
          SizedBox(height: LayoutConstants.marginLg),
          Divider(color: AppTheme.outline.withValues(alpha: 0.2)),
          SizedBox(height: LayoutConstants.marginLg),
          
          // Seção de Notificações
          _buildSectionHeader(context, 'Notificações', Icons.notifications),
          SizedBox(height: LayoutConstants.marginMd),
          
          _buildSwitchTile(
            context: context,
            title: 'Notificações Push',
            subtitle: 'Receba alertas no dispositivo',
            icon: Icons.notifications_active,
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          
          SizedBox(height: LayoutConstants.marginMd),
          
          _buildSwitchTile(
            context: context,
            title: 'Notificações por Email',
            subtitle: 'Receba atualizações por email',
            icon: Icons.email,
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          
          SizedBox(height: LayoutConstants.marginMd),
          
          _buildSwitchTile(
            context: context,
            title: 'Alertas Sonoros',
            subtitle: 'Reproduzir sons para notificações',
            icon: Icons.volume_up,
            value: _soundAlerts,
            onChanged: (value) {
              setState(() {
                _soundAlerts = value;
              });
            },
          ),
          
          SizedBox(height: LayoutConstants.marginLg),
          Divider(color: AppTheme.outline.withValues(alpha: 0.2)),
          SizedBox(height: LayoutConstants.marginLg),
          
          // Seção de Sincronização
          _buildSectionHeader(context, 'Sincronização', Icons.sync),
          SizedBox(height: LayoutConstants.marginMd),
          
          _buildSwitchTile(
            context: context,
            title: 'Sincronização Automática',
            subtitle: 'Sincronizar dados automaticamente',
            icon: Icons.sync_alt,
            value: _autoSync,
            onChanged: (value) {
              setState(() {
                _autoSync = value;
              });
            },
          ),
          
          if (_autoSync) ...[
            SizedBox(height: LayoutConstants.marginMd),
            
            _buildDropdownTile(
              context: context,
              title: 'Intervalo de Sincronização',
              subtitle: 'Frequência da sincronização automática',
              icon: Icons.schedule,
              value: _syncInterval,
              items: const [
                {'value': '5min', 'label': 'A cada 5 minutos'},
                {'value': '15min', 'label': 'A cada 15 minutos'},
                {'value': '30min', 'label': 'A cada 30 minutos'},
                {'value': '1h', 'label': 'A cada 1 hora'},
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _syncInterval = value;
                  });
                }
              },
            ),
            
            SizedBox(height: LayoutConstants.marginMd),
            
            _buildSwitchTile(
              context: context,
              title: 'Apenas Wi-Fi',
              subtitle: 'Sincronizar apenas quando conectado ao Wi-Fi',
              icon: Icons.wifi,
              value: _syncOnlyWifi,
              onChanged: (value) {
                setState(() {
                  _syncOnlyWifi = value;
                });
              },
            ),
          ],
          
          SizedBox(height: LayoutConstants.marginLg),
          
          // Informações Adicionais
          _buildInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildCompanySection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo da empresa (placeholder)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'TA',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: LayoutConstants.marginMd),
              
              // Informações da empresa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terra Allwert',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: LayoutConstants.marginXs),
                    Text(
                      'Sistema de Gestão Imobiliária',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: LayoutConstants.marginXs),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: LayoutConstants.paddingSm,
                        vertical: LayoutConstants.paddingXs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Empresa Ativa',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: LayoutConstants.marginMd),
          
          // Informações adicionais da empresa
          _buildCompanyInfo(context),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'CNPJ', '12.345.678/0001-90', Icons.business),
          SizedBox(height: LayoutConstants.marginSm),
          _buildInfoRow(context, 'Telefone', '(11) 99999-9999', Icons.phone),
          SizedBox(height: LayoutConstants.marginSm),
          _buildInfoRow(context, 'Email', 'contato@terraallwert.com', Icons.email),
          SizedBox(height: LayoutConstants.marginSm),
          _buildInfoRow(context, 'Plano', 'Premium - 50 propriedades', Icons.star),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        SizedBox(width: LayoutConstants.marginSm),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppTheme.primaryColor),
        SizedBox(width: LayoutConstants.marginSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppTheme.primaryColor),
          SizedBox(width: LayoutConstants.marginMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: AppTheme.primaryColor),
              SizedBox(width: LayoutConstants.marginMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: LayoutConstants.marginSm),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: LayoutConstants.paddingMd,
                vertical: LayoutConstants.paddingXs,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item['value'],
                child: Text(item['label']!),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: AppTheme.primaryColor),
              SizedBox(width: LayoutConstants.marginMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: LayoutConstants.paddingSm,
                  vertical: LayoutConstants.paddingXs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                ),
                child: Text(
                  '${value.toInt()}px',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${value.toInt()}px',
            activeColor: AppTheme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: Colors.blue),
              SizedBox(width: LayoutConstants.marginSm),
              Text(
                'Sobre as Configurações',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: LayoutConstants.marginSm),
          Text(
            'As configurações são sincronizadas com sua conta e aplicadas em todos os dispositivos onde você fizer login.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: LayoutConstants.marginXs),
          Text(
            'Versão do App: 1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _resetToDefaults,
            child: const Text('Restaurar Padrões'),
          ),
          const Spacer(),
          AppButton.secondary(
            text: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          SizedBox(width: LayoutConstants.marginMd),
          AppButton.primary(
            text: 'Salvar',
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _darkMode = false;
      _selectedLanguage = 'pt_BR';
      _fontSize = 14.0;
      _pushNotifications = true;
      _emailNotifications = false;
      _soundAlerts = true;
      _autoSync = true;
      _syncInterval = '15min';
      _syncOnlyWifi = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações restauradas para o padrão'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _saveSettings() {
    // TODO: Implementar salvamento das configurações
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}