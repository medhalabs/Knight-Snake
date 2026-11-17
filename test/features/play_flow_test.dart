import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightsnake/app.dart';
import 'package:knightsnake/core/square.dart';
import 'package:knightsnake/features/play/result_card.dart';
import 'package:knightsnake/game/knight_snake_game.dart';
import 'package:knightsnake/services/services.dart';

/// Screenshots are written only with `--dart-define=SCREENSHOTS=true`
/// (goldens differ per OS, so CI never compares them).
const _shots = bool.fromEnvironment('SCREENSHOTS');

final _board = find.byWidgetPredicate((w) => w is GameWidget);

Future<void> _frames(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 16; i++) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _shot(WidgetTester t, String name) async {
  if (!_shots) return;
  await expectLater(
    find.byType(KnightSnakeApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

Offset _squareCenter(WidgetTester t, String square) {
  final rect = t.getRect(_board);
  final side = rect.shortestSide;
  final s = Square.parse(square);
  return rect.topLeft +
      Offset((s.file + 0.5) * side / 8, (7 - s.rank + 0.5) * side / 8);
}

Future<void> _openFirstLevel(WidgetTester t, {String? homeShot}) async {
  await t.pumpWidget(KnightSnakeApp(services: Services.fake()));
  final level1 = find.bySemanticsLabel(RegExp('^Level 1,'));
  for (var i = 0; i < 50 && level1.evaluate().isEmpty; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump();
  }
  await _frames(t, 300);
  if (homeShot != null) await _shot(t, homeShot);
  await t.tap(level1);
  await _frames(t, 800);
}

void main() {
  // rootBundle caches futures; one from a previous test's fake clock never
  // completes in the next test.
  setUp(rootBundle.clear);

  for (final (name, size) in [
    ('phone', const Size(390, 844)),
    ('landscape', const Size(1280, 800)),
  ]) {
    testWidgets('level 1 can be won ($name)', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      await _openFirstLevel(t, homeShot: '${name}_home');
      expect(_board, findsOneWidget);
      await _shot(t, '${name}_level1');

      await t.tapAt(_squareCenter(t, 'c3'));
      await _frames(t, 360);
      await _shot(t, '${name}_eat');
      await _frames(t, 2000);
      expect(find.byType(ResultCard), findsOneWidget);
      await _frames(t, 2500);
      await _shot(t, '${name}_result');
    });
  }

  testWidgets('drag starts at the head and restart cancels the pending win', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await _openFirstLevel(t);
    final controller = t
        .widget<GameWidget<KnightSnakeGame>>(_board)
        .game!
        .controller;
    final target = _squareCenter(t, 'c3');
    final empty = _squareCenter(t, 'd4');
    await t.dragFrom(empty, target - empty);
    await _frames(t, 350);
    expect(controller.state.movesUsed, 0);

    final head = _squareCenter(t, 'b1');
    final cancelled = await t.startGesture(head);
    await cancelled.moveTo(target);
    await cancelled.cancel();
    await _frames(t, 350);
    expect(controller.state.movesUsed, 0);

    await t.tapAt(target);
    await _frames(t, 48);
    expect(controller.busy, isTrue);
    await t.tap(find.byTooltip('Restart level'));
    await _frames(t, 1500);
    expect(controller.state.movesUsed, 0);
    expect(controller.busy, isFalse);
    expect(find.byType(ResultCard), findsNothing);

    await t.dragFrom(head, target - head);
    await _frames(t, 1500);
    expect(controller.state.isWon, isTrue);
    expect(find.byType(ResultCard), findsOneWidget);
  });
}
