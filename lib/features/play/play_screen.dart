import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/level.dart';
import '../../game/game_controller.dart';
import '../../game/knight_snake_game.dart';
import '../../services/services.dart';
import '../common/widgets.dart';
import '../levels/level_repository.dart';
import 'help_sheet.dart';
import 'hud.dart';
import 'result_card.dart';

/// Plays one level: HUD + Flame board, result card on top when it ends.
/// Portrait: HUD above the board. Landscape: HUD in a side panel.
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.levels,
    required this.index,
    required this.repo,
    required this.services,
  });

  final List<Level> levels;
  final int index;
  final LevelRepository repo;
  final Services services;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late GameController _controller;
  KnightSnakeGame? _game;
  bool _recorded = false;
  bool _newBest = false;

  Level get _level => widget.levels[widget.index];

  bool get _reducedMotion =>
      widget.repo.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _controller = GameController(_level)..addListener(_onChange);
    widget.services.analytics.log('level_start', {'level': _level.id});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= KnightSnakeGame(
      controller: _controller,
      services: widget.services,
      reducedMotion: _reducedMotion,
    );
  }

  void _onChange() {
    final st = _controller.state;
    if (_controller.finaleDone && !_recorded) {
      _recorded = true;
      _newBest = widget.repo.record(
        _level.id,
        score: st.totalScore,
        stars: _controller.stars,
      );
      widget.services.analytics.log(st.isWon ? 'level_win' : 'level_lose', {
        'level': _level.id,
      });
    }
    if (!_controller.finaleDone) _recorded = false;
    setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  void _goTo(int index) => unawaited(
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PlayScreen(
          levels: widget.levels,
          index: index,
          repo: widget.repo,
          services: widget.services,
        ),
      ),
    ),
  );

  Future<void> _undoWithAd() async {
    final ok = await widget.services.ads.showRewarded('undo_crash');
    if (ok && mounted) _controller.undo();
  }

  @override
  Widget build(BuildContext context) {
    final hasNext = widget.index + 1 < widget.levels.length;
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(builder: _layout),
              Positioned(
                left: 8,
                top: 8,
                child: CandyButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back to levels',
                  size: 44,
                  color: const Color(0xFF8E5CF7),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (_controller.finaleDone)
                ColoredBox(
                  color: const Color(0x55000000),
                  child: ResultCard(
                    state: _controller.state,
                    stars: _controller.stars,
                    newBest: _newBest,
                    reducedMotion: _reducedMotion,
                    onRetry: _controller.restart,
                    onLevels: () => Navigator.of(context).pop(),
                    onNext: hasNext ? () => _goTo(widget.index + 1) : null,
                    onUndo: _controller.canUndo ? _undoWithAd : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _layout(BuildContext context, BoxConstraints c) {
    final landscape = c.maxWidth > c.maxHeight * 1.15;
    final hud = Hud(
      controller: _controller,
      onHelp: () => unawaited(showHelpSheet(context, _level)),
    );
    final levelChip = Pill(
      child: Text(
        '${_level.id}',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
    );
    if (landscape) {
      final side = math.min(
        620.0,
        math.min(c.maxHeight - 32, c.maxWidth - 360),
      );
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [levelChip, const SizedBox(height: 16), hud],
            ),
          ),
          const SizedBox(width: 24),
          _board(side),
        ],
      );
    }
    final side = math.min(620.0, math.min(c.maxWidth - 24, c.maxHeight - 190));
    return Column(
      children: [
        const SizedBox(height: 10),
        levelChip,
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: hud,
        ),
        Expanded(child: Center(child: _board(side))),
      ],
    );
  }

  Widget _board(double side) => SizedBox.square(
    dimension: math.max(200, side),
    child: GameWidget(game: _game!),
  );
}
