import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/game_state.dart';
import '../../core/scoring.dart';
import '../../game/palette.dart';
import '../common/widgets.dart';

/// End-of-level card. On a win the score is built up step by step
/// (eating points, then +50 per unused move) and the stars pop in one by one.
class ResultCard extends StatefulWidget {
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
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  int _shownBonusMoves = 0;
  int _shownStars = 0;
  bool _showBest = false;
  final List<Timer> _timers = [];

  int get _unused => widget.state.movesLeft ?? 0;

  @override
  void initState() {
    super.initState();
    if (!widget.state.isWon) return;
    final step = widget.reducedMotion ? 60 : 220;
    var t = 500;
    for (var i = 1; i <= _unused; i++) {
      _at(t += step, () => _shownBonusMoves = i);
    }
    for (var s = 1; s <= widget.stars; s++) {
      _at(t += 380, () => _shownStars = s);
    }
    if (widget.newBest) _at(t + 400, () => _showBest = true);
  }

  void _at(int ms, VoidCallback f) => _timers.add(
    Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(f);
    }),
  );

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final won = widget.state.isWon;
    final bonus = _shownBonusMoves * Scoring.perUnusedMove;
    return Center(
      child: Container(
        width: 340,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x44000000), blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (won) _stars() else _lostIcon(),
            const SizedBox(height: 12),
            if (won) ...[
              _line(Icons.restaurant_rounded, '${widget.state.score}'),
              _line(
                Icons.directions_walk_rounded,
                '+${Scoring.perUnusedMove} × $_shownBonusMoves = +$bonus',
              ),
              const Divider(height: 20),
              CountUp(
                widget.state.score + bonus,
                ms: 200,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Palette.ink,
                ),
              ),
              AnimatedOpacity(
                opacity: _showBest ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Text(
                  'NEW BEST!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF0509A),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CandyButton(
                  icon: Icons.grid_view_rounded,
                  tooltip: 'Levels',
                  color: const Color(0xFF14B8A6),
                  onPressed: widget.onLevels,
                ),
                if (!won && widget.onUndo != null)
                  CandyButton(
                    icon: Icons.undo_rounded,
                    tooltip: 'Undo last move (watch a video)',
                    color: const Color(0xFFFB8C2A),
                    onPressed: widget.onUndo,
                  ),
                CandyButton(
                  icon: Icons.replay_rounded,
                  tooltip: 'Play again',
                  color: const Color(0xFFF0509A),
                  onPressed: widget.onRetry,
                ),
                if (won && widget.onNext != null)
                  CandyButton(
                    icon: Icons.arrow_forward_rounded,
                    tooltip: 'Next level',
                    size: 64,
                    color: const Color(0xFF4CC36A),
                    onPressed: widget.onNext,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stars() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 1; i <= 3; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i == 2 ? 14 : 0),
          child: AnimatedScale(
            scale: _shownStars >= i ? 1 : 0.6,
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            child: Icon(
              _shownStars >= i
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: i == 2 ? 72 : 58,
              color: _shownStars >= i ? Palette.star : Palette.starOff,
            ),
          ),
        ),
    ],
  );

  Widget _lostIcon() => Icon(
    widget.state.status == GameStatus.lostTrapped
        ? Icons.block_rounded
        : Icons.hourglass_empty_rounded,
    size: 72,
    color: Palette.danger,
    semanticLabel: widget.state.status == GameStatus.lostTrapped
        ? 'Trapped'
        : 'Out of moves',
  );

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Palette.ink, size: 22),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
