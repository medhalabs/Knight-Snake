import 'package:material_ui/material_ui.dart';

import 'features/levels/level_select_screen.dart';
import 'services/services.dart';

class KnightSnakeApp extends StatelessWidget {
  const KnightSnakeApp({super.key, required this.services});

  final Services services;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Knight Snake',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8E5CF7)),
      useMaterial3: true,
    ),
    home: LevelSelectScreen(services: services),
  );
}
