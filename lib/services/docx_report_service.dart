import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import '../models/arbeitszeit.dart';
import '../models/appointment.dart';
import '../models/client.dart';

/// Echter DOCX-Generator (OpenXML-Format, von Word & LibreOffice nativ lesbar).
///
/// Kein RTF-Ersatz, sondern ein korrektes OpenXML-ZIP-Paket mit
/// document.xml, styles.xml und Content-Types. Unterstuetzt Ueberschriften,
/// Absaetze, Tabellen und Farb-Akzente analog zum Hybrid-PDF-Design.
class DocxReportService {
  // Farben (im gleichen System wie PdfReportService)
  static const _primaerHex = '1E3A5F';
  static const _mutedHex = '6B7280';
  static const _textHex = '1F2937';
  static const _tableHeaderHex = 'F3F4F6';
  static const _dividerHex = 'E5E7EB';
  static const _accentHex = '0F766E';
  static const _warnHex = 'B91C1C';

  // ══════════════════════════════════════════════════════════════════
  // OEFFENTLICHE REPORT-METHODEN
  // ══════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateArbeitszeitenDocx({
    required List<Arbeitszeit> arbeitszeiten,
    required DateTime startDate,
    required DateTime endDate,
    String? autor,
    String? aktenzeichen,
  }) async {
    final df = DateFormat('dd.MM.yyyy');
    final stats = _arbeitszeitStats(arbeitszeiten);
    final builder = _DocxBuilder();

    _addHeader(builder, 'Arbeitszeit-Bericht', aktenzeichen);
    _addHero(builder, _zeitraumLabel(startDate, endDate),
        '${df.format(startDate)} bis ${df.format(endDate)}');

    // KPI-Tabelle
    builder.table([
      [
        ('GESAMTARBEITSZEIT', '${stats.gesamtStunden.toStringAsFixed(1)} h', _primaerHex, true),
        ('EINTRÄGE', '${arbeitszeiten.length}', _textHex, false),
        ('DURCHSCHNITT', '${stats.durchschnittH.toStringAsFixed(1)} h/Tag', _textHex, false),
        ('SALDO',
            '${stats.ueberstunden >= 0 ? "+" : ""}${stats.ueberstunden.toStringAsFixed(1)} h',
            stats.ueberstunden >= 0 ? _accentHex : _warnHex,
            false),
      ],
    ], kpiRow: true);

    builder.spacer(240);

    if (stats.verteilung.isNotEmpty) {
      _addSection(builder, 'I', 'Verteilung nach Tätigkeit');
      _addVerteilung(builder, stats.verteilung, stats.gesamtStunden);
      builder.spacer(240);
    }

    _addSection(builder, stats.verteilung.isNotEmpty ? 'II' : 'I', 'Einzelnachweis');
    if (arbeitszeiten.isEmpty) {
      _addEmpty(builder, 'Keine Arbeitszeiten im gewählten Zeitraum.');
    } else {
      _addArbeitszeitenTabelle(builder, arbeitszeiten);
    }

    builder.spacer(480);
    _addUnterschriften(builder, autor);

    return builder.build();
  }

  static Future<Uint8List> generateFachleistungsstundenDocx({
    required List<Appointment> appointments,
    required DateTime startDate,
    required DateTime endDate,
    String? autor,
    String? aktenzeichen,
  }) async {
    final df = DateFormat('dd.MM.yyyy');
    final relevante = appointments.where((a) => a.fachleistungsstunden > 0).toList();
    final stats = _flsStats(relevante);
    final builder = _DocxBuilder();

    _addHeader(builder, 'Fachleistungsstunden', aktenzeichen);
    _addHero(builder, _zeitraumLabel(startDate, endDate),
        '${df.format(startDate)} bis ${df.format(endDate)}');

    builder.table([
      [
        ('GESAMT-FLS', '${stats.gesamt.toStringAsFixed(2)} h', _primaerHex, true),
        ('TERMINE', '${relevante.length}', _textHex, false),
        ('KLIENTEN', '${stats.proKlient.length}', _textHex, false),
        if (stats.proKlient.isNotEmpty)
          ('TOP-KLIENT', '${stats.proKlient.values.first.toStringAsFixed(1)} h', _accentHex, false),
      ],
    ], kpiRow: true);

    builder.spacer(240);

    if (stats.proKlient.isNotEmpty) {
      _addSection(builder, 'I', 'Verteilung pro Klient');
      _addVerteilung(builder, stats.proKlient, stats.gesamt);
      builder.spacer(240);
    }

    _addSection(builder, stats.proKlient.isNotEmpty ? 'II' : 'I', 'Einzelnachweis');
    if (relevante.isEmpty) {
      _addEmpty(builder, 'Keine Fachleistungsstunden im gewählten Zeitraum.');
    } else {
      _addFlsTabelle(builder, relevante);
    }

    builder.spacer(480);
    _addUnterschriften(builder, autor);

    return builder.build();
  }

  static Future<Uint8List> generateKlientenDocx({
    required List<Client> clients,
    String? autor,
    String? aktenzeichen,
  }) async {
    int mitEinwilligung = 0;
    double bewilligtSumme = 0;
    double verbrauchtSumme = 0;
    for (final c in clients) {
      if (c.einwilligungVorhanden) mitEinwilligung++;
      if (c.fachleistungsstunden != null) {
        bewilligtSumme += c.fachleistungsstunden!.toDouble();
        verbrauchtSumme += c.verbrauchteStunden;
      }
    }
    final auslastung = bewilligtSumme > 0 ? verbrauchtSumme / bewilligtSumme * 100 : 0.0;
    final builder = _DocxBuilder();

    _addHeader(builder, 'Klienten-Übersicht', aktenzeichen);
    _addHero(builder, 'Klienten-Übersicht',
        'Stand ${DateFormat('dd.MM.yyyy').format(DateTime.now())}');

    builder.table([
      [
        ('KLIENTEN GESAMT', '${clients.length}', _primaerHex, true),
        ('MIT EINWILLIGUNG', '$mitEinwilligung / ${clients.length}',
            mitEinwilligung == clients.length ? _accentHex : _warnHex, false),
        if (bewilligtSumme > 0)
          ('FLS BEWILLIGT', '${bewilligtSumme.toStringAsFixed(0)} h', _textHex, false),
        if (bewilligtSumme > 0)
          ('AUSLASTUNG', '${auslastung.toStringAsFixed(0)} %',
              auslastung >= 90 ? _warnHex : (auslastung >= 75 ? _accentHex : _textHex),
              false),
      ],
    ], kpiRow: true);

    builder.spacer(240);
    _addSection(builder, 'I', 'Klienten-Liste');
    if (clients.isEmpty) {
      _addEmpty(builder, 'Keine Klienten erfasst.');
    } else {
      _addKlientenTabelle(builder, clients);
    }

    builder.spacer(480);
    _addUnterschriften(builder, autor);

    return builder.build();
  }

  // ══════════════════════════════════════════════════════════════════
  // BAUSTEINE
  // ══════════════════════════════════════════════════════════════════

  static void _addHeader(_DocxBuilder b, String titel, String? az) {
    b.paragraph([
      _Run('FEGH-Dokumentation', size: 26, bold: true, color: _primaerHex),
    ], borderBottom: _primaerHex);
    b.paragraph([
      _Run('Eingliederungshilfe nach SGB IX', size: 16, color: _mutedHex),
    ]);
    b.paragraph([
      _Run(titel.toUpperCase(), size: 18, color: _mutedHex),
      if (az != null && az.isNotEmpty) _Run('   AZ: $az', size: 16, color: _mutedHex),
    ]);
    b.spacer(360);
  }

  static void _addHero(_DocxBuilder b, String titel, String untertitel) {
    b.paragraph([
      _Run('ZEITRAUM', size: 18, color: _mutedHex),
    ]);
    b.paragraph([
      _Run(titel, size: 60, bold: true, color: _primaerHex),
    ]);
    b.paragraph([
      _Run(untertitel, size: 22, color: _mutedHex),
    ]);
    b.spacer(360);
  }

  static void _addSection(_DocxBuilder b, String nr, String titel) {
    b.paragraph([
      _Run('$nr.  ', size: 28, bold: true, color: _primaerHex),
      _Run(titel, size: 28, bold: true, color: _primaerHex),
    ], borderBottom: _dividerHex);
    b.spacer(120);
  }

  static void _addEmpty(_DocxBuilder b, String text) {
    b.paragraph([
      _Run(text, size: 22, color: _mutedHex, italic: true),
    ]);
  }

  static void _addVerteilung(_DocxBuilder b, Map<String, double> data, double total) {
    if (data.isEmpty) return;
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final rows = <List<(String, String, String, bool)>>[
      [
        ('BEREICH', 'BEREICH', _primaerHex, true),
        ('ANTEIL', 'ANTEIL', _primaerHex, true),
        ('STUNDEN', 'STUNDEN', _primaerHex, true),
      ],
    ];
    for (final e in sorted) {
      final anteil = total > 0 ? (e.value / total * 100) : 0;
      rows.add([
        (e.key, e.key, _textHex, false),
        ('${anteil.toStringAsFixed(0)} %', '${anteil.toStringAsFixed(0)} %', _mutedHex, false),
        ('${e.value.toStringAsFixed(1)} h', '${e.value.toStringAsFixed(1)} h', _textHex, true),
      ]);
    }
    b.table(rows);
  }

  static void _addArbeitszeitenTabelle(_DocxBuilder b, List<Arbeitszeit> list) {
    final sorted = List<Arbeitszeit>.from(list)..sort((a, b) => a.datum.compareTo(b.datum));
    final rows = <List<(String, String, String, bool)>>[
      [
        ('DATUM', 'DATUM', _primaerHex, true),
        ('ZEIT', 'ZEIT', _primaerHex, true),
        ('TÄTIGKEIT', 'TÄTIGKEIT', _primaerHex, true),
        ('STUNDEN', 'STUNDEN', _primaerHex, true),
      ],
    ];
    for (final a in sorted) {
      final h = (a.arbeitszeit.inMinutes / 60.0).toStringAsFixed(2);
      rows.add([
        (DateFormat('dd.MM.yyyy').format(a.datum), '', _textHex, false),
        ('${a.formatierteStartzeit} – ${a.formatierteEndzeit}', '', _textHex, false),
        (a.taetigkeit, '', _textHex, false),
        ('$h h', '', _textHex, true),
      ]);
    }
    b.table(rows);
  }

  static void _addFlsTabelle(_DocxBuilder b, List<Appointment> list) {
    final sorted = List<Appointment>.from(list)..sort((a, b) => a.date.compareTo(b.date));
    final rows = <List<(String, String, String, bool)>>[
      [
        ('DATUM', 'DATUM', _primaerHex, true),
        ('ZEIT', 'ZEIT', _primaerHex, true),
        ('KLIENT', 'KLIENT', _primaerHex, true),
        ('FLS', 'FLS', _primaerHex, true),
      ],
    ];
    for (final a in sorted) {
      rows.add([
        (DateFormat('dd.MM.yyyy').format(a.date), '', _textHex, false),
        ('${DateFormat('HH:mm').format(a.startTime)} – ${DateFormat('HH:mm').format(a.endTime)}',
            '', _textHex, false),
        (a.clientName, '', _textHex, false),
        ('${a.fachleistungsstunden.toStringAsFixed(2)} h', '', _textHex, true),
      ]);
    }
    b.table(rows);
  }

  static void _addKlientenTabelle(_DocxBuilder b, List<Client> list) {
    for (final c in list) {
      final farbe = c.einwilligungVorhanden ? _accentHex : _warnHex;
      b.paragraph([
        _Run(c.vollstaendigerName, size: 24, bold: true, color: _primaerHex),
        _Run(c.einwilligungVorhanden ? '    Einwilligung: Ja' : '    Einwilligung: Nein',
            size: 18, bold: true, color: farbe),
      ]);
      if (c.kostenuebernahme != null && c.kostenuebernahme!.isNotEmpty) {
        b.paragraph([_Run(c.kostenuebernahme!, size: 20, color: _mutedHex)]);
      }
      if (c.fachleistungsstunden != null) {
        final bew = c.fachleistungsstunden!;
        final verb = c.verbrauchteStunden.toStringAsFixed(1);
        final pro = c.stundenverbrauchProzent.toStringAsFixed(0);
        final auslFarbe = c.stundenverbrauchProzent >= 90
            ? _warnHex
            : (c.stundenverbrauchProzent >= 75 ? _accentHex : _textHex);
        b.paragraph([
          _Run('Fachleistungsstunden: ', size: 18, color: _mutedHex),
          _Run('$verb / $bew h  ($pro %)', size: 18, bold: true, color: auslFarbe),
        ]);
      }
      b.spacer(180);
    }
  }

  static void _addUnterschriften(_DocxBuilder b, String? autor) {
    final label = autor != null && autor.isNotEmpty
        ? 'UNTERSCHRIFT ${autor.toUpperCase()}'
        : 'UNTERSCHRIFT MITARBEITER:IN';
    b.table([
      [
        ('_______________________', '_______________________', _textHex, false),
        ('_______________________', '_______________________', _textHex, false),
        ('_______________________', '_______________________', _textHex, false),
      ],
      [
        ('ORT, DATUM', 'ORT, DATUM', _mutedHex, false),
        (label, label, _mutedHex, false),
        ('UNTERSCHRIFT TEAMLEITUNG', 'UNTERSCHRIFT TEAMLEITUNG', _mutedHex, false),
      ],
    ]);
  }

  // ── Helpers (Stats, Labels) ──────────────────────────────────────

  static _ArbeitszeitStats _arbeitszeitStats(List<Arbeitszeit> list) {
    double gesamt = 0;
    final verteilung = <String, double>{};
    final tage = <DateTime>{};
    for (final a in list) {
      final h = a.arbeitszeit.inMinutes / 60.0;
      gesamt += h;
      verteilung[a.typ.displayName] = (verteilung[a.typ.displayName] ?? 0) + h;
      tage.add(DateTime(a.datum.year, a.datum.month, a.datum.day));
    }
    final arbeitstage = tage.isEmpty ? 1 : tage.length;
    final durchschnitt = gesamt / arbeitstage;
    final saldo = gesamt - arbeitstage * 8.0;
    return _ArbeitszeitStats(gesamt, durchschnitt, saldo, verteilung);
  }

  static _FlsStats _flsStats(List<Appointment> list) {
    double gesamt = 0;
    final proKlient = <String, double>{};
    for (final a in list) {
      if (a.isIndirect && a.clientAllocations != null) {
        for (final alloc in a.clientAllocations!) {
          gesamt += alloc.stunden;
          proKlient[alloc.clientName] = (proKlient[alloc.clientName] ?? 0) + alloc.stunden;
        }
      } else {
        gesamt += a.fachleistungsstunden;
        proKlient[a.clientName] = (proKlient[a.clientName] ?? 0) + a.fachleistungsstunden;
      }
    }
    final sortiert = Map.fromEntries(
      proKlient.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return _FlsStats(gesamt, sortiert);
  }

  static String _zeitraumLabel(DateTime start, DateTime end) {
    const monate = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];
    if (start.year == end.year && start.month == end.month) {
      return '${monate[start.month - 1]} ${start.year}';
    }
    if (start.year == end.year) return '${start.year}';
    return '${start.year} - ${end.year}';
  }
}

