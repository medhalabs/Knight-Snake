# CLAUDE.md — Knight Snake

Original chess × snake puzzle game (Flutter + Flame). Solo developer, audience
kids to adults. Read `docs/GAME_PLAN.md` (rules) and `docs/ARCHITECTURE.md`
before changing code.

## Hard rules
- `lib/core` is pure Dart: no `flutter`, `flame`, `dart:io`, `dart:ui`,
  `dart:html` imports. Deterministic; all randomness via `XorShift32`.
  `test/core/purity_test.dart` enforces this.
- Flame components and widgets only render state and send moves.
- Material widgets: `import 'package:material_ui/material_ui.dart';`
  never `package:flutter/material.dart` (deprecated).
- A rule change updates `docs/GAME_PLAN.md` (incl. its change log), tests and
  code in the same change.
- Every level follows Plan → Document → Build → Test (`docs/levels/README.md`).
  Star scores come from the solver.
- Original art only, drawn in code with vector paths. No font glyphs for pieces.
- Kid safety: no tracking for under-13, parent gate on purchases, no loot boxes
  or fake timers.
- Keep files ~300 lines; split when larger.
- Ask the user before anything outward-facing: creating accounts, pushing,
  publishing, downloading third-party assets.

## Commands
```bash
flutter pub get
dart format .
flutter analyze
flutter test
dart run tool/level_solver.dart assets/levels/level_001.json
flutter run -d chrome
flutter build web && dart run tool/serve_web.dart   # http://localhost:8080
```

## Layout
`lib/core` logic · `lib/game` Flame · `lib/features` screens ·
`lib/services` interfaces + fakes · `assets/levels` JSON · `test/` mirrors
`lib/core` · `tool/` CLIs · `docs/` plans.
