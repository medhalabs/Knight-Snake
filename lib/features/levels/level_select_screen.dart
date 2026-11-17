import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/level.dart';
import '../../core/piece.dart';
import '../../game/palette.dart';
import '../../services/services.dart';
import '../common/widgets.dart';
import '../play/play_screen.dart';
import 'level_repository.dart';

/// Home: title art and a grid of level buttons with earned stars.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key, required this.services});
  final Services services;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late final LevelRepository _repo = LevelRepository(widget.services.storage);
  late final Future<List<Level>> _levels = _repo.loadAll();

  Future<void> _open(List<Level> levels, int i) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayScreen(
          levels: levels,
          index: i,
          repo: _repo,
          services: widget.services,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SkyBackground(
      child: SafeArea(
        child: FutureBuilder<List<Level>>(
          future: _levels,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            final levels = snap.data;
            if (levels == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CandyButton(
                      icon: _repo.reducedMotion
                          ? Icons.motion_photos_off_rounded
                          : Icons.animation_rounded,
                      tooltip: 'Reduce motion',
                      size: 44,
                      color: _repo.reducedMotion
                          ? Palette.ink
                          : const Color(0xFF14B8A6),
                      onPressed: () => setState(
                        () => _repo.reducedMotion = !_repo.reducedMotion,
                      ),
                    ),
                  ),
                ),
                const _Title(),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: GridView.count(
                        padding: const EdgeInsets.all(16),
                        crossAxisCount: 5,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        children: [
                          for (var i = 0; i < levels.length; i++)
                            _LevelButton(
                              id: levels[i].id,
                              stars: _repo.stars(levels[i].id),
                              unlocked: _repo.isUnlocked(levels[i].id),
                              onTap: () => unawaited(_open(levels, i)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PieceIcon(PieceType.knight, size: 64, asHead: true),
          SizedBox(width: 4),
          PieceIcon(PieceType.bishop, size: 44, asHead: true),
          PieceIcon(PieceType.rook, size: 36, asHead: true),
          PieceIcon(PieceType.queen, size: 30, asHead: true),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'KNIGHT SNAKE',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: Palette.head(PieceType.knight),
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 0, offset: Offset(0, 3)),
          ],
        ),
      ),
    ],
  );
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({
    required this.id,
    required this.stars,
    required this.unlocked,
    required this.onTap,
  });

  final int id;
  final int stars;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Level $id, $stars stars${unlocked ? '' : ', locked'}',
    child: Material(
      color: unlocked ? Colors.white : Colors.white.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      elevation: unlocked ? 3 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: unlocked ? onTap : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (unlocked)
              Text(
                '$id',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Palette.ink,
                ),
              )
            else
              const Icon(Icons.lock_rounded, color: Palette.starOff, size: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var s = 1; s <= 3; s++)
                  Icon(
                    s <= stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: s <= stars ? Palette.star : Palette.starOff,
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
