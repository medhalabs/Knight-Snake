import 'package:material_ui/material_ui.dart';

import '../../core/goal.dart';
import '../../core/piece.dart';
import '../../core/scoring.dart';
import '../../game/game_controller.dart';
import '../../game/palette.dart';
import '../common/widgets.dart';

class Hud extends StatelessWidget {
  const Hud({super.key, required this.controller, required this.reducedMotion});

  final GameController controller;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final st = controller.state;
    final (done, target) = st.goal.progress(st);
    final head = st.snake.head;
    final multiplier = Scoring.multiplier(st.streak);
    final combo = multiplier > 1;
    final goal = switch (st.goal) {
      EatAllGoal() => 'Capture every piece',
      EatCountGoal() => 'Capture $target pieces',
      EatPiecesGoal(:final pieces) =>
        pieces.entries
            .map((e) => '${e.key.name} ${st.eaten[e.key] ?? 0}/${e.value}')
            .join(' · '),
      LengthGoal() => 'Grow to length $target',
      ReachExitGoal() => 'Reach the exit',
    };
    final tutorial = switch (controller.level.tutorial) {
      'tapDot' when st.movesUsed == 0 =>
        'Tap a glowing square to make your move.',
      'chain' => 'Capture pieces in a row to build a combo.',
      'eatChange' => 'Capture a bishop to move diagonally.',
      'rocks' => 'Knights jump over rocks. Sliding pieces stop at them.',
      'body' => 'You can land on your tail as it moves away.',
      _ => switch (head) {
        PieceType.knight => 'Knights jump in an L shape.',
        PieceType.bishop => 'Bishops slide diagonally.',
        PieceType.rook => 'Rooks slide horizontally or vertically.',
        PieceType.queen => 'Queens slide in any direction.',
        PieceType.king => 'Kings move one square in any direction.',
        PieceType.pawn => '',
      },
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'LEVEL ${controller.level.id.toString().padLeft(2, '0')}',
          style: arcadeLabel.copyWith(color: Palette.violet),
        ),
        const SizedBox(height: 4),
        Text(
          controller.level.name,
          style: const TextStyle(
            fontSize: 30,
            height: 1.06,
            letterSpacing: -0.85,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_rounded, color: Palette.mint, size: 16),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      goal,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${done.clamp(0, target)} / $target',
                    style: arcadeLabel.copyWith(
                      color: Palette.mint,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _Meter(
                value: target == 0 ? 1 : done / target,
                color: Palette.mint,
                label: 'Objective progress',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _Panel(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'SCORE',
                      child: CountUp(
                        st.totalScore,
                        style: arcadeNumber,
                        reducedMotion: reducedMotion,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'MOVES LEFT',
                      child: Text(
                        '${st.movesLeft ?? '∞'}',
                        style: arcadeNumber.copyWith(
                          color: st.movesLeft == 1
                              ? Palette.danger
                              : Palette.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'COMBO',
                      child: Text(
                        '×$multiplier',
                        style: arcadeNumber.copyWith(
                          color: combo ? Palette.star : Palette.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 1; i <= 3; i++)
                    Icon(
                      i <= controller.stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 13,
                      color: i <= controller.stars
                          ? Palette.star
                          : Palette.starOff,
                    ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _Meter(
                      value: controller.starProgress,
                      color: Palette.star,
                      label: 'Progress toward three stars',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            PieceIcon(head, size: 36, asHead: true),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                tutorial,
                style: const TextStyle(
                  color: Palette.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xD21D1730),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: Palette.line),
    ),
    child: child,
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: arcadeLabel.copyWith(fontSize: 9, letterSpacing: 0.7)),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: child,
      ),
    ],
  );
}

class _Meter extends StatelessWidget {
  const _Meter({required this.value, required this.color, required this.label});
  final double value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
    semanticsLabel: label,
    value: value.clamp(0.0, 1.0),
    minHeight: 4,
    color: color,
    backgroundColor: Palette.line,
    borderRadius: const BorderRadius.all(Radius.circular(6)),
  );
}
