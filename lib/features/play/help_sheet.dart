import 'package:material_ui/material_ui.dart';

import '../../core/level.dart';
import '../../core/piece.dart';
import '../../core/scoring.dart';
import '../../game/palette.dart';
import '../common/widgets.dart';

/// The "?" sheet: how scoring works and this level's star scores.
Future<void> showHelpSheet(BuildContext context, Level level) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (_) => _HelpSheet(level),
    );

class _HelpSheet extends StatelessWidget {
  const _HelpSheet(this.level);
  final Level level;

  static const _bold = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Palette.ink,
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              for (final p in PieceType.values)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PieceIcon(p, size: 40),
                    Text('+${p.points}', style: _bold),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          const _Row(
            icon: Icons.bolt_rounded,
            color: Color(0xFFF0509A),
            text: 'Eat on moves in a row: COMBO ×2, ×3 … up to ×5',
          ),
          const _Row(
            icon: Icons.directions_walk_rounded,
            color: Palette.ink,
            text: '+${Scoring.perUnusedMove} for every move you did not use',
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (n, score) in [
                (1, null),
                (2, level.stars[0]),
                (3, level.stars[1]),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < n; i++)
                            const Icon(Icons.star_rounded, color: Palette.star),
                        ],
                      ),
                      if (score == null)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4CC36A),
                        )
                      else
                        Text('$score', style: _bold),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, color: Palette.ink),
          ),
        ),
      ],
    ),
  );
}
