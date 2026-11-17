// Serves build/web locally (no Python needed).
//
//   flutter build web
//   dart run tool/serve_web.dart [--port 8080] [--dir build/web]
// ignore_for_file: avoid_print
import 'dart:io';

const _types = {
  'html': 'text/html; charset=utf-8',
  'js': 'application/javascript',
  'mjs': 'application/javascript',
  'json': 'application/json',
  'css': 'text/css',
  'wasm': 'application/wasm',
  'png': 'image/png',
  'ico': 'image/x-icon',
  'svg': 'image/svg+xml',
  'ttf': 'font/ttf',
  'otf': 'font/otf',
  'woff2': 'font/woff2',
  'map': 'application/json',
};

Future<void> main(List<String> args) async {
  String opt(String name, String fallback) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
  }

  final port = int.parse(opt('--port', '8080'));
  final root = Directory(opt('--dir', 'build/web')).absolute;
  if (!root.existsSync()) {
    stderr.writeln('${root.path} not found. Run `flutter build web` first.');
    exitCode = 66;
    return;
  }
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('Serving ${root.path} at http://localhost:$port');
  await for (final req in server) {
    await _handle(req, root);
  }
}

Future<void> _handle(HttpRequest req, Directory root) async {
  final res = req.response;
  var path = Uri.decodeComponent(req.uri.path);
  if (path.endsWith('/')) path += 'index.html';
  final file = File('${root.path}$path');
  // Block path traversal outside the web root.
  final inside = file.absolute.path.startsWith(root.path);
  final target = inside && file.existsSync()
      ? file
      : File('${root.path}/index.html');
  final ext = target.path.split('.').last.toLowerCase();
  res.headers
    ..set(
      HttpHeaders.contentTypeHeader,
      _types[ext] ?? 'application/octet-stream',
    )
    ..set(HttpHeaders.cacheControlHeader, 'no-cache');
  await res.addStream(target.openRead());
  await res.close();
}
