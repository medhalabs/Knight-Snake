import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightsnake/app.dart';
import 'package:knightsnake/features/play/result_card.dart';
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

/// Taps the center of [square] ("c3") on the Flame board.
Future<void> _tapSquare(WidgetTester t, String square) async {
  final rect = t.getRect(_board);
  final side = rect.shortestSide;
  final f = square.codeUnitAt(0) - 0x61;
  final r = square.codeUnitAt(1) - 0x31;
  await t.tapAt(
    rect.topLeft + Offset((f + 0.5) * side / 8, (7 - r + 0.5) * side / 8),
  );
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
      await t.pumpWidget(KnightSnakeApp(services: Services.fake()));
      final level1 = find.bySemanticsLabel(RegExp('^Level 1,'));
      for (var i = 0; i < 50 && level1.evaluate().isEmpty; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump();
      }
      await _frames(t, 300);
      await _shot(t, '${name}_home');

      await t.tap(level1);
      await _frames(t, 800);
      expect(_board, findsOneWidget);
      await _shot(t, '${name}_level1');

      await _tapSquare(t, 'c3');
      await _frames(t, 200);
      await _shot(t, '${name}_eat');
      await _frames(t, 2000);
      expect(find.byType(ResultCard), findsOneWidget);
      await _frames(t, 2500);
      await _shot(t, '${name}_result');
    });
  }
}
