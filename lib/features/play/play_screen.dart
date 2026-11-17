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
  final _boardKey = GlobalKey();
  late final GameController _controller;
  KnightSnakeGame? _game;
  bool _recorded = false;
  bool _newBest = false;
  bool _undoPending = false;

  Level get _level => widget.levels[widget.index];

  bool get _reducedMotion =>
      widget.repo.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _controller = GameController(_level)..addListener(_onChange);
    widget.services.analytics.log('level_start', {'level': _level.id});
    _recordResult();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= KnightSnakeGame(
      controller: _controller,
      services: widget.services,
    );
    _game!.reducedMotion = _reducedMotion;
  }

  void _recordResult() {
    if (!_controller.finaleDone) {
      _recorded = false;
      return;
    }
    if (_recorded) return;
    _recorded = true;
    final st = _controller.state;
    _newBest = widget.repo.record(
      _level.id,
      score: st.totalScore,
      stars: _controller.stars,
    );
    widget.services.analytics.log(st.isWon ? 'level_win' : 'level_lose', {
      'level': _level.id,
    });
  }

  void _onChange() {
    _recordResult();
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
    if (_undoPending) return;
    final attempt = _controller.state;
    setState(() => _undoPending = true);
    try {
      final ok = await widget.services.ads.showRewarded('undo_crash');
      if (ok && mounted && identical(attempt, _controller.state)) {
        _controller.undo();
      }
    } finally {
      if (mounted) setState(() => _undoPending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNext = widget.index + 1 < widget.levels.length;
    final safe = SafeArea(child: LayoutBuilder(builder: _layout));
    return Scaffold(
      body: ArcadeBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(excluding: _controller.finaleDone, child: safe),
            if (_controller.finaleDone)
              ColoredBox(
                color: const Color(0xCA0C0816),
                child: SafeArea(
                  child: ResultCard(
                    key: ObjectKey(_controller.state),
                    state: _controller.state,
                    stars: _controller.stars,
                    newBest: _newBest,
                    reducedMotion: _reducedMotion,
                    onRetry: _controller.restart,
                    onLevels: () => Navigator.of(context).pop(),
                    onNext: hasNext ? () => _goTo(widget.index + 1) : null,
                    onUndo: _controller.canUndo && !_undoPending
                        ? _undoWithAd
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _layout(BuildContext context, BoxConstraints c) {
    final landscape = c.maxWidth >= 480 && c.maxWidth > c.maxHeight * 1.16;
    final padding = c.maxWidth >= 720 ? 24.0 : 12.0;
    final width = math.min(c.maxWidth - padding * 2, 1080.0);
    final hud = Hud(controller: _controller, reducedMotion: _reducedMotion);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
      child: Center(
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              _toolbar(context),
              const SizedBox(height: 8),
              Expanded(
                child: landscape
                    ? _landscape(hud, width)
                    : _portrait(hud, width),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbar(BuildContext context) => Row(
    children: [
      ArcadeIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: 'Back to levels',
        onPressed: () => Navigator.of(context).pop(),
      ),
      const SizedBox(width: 10),
      const Expanded(child: Text('KNIGHT SNAKE', style: arcadeLabel)),
      ArcadeIconButton(
        icon: Icons.restart_alt_rounded,
        tooltip: 'Restart level',
        onPressed: _controller.state.movesUsed > 0 ? _controller.restart : null,
      ),
      const SizedBox(width: 8),
      ArcadeIconButton(
        icon: Icons.help_outline_rounded,
        tooltip: 'How to play',
        onPressed: () => unawaited(showHelpSheet(context, _level)),
      ),
    ],
  );

  Widget _landscape(Hud hud, double width) => LayoutBuilder(
    builder: (context, c) {
      final sidebar = (width * 0.35).clamp(186.0, 326.0);
      const gap = 20.0;
      final board = math.min(
        620.0,
        math.min(c.maxHeight - 2, width - sidebar - gap),
      );
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: sidebar,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: hud,
              ),
            ),
          ),
          const SizedBox(width: gap),
          _board(board),
        ],
      );
    },
  );

  Widget _portrait(Hud hud, double width) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: math.min(width, 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hud,
              const SizedBox(height: 12),
              _board(
                math.min(
                  width,
                  math.min(620, math.max(240, c.maxHeight - 252)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _board(double side) => Center(
    child: Container(
      width: math.max(24, side),
      height: math.max(24, side),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF492F69), Color(0xFF19122C), Color(0xFF35204D)],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF715596)),
        boxShadow: const [
          BoxShadow(color: Color(0x80432C68), blurRadius: 32),
          BoxShadow(
            color: Color(0x660A0711),
            offset: Offset(0, 12),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GameWidget(key: _boardKey, game: _game!),
      ),
    ),
  );
}
