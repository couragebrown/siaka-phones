import 'dart:js_interop';

@JS('window.open')
external JSObject? _windowOpen(String url, String target);

Future<bool> launchPrintableHtml(
  String htmlContent, {
  required String fileSlug,
}) async {
  try {
    final dataUri =
        'data:text/html;charset=utf-8,${Uri.encodeComponent(htmlContent)}';
    _windowOpen(dataUri, '_blank');
    return true;
  } catch (_) {
    return false;
  }
}

