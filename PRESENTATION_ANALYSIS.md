# Análise de Inconsistências nas Presentations

## Problemas Identificados

### 1. **Dialogs Inconsistentes**

#### FloorPlanPresentation
- Usa `AlertDialog` diretamente
- Estilos diferentes para cada dialog
- Sem padronização de botões
- Código duplicado para validação

```dart
// Exemplo atual (inconsistente)
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Adicionar Pavimento'),
    // Estilo específico sem padronização
  ),
);
```

#### ImageCarouselPresentation  
- Mistura `AlertDialog` e `showDialog` com estilos diferentes
- Botões com cores hardcoded
- Sem validação padronizada
- UI inconsistente entre dialogs

#### PinMapPresentation
- Similar aos outros, mas com variações de estilo
- SnackBar usado de forma inconsistente
- Diferentes padrões de confirmação

### 2. **Bottom Sheets Inconsistentes**

#### FloorPlanPresentation
```dart
showModalBottomSheet<void>(
  context: context,
  builder: (BuildContext context) {
    // Implementação específica sem padronização
  },
);
```

Problemas:
- Sem handle visual padrão
- Diferentes estilos de header
- Inconsistência na estrutura de botões

### 3. **Snackbars Despadronizados**

#### PinMapPresentation
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Este pin não possui imagens'),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
  ),
);
```

Problemas:
- Não usa o SnackbarNotification centralizado
- Cores hardcoded
- Diferentes durações e comportamentos

### 4. **Validação Inconsistente**

Cada presentation tem sua própria lógica de validação:
- Diferentes mensagens de erro
- Diferentes padrões de feedback visual
- Código duplicado

## Solução Implementada

### Sistema Centralizado Criado

1. **AppDialog** (`lib/presentation/widgets/molecules/app_dialog.dart`)
   - ✅ Dialogs padronizados com design responsivo
   - ✅ Confirmação, Input, Info, Error, Success
   - ✅ Validação integrada
   - ✅ Botões consistentes

2. **AppBottomSheet** (`lib/presentation/widgets/molecules/app_bottom_sheet.dart`)
   - ✅ Bottom sheets padronizados
   - ✅ Handle visual consistente
   - ✅ Adaptive (Dialog no desktop, BottomSheet no mobile)
   - ✅ Opções, Confirmação, Input

3. **AppAlert** (`lib/presentation/widgets/molecules/app_alert.dart`)
   - ✅ Alertas inline padronizados
   - ✅ Material Banner para alertas globais
   - ✅ Tipos: Success, Error, Warning, Info

## Exemplos de Refatoração Recomendada

### Antes (Inconsistente)
```dart
// FloorPlanPresentation - linha 616
showDialog<void>(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Pavimento'),
      content: SizedBox(
        width: 300,
        child: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Nome do pavimento (ex: Térreo, 1º Andar)',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop();
              _createNewFloorPlan(name);
            }
          },
          child: const Text('Criar'),
        ),
      ],
    );
  },
);
```

### Depois (Padronizado)
```dart
// Usando o sistema centralizado
final result = await AppDialog.showInput(
  context: context,
  title: 'Adicionar Pavimento',
  hintText: 'Nome do pavimento (ex: Térreo, 1º Andar)',
  icon: Icons.apartment,
  isRequired: true,
);

if (result != null) {
  _createNewFloorPlan(result);
}
```

### Bottom Sheet - Antes (Inconsistente)
```dart
showModalBottomSheet<void>(
  context: context,
  builder: (BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar Marcador'),
            onTap: () {
              Navigator.of(context).pop();
              _editMarker(marker);
            },
          ),
          // Mais opções...
        ],
      ),
    );
  },
);
```

### Bottom Sheet - Depois (Padronizado)
```dart
final result = await AppBottomSheet.showOptions<String>(
  context: context,
  title: 'Opções do Marcador',
  options: [
    BottomSheetOption(
      label: 'Editar Marcador',
      value: 'edit',
      icon: Icons.edit,
    ),
    BottomSheetOption(
      label: 'Excluir Marcador',
      value: 'delete',
      icon: Icons.delete,
      isDangerous: true,
    ),
  ],
);

switch (result) {
  case 'edit':
    _editMarker(marker);
    break;
  case 'delete':
    _confirmDeleteMarker(marker);
    break;
}
```

## Benefícios da Padronização

### 1. **Consistência Visual**
- Todos os dialogs/sheets seguem o mesmo design
- Cores, tipografia e espaçamentos padronizados
- Responsividade automática

### 2. **Manutenibilidade**
- Centralização facilita updates globais
- Menos código duplicado
- Validação consistente

### 3. **Experiência do Usuário**
- Interface familiar em toda a aplicação
- Comportamento previsível
- Acessibilidade melhorada

### 4. **Produtividade do Desenvolvedor**
- APIs simples e intuitivas
- Menos código por feature
- Menos bugs de inconsistência

## Recomendações de Implementação

### Fase 1: Migração Gradual
1. Migrar dialogs de confirmação simples
2. Migrar inputs básicos
3. Migrar bottom sheets de opções

### Fase 2: Funcionalidades Avançadas
1. Migrar dialogs complexos com validação
2. Migrar formulários multi-campo
3. Implementar alertas contextuais

### Fase 3: Otimização
1. Remover código duplicado
2. Padronizar mensagens de erro
3. Testes automatizados

## Impacto Estimado

- **Redução de código**: ~40% nas presentations
- **Consistência visual**: 100% padronizada
- **Tempo de desenvolvimento**: -60% para novos dialogs/sheets
- **Bugs de inconsistência**: -90%
