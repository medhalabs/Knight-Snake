import 'package:material_ui/material_ui.dart';

import '../../core/level.dart';
import '../../core/piece.dart';
import '../../core/scoring.dart';
import '../../game/palette.dart';
import '../common/widgets.dart';

Future<void> showHelpSheet(BuildContext context, Level level) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.panel,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _HelpSheet(level),
    );

class _HelpSheet extends StatelessWidget {
  const _HelpSheet(this.level);
  final Level level;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How to play',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const _Rule(
            Icons.touch_app_rounded,
            'Tap a glowing square or drag your head onto it.',
          ),
          const _Rule(
            Icons.swap_calls_rounded,
            'Capturing changes your head to that piece. Pawns only make you grow.',
          ),
          const _Rule(
            Icons.bolt_rounded,
            'Captures in a row build a combo up to ×${Scoring.maxCombo}.',
          ),
          const _Rule(
            Icons.timer_outlined,
            'Win with moves left to earn +${Scoring.perUnusedMove} per unused move.',
          ),
          const Divider(height: 26, color: Palette.line),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final p in PieceType.values)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PieceIcon(p, size: 38),
                    Text(
                      '+${p.points}',
                      style: arcadeLabel.copyWith(letterSpacing: 0),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final (stars, goal) in [
                (1, 'Clear level'),
                (2, '${level.stars[0]} points'),
                (3, '${level.stars[1]} points'),
              ])
                Text(
                  '${'★' * stars}  $goal',
                  style: const TextStyle(
                    color: Palette.star,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Rule extends StatelessWidget {
  const _Rule(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, color: Palette.violet, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Palette.muted)),
        ),
      ],
    ),
  );
}
