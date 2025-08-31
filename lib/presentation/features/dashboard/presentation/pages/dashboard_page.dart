import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/components/organisms/presentations/image_carousel_presentation.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dashboard now uses the same presentation system as other pages
    // Shows a carousel with project overview images
    return const ImageCarouselPresentation(
      title: 'Terra Allwert',
      route: '/dashboard',
      description: 'Visão geral do empreendimento',
      images: [
        'https://placehold.co/1200x800/2E7D32/FFFFFF?text=Vista+Aérea+do+Empreendimento',
        'https://placehold.co/1200x800/1976D2/FFFFFF?text=Fachada+Principal',
        'https://placehold.co/1200x800/388E3C/FFFFFF?text=Área+de+Lazer+Completa',
        'https://placehold.co/1200x800/F57C00/FFFFFF?text=Hall+de+Entrada',
        'https://placehold.co/1200x800/7B1FA2/FFFFFF?text=Paisagismo+e+Jardins',
        'https://placehold.co/1200x800/D32F2F/FFFFFF?text=Vista+Noturna',
      ],
    );
  }
}
