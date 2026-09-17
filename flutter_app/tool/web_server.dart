// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  const port = 8080;
  final currentDir = Directory.current.path;
  final webPath = currentDir.endsWith('flutter_app')
      ? 'build/web'
      : 'flutter_app/build/web';

  final webDir = Directory(webPath);
  if (!webDir.existsSync()) {
    print('Error: Directory $webPath does not exist.');
    exit(1);
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('====================================================');
  print(' Siaka Phones Web Server running!');
  print(' Local Wi-Fi Access: http://192.168.1.167:$port');
  print(' Localhost Access:    http://localhost:$port');
  print('====================================================');

  await for (HttpRequest request in server) {
    try {
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', '*');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        continue;
      }

      var reqPath = request.uri.path;
      if (reqPath.startsWith('/')) {
        reqPath = reqPath.substring(1);
      }
      if (reqPath.isEmpty) {
        reqPath = 'index.html';
      }

      var filePath = '${webDir.path}/$reqPath';
      var targetFile = File(filePath);

      if (!await targetFile.exists() && !reqPath.contains('.')) {
        targetFile = File('${webDir.path}/index.html');
      }

      if (await targetFile.exists()) {
        final ext = targetFile.path.split('.').last.toLowerCase();
        final contentType = switch (ext) {
          'html' => ContentType.html,
          'js' || 'mjs' => ContentType('application', 'javascript', charset: 'utf-8'),
          'css' => ContentType('text', 'css', charset: 'utf-8'),
          'json' => ContentType.json,
          'png' => ContentType('image', 'png'),
          'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
          'svg' => ContentType('image', 'svg+xml'),
          'wasm' => ContentType('application', 'wasm'),
          'ttf' || 'otf' => ContentType('font', 'ttf'),
          'woff' => ContentType('font', 'woff'),
          'woff2' => ContentType('font', 'woff2'),
          _ => ContentType.binary,
        };

        request.response.headers.contentType = contentType;
        await request.response.addStream(targetFile.openRead());
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('404 Not Found: $reqPath');
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('500 Error: $e');
    } finally {
      await request.response.close();
    }
  }
}
