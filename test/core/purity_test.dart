import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// lib/core must stay pure Dart (docs/ARCHITECTURE.md "The core rule").
void main() {
  test('lib/core imports no Flutter, Flame, dart:io, dart:ui, dart:html', () {
    final forbidden = RegExp(
      r'''import\s+['"](package:flutter|package:flame|package:material_ui|dart:io|dart:ui|dart:html|dart:js)''',
    );
    final files = Directory('lib/core')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final f in files) {
      expect(
        forbidden.hasMatch(f.readAsStringSync()),
        isFalse,
        reason: '${f.path} imports a forbidden library',
      );
    }
  });

  test('lib/core uses no dart:math Random (use XorShift32)', () {
    for (final f in Directory('lib/core').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) {
        expect(
          f.readAsStringSync().contains('Random('),
          isFalse,
          reason: f.path,
        );
      }
    }
  });
}
