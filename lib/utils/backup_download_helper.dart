// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadBackupOnWeb(String data, String filename) {
  final blob = html.Blob([data]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}