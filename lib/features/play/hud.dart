import 'package:material_ui/material_ui.dart';

import '../../core/goal.dart';
import '../../core/piece.dart';
import '../../game/game_controller.dart';
import '../../game/palette.dart';
import '../common/widgets.dart';

/// Top bar: goal progress, moves left, score (counts up) and the star bar.
class Hud extends StatelessWidget {
  const Hud({super.key, required this.controller, required this.onHelp});

  final GameController controller;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final st = controller.state;
      final (done, target) = st.goal.progress(st);
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          Pill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GoalIcon(st.goal),
                const SizedBox(width: 6),
                Text('$done/$target', style: _num),
              ],
            ),
          ),
          Semantics(
            label: 'Moves left',
            child: Pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_walk_rounded, color: Palette.ink),
                  const SizedBox(width: 4),
                  Text('${st.movesLeft ?? '∞'}', style: _num),
                ],
              ),
            ),
          ),
          Pill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountUp(st.totalScore, style: _num.copyWith(fontSize: 22)),
                const SizedBox(width: 10),
                StarBar(
                  progress: controller.starProgress,
                  twoStarAt: controller.level.stars[1] == 0
                      ? 0.66
                      : controller.level.stars[0] / controller.level.stars[1],
                  won: st.isWon,
                ),
              ],
            ),
          ),
          CandyButton(
            icon: Icons.question_mark_rounded,
            tooltip: 'How scoring works',
            size: 40,
            color: const Color(0xFF14B8A6),
            onPressed: onHelp,
          ),
        ],
      );
    },
  );
}

const _num = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w900,
  color: Palette.ink,
);

/// Icon for a goal type, so the goal reads without text.
class GoalIcon extends StatelessWidget {
  const GoalIcon(this.goal, {super.key, this.size = 28});
  final Goal goal;
  final double size;

  @override
  Widget build(BuildContext context) => switch (goal) {
    EatAllGoal() || EatCountGoal() => PieceIcon(PieceType.pawn, size: size),
    EatPiecesGoal(:final pieces) => PieceIcon(pieces.keys.first, size: size),
    LengthGoal() => Icon(
      Icons.straighten_rounded,
      size: size,
      color: Palette.head(PieceType.pawn),
    ),
    ReachExitGoal() => Icon(
      Icons.flag_rounded,
      size: size,
      color: Palette.danger,
    ),
  };
}

/// Three stars over a bar that fills toward the 3-star score.
/// Star 1 lights only on a win (GAME_PLAN §3).
class StarBar extends StatelessWidget {
  const StarBar({
    super.key,
    required this.progress,
    required this.twoStarAt,
    required this.won,
  });

  final double progress;
  final double twoStarAt;
  final bool won;

  @override
  Widget build(BuildContext context) {
    const width = 96.0;
    return Semantics(
      label: 'Star progress',
      value: '${(progress * 100).round()}%',
      child: SizedBox(
        width: width,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 500),
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: Palette.starOff,
                    color: Palette.star,
                  ),
                ),
              ),
            ),
            _star(0, won),
            _star(twoStarAt * width - 10, won && progress >= twoStarAt),
            _star(width - 20, won && progress >= 1),
          ],
        ),
      ),
    );
  }

  Widget _star(double left, bool lit) => Positioned(
    left: left.clamp(0, 76),
    top: 0,
    child: AnimatedScale(
      scale: lit ? 1.25 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: Icon(
        lit ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 22,
        color: lit ? Palette.star : Palette.ink.withValues(alpha: 0.35),
      ),
    ),
  );
}
