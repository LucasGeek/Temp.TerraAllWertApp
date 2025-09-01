import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';
import '../../../widgets/organisms/app_header.dart';

class SearchResultsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> searchData;

  const SearchResultsPage({
    super.key,
    required this.searchData,
  });

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSearchResults();
  }

  Future<void> _loadSearchResults() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final mockResults = _generateMockResults();

    if (mounted) {
      setState(() {
        _results = mockResults;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateMockResults() {
    final searchType = widget.searchData['searchType'] as String;
    final tower = widget.searchData['tower'] as String;
    final searchValue = widget.searchData['searchValue'] as String;

    final List<Map<String, dynamic>> mockData = [];

    switch (searchType) {
      case 'suites':
        if (tower == 'torre1' || tower == 'todas') {
          mockData.add({
            'id': '1',
            'suite': searchValue,
            'tower': 'Torre 1',
            'floor': '${searchValue[0]}° Andar',
            'area': '85m²',
            'bedrooms': 3,
            'bathrooms': 2,
            'price': 'R\$ 650.000',
            'status': 'Disponível',
            'solarPosition': 'Norte/Sul',
          });
        }
        if (tower == 'torre2' || tower == 'todas') {
          mockData.add({
            'id': '2',
            'suite': searchValue,
            'tower': 'Torre 2',
            'floor': '${searchValue[0]}° Andar',
            'area': '92m²',
            'bedrooms': 3,
            'bathrooms': 3,
            'price': 'R\$ 720.000',
            'status': 'Disponível',
            'solarPosition': 'Leste/Oeste',
          });
        }
        break;

      case 'posicaoSolar':
        if (tower == 'torre1' || tower == 'todas') {
          mockData.addAll([
            {
              'id': '3',
              'suite': '302',
              'tower': 'Torre 1',
              'floor': '3° Andar',
              'area': '85m²',
              'bedrooms': 3,
              'bathrooms': 2,
              'price': 'R\$ 650.000',
              'status': 'Disponível',
              'solarPosition': searchValue,
            },
            {
              'id': '4',
              'suite': '402',
              'tower': 'Torre 1',
              'floor': '4° Andar',
              'area': '85m²',
              'bedrooms': 3,
              'bathrooms': 2,
              'price': 'R\$ 670.000',
              'status': 'Reservado',
              'solarPosition': searchValue,
            },
          ]);
        }
        if (tower == 'torre2' || tower == 'todas') {
          mockData.add({
            'id': '5',
            'suite': '501',
            'tower': 'Torre 2',
            'floor': '5° Andar',
            'area': '92m²',
            'bedrooms': 3,
            'bathrooms': 3,
            'price': 'R\$ 750.000',
            'status': 'Vendido',
            'solarPosition': searchValue,
          });
        }
        break;

      case 'numeroUnidade':
        mockData.add({
          'id': '6',
          'suite': '${searchValue}02',
          'tower': tower == 'torre1' ? 'Torre 1' : tower == 'torre2' ? 'Torre 2' : 'Torre 1',
          'floor': '$searchValue° Andar',
          'area': tower == 'torre1' ? '85m²' : '92m²',
          'bedrooms': 3,
          'bathrooms': tower == 'torre1' ? 2 : 3,
          'price': tower == 'torre1' ? 'R\$ ${650 + (int.parse(searchValue) * 20)}.000' : 'R\$ ${720 + (int.parse(searchValue) * 30)}.000',
          'status': int.parse(searchValue) % 3 == 0 ? 'Vendido' : int.parse(searchValue) % 2 == 0 ? 'Reservado' : 'Disponível',
          'solarPosition': int.parse(searchValue) % 2 == 0 ? 'Norte/Sul' : 'Leste/Oeste',
        });
        break;
    }

    return mockData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        showMenuButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    final searchType = widget.searchData['searchType'] as String;
    final tower = widget.searchData['tower'] as String;
    final searchValue = widget.searchData['searchValue'] as String;

    String searchTypeLabel = '';
    switch (searchType) {
      case 'suites':
        searchTypeLabel = 'Suítes';
        break;
      case 'posicaoSolar':
        searchTypeLabel = 'Posição Solar';
        break;
      case 'numeroUnidade':
        searchTypeLabel = 'Número da Unidade';
        break;
    }

    String towerLabel = '';
    switch (tower) {
      case 'torre1':
        towerLabel = 'Torre 1';
        break;
      case 'torre2':
        towerLabel = 'Torre 2';
        break;
      case 'todas':
        towerLabel = 'Todas as Torres';
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(LayoutConstants.radiusMedium),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultados da Busca',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: LayoutConstants.paddingXs),
          Text(
            '$searchTypeLabel: $searchValue',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          Text(
            'Torre: $towerLabel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          if (_results.isNotEmpty && !_isLoading) ...[
            SizedBox(height: LayoutConstants.paddingXs),
            Text(
              '${_results.length} resultado${_results.length != 1 ? 's' : ''} encontrado${_results.length != 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Buscando pavimentações...'),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    final crossAxisCount = context.responsive<int>(
      xs: 1,
      sm: 1,
      md: 2,
      lg: 3,
      xl: 4,
      xxl: 5,
    );

    return GridView.builder(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: LayoutConstants.paddingMd,
        mainAxisSpacing: LayoutConstants.paddingMd,
        childAspectRatio: 0.8,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildResultCard(_results[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(LayoutConstants.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.onSurface.withValues(alpha: 0.5),
            ),
            SizedBox(height: LayoutConstants.paddingMd),
            Text(
              'Nenhum resultado encontrado',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: LayoutConstants.paddingXs),
            Text(
              'Tente ajustar os filtros de busca',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    Color statusColor;
    switch (result['status']) {
      case 'Disponível':
        statusColor = Colors.green;
        break;
      case 'Reservado':
        statusColor = Colors.orange;
        break;
      case 'Vendido':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: LayoutConstants.elevationXs,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
      ),
      child: Padding(
        padding: EdgeInsets.all(LayoutConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suíte ${result['suite']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    result['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: LayoutConstants.paddingXs),
            Text(
              '${result['tower']} • ${result['floor']}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: LayoutConstants.paddingSm),
            Row(
              children: [
                Icon(Icons.straighten, size: 16, color: AppTheme.onSurface.withValues(alpha: 0.6)),
                SizedBox(width: LayoutConstants.paddingXs),
                Text(
                  result['area'],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(width: LayoutConstants.paddingSm),
                Icon(Icons.bed, size: 16, color: AppTheme.onSurface.withValues(alpha: 0.6)),
                SizedBox(width: LayoutConstants.paddingXs),
                Text(
                  '${result['bedrooms']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(width: LayoutConstants.paddingSm),
                Icon(Icons.bathroom, size: 16, color: AppTheme.onSurface.withValues(alpha: 0.6)),
                SizedBox(width: LayoutConstants.paddingXs),
                Text(
                  '${result['bathrooms']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: LayoutConstants.paddingSm),
            Row(
              children: [
                Icon(Icons.wb_sunny, size: 16, color: AppTheme.onSurface.withValues(alpha: 0.6)),
                SizedBox(width: LayoutConstants.paddingXs),
                Expanded(
                  child: Text(
                    result['solarPosition'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Divider(height: LayoutConstants.paddingSm),
            Text(
              result['price'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

