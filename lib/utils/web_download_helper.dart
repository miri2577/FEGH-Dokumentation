// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileOnWeb(String content, String fileName) {
  final bytes = html.Blob([content], 'text/plain', 'native');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = '$fileName.txt';
  html.document.body!.children.add(anchor);
  anchor.click();
  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}