import 'package:material_ui/material_ui.dart';

import '../../core/game_state.dart';
import '../../game/palette.dart';
import '../common/widgets.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.state,
    required this.stars,
    required this.newBest,
    required this.onRetry,
    required this.onNext,
    required this.onLevels,
    required this.onUndo,
    required this.reducedMotion,
  });

  final GameState state;
  final int stars;
  final bool newBest;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final VoidCallback onLevels;
  final VoidCallback? onUndo;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final won = state.isWon;
    final accent = won ? Palette.star : Palette.danger;
    final title = won
        ? 'Level cleared'
        : (state.status == GameStatus.lostTrapped ? 'Trapped' : 'Out of moves');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: 368,
          padding: const EdgeInsets.fromLTRB(20, 21, 20, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF322449), Color(0xFF1B152D)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.52)),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.14), blurRadius: 44),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!won)
                Icon(
                  state.status == GameStatus.lostTrapped
                      ? Icons.block_rounded
                      : Icons.hourglass_empty_rounded,
                  size: 34,
                  color: accent,
                ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              if (won)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 1120),
                  builder: (context, progress, _) => _celebration(progress),
                )
              else ...[
                const SizedBox(height: 8),
                Text(
                  state.status == GameStatus.lostTrapped
                      ? 'Your head has no legal moves left.'
                      : 'The move limit ran out before you reached the goal.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Palette.muted),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: won && onNext != null ? onNext : onRetry,
                icon: Icon(
                  won && onNext != null
                      ? Icons.arrow_forward_rounded
                      : Icons.replay_rounded,
                ),
                label: Text(
                  won && onNext != null ? 'Next level' : 'Play again',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  backgroundColor: won ? Palette.mint : Palette.violet,
                  foregroundColor: Palette.ink,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  TextButton(onPressed: onLevels, child: const Text('Levels')),
                  if (won && onNext != null)
                    TextButton(onPressed: onRetry, child: const Text('Replay')),
                  if (!won && onUndo != null)
                    TextButton(
                      onPressed: onUndo,
                      child: const Text('Undo with video'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _celebration(double progress) {
    final fill = Curves.easeOut.transform((progress * 1.7).clamp(0.0, 1.0));
    final bonus = (state.bonus * fill).round();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [for (var i = 1; i <= 3; i++) _star(i, progress)],
        ),
        Text(
          '${state.score + bonus}',
          style: arcadeNumber.copyWith(fontSize: 48, height: 1.1),
        ),
        const SizedBox(height: 3),
        Text(
          '${state.score} capture points  +  $bonus move bonus',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Palette.muted, fontSize: 12),
        ),
        if (newBest)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'NEW PERSONAL BEST',
              style: arcadeLabel.copyWith(color: Palette.mint),
            ),
          ),
      ],
    );
  }

  Widget _star(int index, double progress) {
    final reveal = ((progress - (index - 1) * 0.22) * 3.3).clamp(0.0, 1.0);
    final lit = index <= stars && reveal > 0;
    return Transform.scale(
      scale: lit ? 0.55 + 0.45 * Curves.easeOutBack.transform(reveal) : 1,
      child: Icon(
        lit ? Icons.star_rounded : Icons.star_outline_rounded,
        size: index == 2 ? 57 : 43,
        color: lit ? Palette.star : Palette.starOff,
        shadows: lit
            ? const [Shadow(color: Color(0x90FFB859), blurRadius: 16)]
            : null,
      ),
    );
  }
}
