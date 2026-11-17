import 'package:material_ui/material_ui.dart';

import 'features/levels/level_select_screen.dart';
import 'game/palette.dart';
import 'services/services.dart';

class KnightSnakeApp extends StatelessWidget {
  const KnightSnakeApp({super.key, required this.services});

  final Services services;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Knight Snake',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: Palette.violet,
        onPrimary: Palette.ink,
        secondary: Palette.mint,
        surface: Palette.panel,
        onSurface: Palette.white,
        error: Palette.danger,
      ),
      scaffoldBackgroundColor: Palette.background,
      useMaterial3: true,
    ),
    home: LevelSelectScreen(services: services),
  );
}
