import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/components/organisms/presentations/pin_map_presentation.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Home now uses the same presentation system as other pages
    // Shows a carousel with project overview images
    return const PinMapPresentation();
  }
}
