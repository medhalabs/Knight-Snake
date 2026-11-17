# Knight Snake

An original 2D mobile puzzle game: **chess × snake**. You are a snake on an 8×8
chess board. Your head moves like a chess piece. Eat a piece and your head
becomes that piece, and your body grows by one. Don't bite yourself!

Flutter + Flame · Android, iOS, web · for kids and adults.

## Docs
- [Game plan](docs/GAME_PLAN.md): rules, scoring, modes, look, monetization, release plan
- [Architecture](docs/ARCHITECTURE.md)
- [Levels](docs/levels/README.md): workflow, JSON format, 30-level roadmap

## Run
```bash
flutter pub get
flutter run -d chrome
```

## Test
```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Level solver
```bash
dart run tool/level_solver.dart assets/levels/level_001.json
```
Prints win/no-win, best score, best line and a random-bot win rate.

## Web preview of a release build
```bash
flutter build web
dart run tool/serve_web.dart
```
Then open http://localhost:8080.
