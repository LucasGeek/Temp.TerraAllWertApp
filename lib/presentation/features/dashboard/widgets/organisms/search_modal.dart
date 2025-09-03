import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';
import '../../../../layout/widgets/atoms/primary_button.dart';

enum SearchType {
  suites('Suítes'),
  posicaoSolar('Posição Solar'),
  numeroUnidade('Número da Unidade');

  const SearchType(this.label);
  final String label;
}

enum TowerType {
  torre1('Torre 1'),
  torre2('Torre 2'),
  todas('Todas as Torres');

  const TowerType(this.label);
  final String label;
}

class SearchModal extends ConsumerStatefulWidget {
  const SearchModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SearchModal(),
    );
  }

  @override
  ConsumerState<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends ConsumerState<SearchModal> {
  SearchType? _selectedSearchType;
  TowerType? _selectedTower;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: context.responsive<double>(
            xs: MediaQuery.of(context).size.width * 0.9,
            sm: 400,
            md: 500,
            lg: 600,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(), _buildContent(), _buildActions()],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(LayoutConstants.radiusMedium)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Buscar Pavimentação',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppTheme.onPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchTypeDropdown(),
          SizedBox(height: LayoutConstants.paddingMd),
          _buildTowerDropdown(),
          SizedBox(height: LayoutConstants.paddingMd),
          _buildSearchInput(),
        ],
      ),
    );
  }

  Widget _buildSearchTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Pavimentação',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        SizedBox(height: LayoutConstants.paddingXs),
        DropdownButtonFormField<SearchType>(
          value: _selectedSearchType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: LayoutConstants.paddingMd,
              vertical: LayoutConstants.paddingMd,
            ),
          ),
          hint: const Text('Selecione o tipo de busca'),
          items: SearchType.values.map((type) {
            return DropdownMenuItem<SearchType>(value: type, child: Text(type.label));
          }).toList(),
          onChanged: (SearchType? newValue) {
            setState(() {
              _selectedSearchType = newValue;
              _searchController.clear(); // Limpa o campo ao mudar tipo
            });
          },
        ),
      ],
    );
  }

  Widget _buildTowerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Torre',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        SizedBox(height: LayoutConstants.paddingXs),
        DropdownButtonFormField<TowerType>(
          value: _selectedTower,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: LayoutConstants.paddingMd,
              vertical: LayoutConstants.paddingMd,
            ),
          ),
          hint: const Text('Selecione a torre'),
          items: TowerType.values.map((tower) {
            return DropdownMenuItem<TowerType>(value: tower, child: Text(tower.label));
          }).toList(),
          onChanged: (TowerType? newValue) {
            setState(() {
              _selectedTower = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchInput() {
    if (_selectedSearchType == null) {
      return const SizedBox.shrink();
    }

    String labelText;
    String hintText;
    TextInputType? keyboardType;

    switch (_selectedSearchType!) {
      case SearchType.suites:
        labelText = 'Número da Suíte';
        hintText = 'Ex: 101, 202, 303...';
        keyboardType = TextInputType.number;
        break;
      case SearchType.posicaoSolar:
        labelText = 'Posição Solar';
        hintText = 'Ex: Norte, Sul, Leste, Oeste';
        keyboardType = TextInputType.text;
        break;
      case SearchType.numeroUnidade:
        labelText = 'Número da Unidade';
        hintText = 'Ex: 1, 2, 3...';
        keyboardType = TextInputType.number;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        SizedBox(height: LayoutConstants.paddingXs),
        TextFormField(
          controller: _searchController,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: LayoutConstants.paddingMd,
              vertical: LayoutConstants.paddingMd,
            ),
            hintText: hintText,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Este campo é obrigatório';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSearching ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          SizedBox(width: LayoutConstants.paddingMd),
          AppButton.primary(
            text: 'Buscar',
            isLoading: _isSearching,
            isFullWidth: false,
            onPressed: _canSearch() && !_isSearching ? _handleSearch : null,
          ),
        ],
      ),
    );
  }

  bool _canSearch() {
    return _selectedSearchType != null &&
        _selectedTower != null &&
        _searchController.text.trim().isNotEmpty;
  }

  Future<void> _handleSearch() async {
    if (!_canSearch()) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Preparar dados de busca
      final searchData = {
        'searchType': _selectedSearchType!.name,
        'tower': _selectedTower!.name,
        'searchValue': _searchController.text.trim(),
      };

      // Fechar modal
      if (mounted) {
        Navigator.of(context).pop();

        // Navegar para tela de resultados
        context.push('/search-results', extra: searchData);
      }
    } catch (e) {
      _showError('Erro ao realizar busca: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor));
    }
  }
}
