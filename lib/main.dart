import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'services/services.dart';

void main() {
  runApp(KnightSnakeApp(services: Services.dev()));
}
