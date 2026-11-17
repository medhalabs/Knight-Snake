import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/level.dart';
import '../../game/palette.dart';
import '../../services/services.dart';
import '../common/widgets.dart';
import '../play/play_screen.dart';
import 'hero_art.dart';
import 'level_repository.dart';

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
    body: ArcadeBackground(
      child: SafeArea(
        child: FutureBuilder<List<Level>>(
          future: _levels,
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('Could not load levels'));
            }
            final levels = snap.data;
            if (levels == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 850;
                final campaign = _campaign(levels);
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 36 : 20,
                    14,
                    wide ? 36 : 20,
                    24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(),
                          SizedBox(
                            height: wide
                                ? (c.maxHeight * 0.075).clamp(28, 88)
                                : 12,
                          ),
                          if (wide)
                            Row(
                              children: [
                                const Expanded(
                                  flex: 11,
                                  child: _Title(wide: true),
                                ),
                                const SizedBox(width: 52),
                                Expanded(flex: 9, child: campaign),
                              ],
                            )
                          else ...[
                            const _Title(wide: false),
                            const SizedBox(height: 22),
                            campaign,
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );

  Widget _header() => Row(
    children: [
      const Expanded(child: Text('CHESS × SNAKE', style: arcadeLabel)),
      Semantics(
        toggled: _repo.reducedMotion,
        child: ArcadeIconButton(
          icon: _repo.reducedMotion
              ? Icons.motion_photos_off_rounded
              : Icons.animation_rounded,
          tooltip: _repo.reducedMotion ? 'Enable motion' : 'Reduce motion',
          onPressed: () =>
              setState(() => _repo.reducedMotion = !_repo.reducedMotion),
        ),
      ),
    ],
  );

  Widget _campaign(List<Level> levels) {
    final earned = levels.fold(
      0,
      (total, level) => total + _repo.stars(level.id),
    );
    final next = levels.indexWhere(
      (level) => _repo.isUnlocked(level.id) && _repo.stars(level.id) == 0,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.panelLight, Palette.panel],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38080513),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Campaign',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                const Icon(Icons.star_rounded, color: Palette.star, size: 19),
                const SizedBox(width: 5),
                Text(
                  '$earned / ${levels.length * 3}',
                  style: arcadeLabel.copyWith(color: Palette.star),
                ),
              ],
            ),
          ),
          for (var i = 0; i < levels.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == levels.length - 1 ? 0 : 8),
              child: _LevelButton(
                level: levels[i],
                stars: _repo.stars(levels[i].id),
                unlocked: _repo.isUnlocked(levels[i].id),
                featured: i == next,
                onTap: () => unawaited(_open(levels, i)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final title = TextStyle(
      fontSize: wide ? 76 : 46,
      height: wide ? 1 : 0.92,
      letterSpacing: wide ? -4.6 : -2.8,
      fontWeight: FontWeight.w900,
      color: Palette.white,
    );
    return Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              text: wide ? 'Knight\n' : 'Knight ',
              children: [
                TextSpan(
                  text: 'Snake',
                  style: title.copyWith(color: Palette.violet),
                ),
              ],
            ),
            style: title,
            semanticsLabel: 'Knight Snake',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Capture pieces. Grow your snake.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Palette.muted,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: wide ? 22 : 10),
        SizedBox(
          width: wide ? 510 : 360,
          height: wide ? 304 : 148,
          child: const CustomPaint(painter: HeroArt()),
        ),
      ],
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.featured,
    required this.onTap,
  });

  final Level level;
  final int stars;
  final bool unlocked;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      enabled: unlocked,
      label:
          'Level ${level.id}, $stars stars, ${level.name}${unlocked ? '' : ', locked'}',
      excludeSemantics: true,
      onTap: unlocked ? onTap : null,
      child: Material(
        color: featured ? const Color(0xFF382656) : const Color(0xFF201A34),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: featured ? const Color(0xFF9F75EA) : Palette.line,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: unlocked ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Container(
                  alignment: Alignment.center,
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: featured ? Palette.violet : Palette.panelLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    level.id.toString().padLeft(2, '0'),
                    style: arcadeLabel.copyWith(
                      fontSize: 13,
                      letterSpacing: 0.4,
                      color: featured ? Palette.ink : Palette.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    level.name,
                    style: TextStyle(
                      color: unlocked ? Palette.white : Palette.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (unlocked) ...[
                  for (var i = 0; i < 3; i++)
                    Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: i < stars ? Palette.star : Palette.starOff,
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.play_arrow_rounded,
                    color: featured ? Palette.mint : Palette.muted,
                    size: 23,
                  ),
                ] else
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Palette.starOff,
                    size: 17,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
