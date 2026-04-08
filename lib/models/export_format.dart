enum ExportFormat {
  pdf('PDF', 'pdf', 'application/pdf'),
  word('Word', 'docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
  markdown('Markdown', 'md', 'text/markdown'),
  csv('CSV', 'csv', 'text/csv'),
  txt('Text', 'txt', 'text/plain');

  const ExportFormat(this.displayName, this.extension, this.mimeType);

  final String displayName;
  final String extension;
  final String mimeType;
}

class ExportOptions {
  final ExportFormat format;
  final String? customPath;
  final String filename;

  const ExportOptions({
    required this.format,
    this.customPath,
    required this.filename,
  });

  String get fullFilename => '$filename.${format.extension}';
}