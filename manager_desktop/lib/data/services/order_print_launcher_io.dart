import 'dart:io';

Future<bool> launchPrintableHtml(
  String htmlContent, {
  required String fileSlug,
}) async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return true;
  }
  try {
    final safeSlug = fileSlug.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}siaka_print_$safeSlug.html',
    );
    await file.writeAsString(htmlContent, flush: true);

    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', file.path]);
      return true;
    } else if (Platform.isMacOS) {
      await Process.run('open', [file.path]);
      return true;
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [file.path]);
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}

