import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/organisms/first_menu_instruction.dart';
import '../../../../widgets/organisms/presentations/image_carousel_presentation.dart';
import '../../../navigation/providers/navigation_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNoMenus = ref.watch(hasNoMenusConfiguredProvider);

    // Se não há menus configurados, mostra tela de instruções
    if (hasNoMenus) {
      return const Scaffold(body: FirstMenuInstruction());
    }

    // Dashboard normal com carousel quando há menus configurados
    return const ImageCarouselPresentation(
      title: 'Terra Allwert',
      route: '/dashboard',
      description: 'Visão geral do empreendimento',
      images: [],
    );
  }
}