// ══════════════════════════════════════════════════════════════════
// PRIVATE DOCX-BUILDER
// ══════════════════════════════════════════════════════════════════

class _DocxBuilder {
  final StringBuffer _body = StringBuffer();

  void paragraph(List<_Run> runs, {String? borderBottom}) {
    _body.write('<w:p><w:pPr>');
    if (borderBottom != null) {
      _body.write('<w:pBdr><w:bottom w:val="single" w:sz="8" w:space="4" w:color="$borderBottom"/></w:pBdr>');
    }
    _body.write('<w:spacing w:after="60"/>');
    _body.write('</w:pPr>');
    for (final r in runs) {
      _body.write(r.render());
    }
    _body.write('</w:p>');
  }

  void spacer(int twip) {
    _body.write(
        '<w:p><w:pPr><w:spacing w:before="$twip" w:after="0"/></w:pPr></w:p>');
  }

  /// Tabelle. Zelle: (label, value, colorHex, bold)
  void table(List<List<(String, String, String, bool)>> rows, {bool kpiRow = false}) {
    if (rows.isEmpty) return;
    final spalten = rows.first.length;
    final spaltenBreite = 9000 ~/ spalten; // Gesamt ca. 9000 twips (A4 - Margin)
    _body.write('<w:tbl><w:tblPr>');
    _body.write('<w:tblW w:w="5000" w:type="pct"/>');
    _body.write(
        '<w:tblBorders>'
        '<w:top w:val="single" w:sz="4" w:color="${DocxReportService._dividerHex}"/>'
        '<w:left w:val="none" w:sz="0" w:color="auto"/>'
        '<w:right w:val="none" w:sz="0" w:color="auto"/>'
        '<w:bottom w:val="single" w:sz="4" w:color="${DocxReportService._dividerHex}"/>'
        '<w:insideH w:val="single" w:sz="4" w:color="${DocxReportService._dividerHex}"/>'
        '<w:insideV w:val="none" w:sz="0" w:color="auto"/>'
        '</w:tblBorders>');
    _body.write('<w:tblCellMar>'
        '<w:top w:w="120" w:type="dxa"/>'
        '<w:left w:w="120" w:type="dxa"/>'
        '<w:bottom w:w="120" w:type="dxa"/>'
        '<w:right w:w="120" w:type="dxa"/>'
        '</w:tblCellMar>');
    _body.write('</w:tblPr>');

    // PFLICHT in OOXML: tblGrid mit Spalten-Definitionen
    _body.write('<w:tblGrid>');
    for (int i = 0; i < spalten; i++) {
      _body.write('<w:gridCol w:w="$spaltenBreite"/>');
    }
    _body.write('</w:tblGrid>');
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final isHeader = i == 0 && !kpiRow;
      final isKpi = kpiRow;
      _body.write('<w:tr>');
      for (final cell in row) {
        final label = cell.$1;
        final value = cell.$2;
        final colorHex = cell.$3;
        final bold = cell.$4;
        _body.write('<w:tc><w:tcPr><w:tcW w:w="${5000 ~/ row.length}" w:type="pct"/>');
        if (isHeader || isKpi) {
          _body.write('<w:shd w:val="clear" w:fill="${DocxReportService._tableHeaderHex}"/>');
        }
        _body.write('</w:tcPr>');

        if (isKpi) {
          // KPI-Zelle: Label klein + Wert groß
          _body.write('<w:p><w:pPr><w:spacing w:after="20"/></w:pPr>');
          _body.write(_Run(label, size: 14, color: DocxReportService._mutedHex).render());
          _body.write('</w:p>');
          _body.write('<w:p><w:pPr><w:spacing w:after="0"/></w:pPr>');
          _body.write(_Run(value, size: bold ? 32 : 24, bold: true, color: colorHex).render());
          _body.write('</w:p>');
        } else {
          _body.write('<w:p><w:pPr><w:spacing w:after="0"/></w:pPr>');
          _body.write(_Run(label,
                  size: isHeader ? 16 : 20,
                  bold: bold || isHeader,
                  color: colorHex)
              .render());
          _body.write('</w:p>');
        }
        _body.write('</w:tc>');
      }
      _body.write('</w:tr>');
    }
    _body.write('</w:tbl>');
    spacer(120);
  }

  Uint8List build() {
    final document = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
${_body.toString()}
<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="709" w:footer="709" w:gutter="0"/></w:sectPr>
</w:body>
</w:document>''';

    const contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';

    const rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    const docRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

    const styles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr></w:rPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
</w:styles>''';

    // UTF-8-Bytes erzeugen und korrekte Byte-Laenge verwenden
    final contentTypesBytes = utf8.encode(contentTypes);
    final relsBytes = utf8.encode(rels);
    final docRelsBytes = utf8.encode(docRels);
    final stylesBytes = utf8.encode(styles);
    final documentBytes = utf8.encode(document);

    final archive = Archive()
      ..addFile(ArchiveFile('[Content_Types].xml', contentTypesBytes.length, contentTypesBytes))
      ..addFile(ArchiveFile('_rels/.rels', relsBytes.length, relsBytes))
      ..addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsBytes.length, docRelsBytes))
      ..addFile(ArchiveFile('word/styles.xml', stylesBytes.length, stylesBytes))
      ..addFile(ArchiveFile('word/document.xml', documentBytes.length, documentBytes));

    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) {
      throw StateError('DOCX-Archiv konnte nicht erzeugt werden');
    }
    return Uint8List.fromList(zipped);
  }
}

class _Run {
  final String text;
  final int size; // halbe Punkt-Werte (22 = 11pt)
  final bool bold;
  final bool italic;
  final String? color; // Hex ohne #

  _Run(this.text, {this.size = 22, this.bold = false, this.italic = false, this.color});

  String render() {
    final buf = StringBuffer('<w:r><w:rPr>');
    if (bold) buf.write('<w:b/>');
    if (italic) buf.write('<w:i/>');
    if (color != null) buf.write('<w:color w:val="$color"/>');
    buf.write('<w:sz w:val="$size"/>');
    buf.write('</w:rPr><w:t xml:space="preserve">${_xmlEscape(text)}</w:t></w:r>');
    return buf.toString();
  }

  static String _xmlEscape(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _ArbeitszeitStats {
  final double gesamtStunden;
  final double durchschnittH;
  final double ueberstunden;
  final Map<String, double> verteilung;
  _ArbeitszeitStats(this.gesamtStunden, this.durchschnittH, this.ueberstunden, this.verteilung);
}

class _FlsStats {
  final double gesamt;
  final Map<String, double> proKlient;
  _FlsStats(this.gesamt, this.proKlient);
}
