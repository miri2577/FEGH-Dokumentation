import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Erzeugt zwei Beispiel-PDFs fuer die Design-Entscheidung:
/// A: modern-schlicht (Apple-Geschaeftsbericht-Stil)
/// B: klassisch-behoerdlich (Amtsformular-Stil)
///
/// Gleiche Dummy-Daten, direkt vergleichbar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Dummy-Daten ────────────────────────────────────────────────
  final zeitraumVon = DateTime(2026, 3, 1);
  final zeitraumBis = DateTime(2026, 3, 31);
  final df = DateFormat('dd.MM.yyyy');

  // Arbeitszeit-Stats
  const gesamtStunden = 162.5;
  const eintraege = 21;
  const durchschnitt = 7.7;
  const ueberstunden = 2.5;

  // Verteilung pro Taetigkeit
  final verteilung = {
    'Kliententermin': 98.5,
    'Dokumentation': 23.0,
    'Buero': 15.0,
    'Supervision': 12.0,
    'Fortbildung': 8.0,
    'Fahrtzeit': 6.0,
  };

  // Einzelne Tage
  final tage = [
    ('Mo 03.03.', 8.0, 'Kliententermin'),
    ('Di 04.03.', 7.5, 'Dokumentation'),
    ('Mi 05.03.', 8.5, 'Kliententermin'),
    ('Do 06.03.', 6.0, 'Supervision'),
    ('Fr 07.03.', 7.0, 'Buero'),
    ('Mo 10.03.', 8.5, 'Kliententermin'),
    ('Di 11.03.', 8.0, 'Kliententermin'),
    ('Mi 12.03.', 7.5, 'Dokumentation'),
  ];

  test('Stil A - modern/schlicht (Apple-Bericht)', () async {
    final bytes = await _baueStilA(
      zeitraumVon: zeitraumVon,
      zeitraumBis: zeitraumBis,
      df: df,
      gesamtStunden: gesamtStunden,
      eintraege: eintraege,
      durchschnitt: durchschnitt,
      ueberstunden: ueberstunden,
      verteilung: verteilung,
      tage: tage,
    );
    final path = 'C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Beispiel_A_modern.pdf';
    File(path).writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('Stil A gespeichert: $path (${bytes.length} Bytes)');
    expect(bytes.length, greaterThan(1000));
  });

  test('Stil B - klassisch/behoerdlich (Amtsformular)', () async {
    final bytes = await _baueStilB(
      zeitraumVon: zeitraumVon,
      zeitraumBis: zeitraumBis,
      df: df,
      gesamtStunden: gesamtStunden,
      eintraege: eintraege,
      durchschnitt: durchschnitt,
      ueberstunden: ueberstunden,
      verteilung: verteilung,
      tage: tage,
    );
    final path = 'C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Beispiel_B_behoerdlich.pdf';
    File(path).writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('Stil B gespeichert: $path (${bytes.length} Bytes)');
    expect(bytes.length, greaterThan(1000));
  });

  test('Stil C - Hybrid (modern + behoerdlich)', () async {
    final bytes = await _baueStilC(
      zeitraumVon: zeitraumVon,
      zeitraumBis: zeitraumBis,
      df: df,
      gesamtStunden: gesamtStunden,
      eintraege: eintraege,
      durchschnitt: durchschnitt,
      ueberstunden: ueberstunden,
      verteilung: verteilung,
      tage: tage,
    );
    final path = 'C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Beispiel_C_hybrid.pdf';
    File(path).writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('Stil C gespeichert: $path (${bytes.length} Bytes)');
    expect(bytes.length, greaterThan(1000));
  });
}

// ═══════════════════════════════════════════════════════════════════
// STIL A - modern-schlicht
// ═══════════════════════════════════════════════════════════════════

Future<List<int>> _baueStilA({
  required DateTime zeitraumVon,
  required DateTime zeitraumBis,
  required DateFormat df,
  required double gesamtStunden,
  required int eintraege,
  required double durchschnitt,
  required double ueberstunden,
  required Map<String, double> verteilung,
  required List<(String, double, String)> tage,
}) async {
  final pdf = pw.Document();
  const akzent = PdfColor.fromInt(0xFF1F2937); // dunkelgrau
  const subtle = PdfColor.fromInt(0xFF6B7280); // mittelgrau
  const line = PdfColor.fromInt(0xFFE5E7EB);   // hellgrau

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(60, 50, 60, 50),
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('FEGH-Dokumentation',
                style: pw.TextStyle(fontSize: 8, color: subtle)),
            pw.Text('Seite ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: subtle)),
          ],
        ),
      ),
      build: (ctx) => [
        // Kleiner Label oben
        pw.Text('ARBEITSZEIT-BERICHT',
            style: pw.TextStyle(fontSize: 9, color: subtle, letterSpacing: 2)),
        pw.SizedBox(height: 6),
        // Grosse Ueberschrift
        pw.Text('Maerz 2026',
            style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: akzent)),
        pw.SizedBox(height: 4),
        pw.Text(
            '${df.format(zeitraumVon)} bis ${df.format(zeitraumBis)}',
            style: pw.TextStyle(fontSize: 11, color: subtle)),
        pw.SizedBox(height: 48),

        // Hero-Zahl
        pw.Text('Gesamtarbeitszeit',
            style: pw.TextStyle(fontSize: 10, color: subtle)),
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(gesamtStunden.toStringAsFixed(1),
                style: pw.TextStyle(
                    fontSize: 56,
                    fontWeight: pw.FontWeight.bold,
                    color: akzent,
                    letterSpacing: -1)),
            pw.SizedBox(width: 8),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text('Stunden',
                  style: pw.TextStyle(fontSize: 14, color: subtle)),
            ),
          ],
        ),
        pw.SizedBox(height: 40),

        // KPI-Reihe - ohne Karten, nur Zahlen
        pw.Row(
          children: [
            _kpiA('Eintraege', '$eintraege', subtle, akzent),
            _kpiA('Durchschnitt', '${durchschnitt.toStringAsFixed(1)} h/Tag', subtle, akzent),
            _kpiA('Ueberstunden', '+${ueberstunden.toStringAsFixed(1)} h', subtle,
                const PdfColor.fromInt(0xFF059669)),
          ],
        ),
        pw.SizedBox(height: 48),
        pw.Divider(color: line, height: 1),
        pw.SizedBox(height: 24),

        // Verteilung
        pw.Text('Verteilung nach Taetigkeit',
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold, color: akzent)),
        pw.SizedBox(height: 16),
        ..._verteilungA(verteilung, gesamtStunden, akzent, subtle),
        pw.SizedBox(height: 40),
        pw.Divider(color: line, height: 1),
        pw.SizedBox(height: 24),

        // Einzeltage
        pw.Text('Taegliche Aufzeichnungen',
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold, color: akzent)),
        pw.SizedBox(height: 16),
        ..._einzeltageA(tage, akzent, subtle, line),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _kpiA(String label, String value, PdfColor subtle, PdfColor akzent) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: subtle)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold, color: akzent)),
      ],
    ),
  );
}

List<pw.Widget> _verteilungA(Map<String, double> data, double total,
    PdfColor akzent, PdfColor subtle) {
  final max = data.values.reduce((a, b) => a > b ? a : b);
  return data.entries.map((e) {
    final anteil = e.value / total * 100;
    final barWidth = e.value / max * 300;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e.key,
                  style: pw.TextStyle(fontSize: 11, color: akzent)),
              pw.Text(
                  '${e.value.toStringAsFixed(1)} h  ${anteil.toStringAsFixed(0)}%',
                  style: pw.TextStyle(fontSize: 11, color: subtle)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            height: 4,
            width: barWidth,
            decoration: pw.BoxDecoration(
              color: akzent,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }).toList();
}

List<pw.Widget> _einzeltageA(List<(String, double, String)> tage,
    PdfColor akzent, PdfColor subtle, PdfColor line) {
  return tage.map((t) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: line)),
        ),
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          children: [
            pw.SizedBox(
                width: 80,
                child: pw.Text(t.$1,
                    style: pw.TextStyle(fontSize: 11, color: subtle))),
            pw.Expanded(
                child: pw.Text(t.$3,
                    style: pw.TextStyle(fontSize: 11, color: akzent))),
            pw.Text('${t.$2.toStringAsFixed(1)} h',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: akzent)),
          ],
        ),
      ),
    );
  }).toList();
}

// ═══════════════════════════════════════════════════════════════════
// STIL B - klassisch-behoerdlich
// ═══════════════════════════════════════════════════════════════════

Future<List<int>> _baueStilB({
  required DateTime zeitraumVon,
  required DateTime zeitraumBis,
  required DateFormat df,
  required double gesamtStunden,
  required int eintraege,
  required double durchschnitt,
  required double ueberstunden,
  required Map<String, double> verteilung,
  required List<(String, double, String)> tage,
}) async {
  final pdf = pw.Document();
  const schwarz = PdfColors.black;
  const grauDunkel = PdfColor.fromInt(0xFF333333);
  const grauHell = PdfColor.fromInt(0xFFF5F5F5);
  const grauLinie = PdfColor.fromInt(0xFF999999);
  const akzentRot = PdfColor.fromInt(0xFFB91C1C);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: schwarz, width: 1.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FEGH-Dokumentation',
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: schwarz)),
                pw.Text('Eingliederungshilfe nach SGB IX',
                    style: pw.TextStyle(fontSize: 8, color: grauDunkel)),
              ],
            ),
            pw.Text('Arbeitszeit-Nachweis',
                style: pw.TextStyle(
                    fontSize: 10, color: grauDunkel, letterSpacing: 1)),
          ],
        ),
      ),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: grauLinie, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
                'Erstellt am ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: grauDunkel)),
            pw.Text('Aktenzeichen: AZ-2026/03-FEGH',
                style: pw.TextStyle(fontSize: 8, color: grauDunkel)),
            pw.Text('Seite ${ctx.pageNumber} von ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: grauDunkel)),
          ],
        ),
      ),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        // Zentrierter Titelblock
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text('Arbeitszeit-Nachweis'.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: schwarz,
                      letterSpacing: 2)),
              pw.SizedBox(height: 4),
              pw.Text('fuer den Zeitraum',
                  style: pw.TextStyle(fontSize: 10, color: grauDunkel)),
              pw.SizedBox(height: 2),
              pw.Text(
                  '${df.format(zeitraumVon)} bis ${df.format(zeitraumBis)}',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: schwarz)),
            ],
          ),
        ),
        pw.SizedBox(height: 28),

        // Metadaten-Block
        _metadatenB(schwarz, grauLinie, grauHell),
        pw.SizedBox(height: 24),

        // Zusammenfassung als strenge Tabelle
        _sektionTitelB('I. Zusammenfassung', schwarz, grauLinie),
        pw.SizedBox(height: 8),
        _zusammenfassungB(
            gesamtStunden: gesamtStunden,
            eintraege: eintraege,
            durchschnitt: durchschnitt,
            ueberstunden: ueberstunden,
            schwarz: schwarz,
            grauHell: grauHell,
            grauLinie: grauLinie,
            akzentRot: akzentRot),
        pw.SizedBox(height: 24),

        // Verteilung
        _sektionTitelB('II. Verteilung nach Taetigkeit', schwarz, grauLinie),
        pw.SizedBox(height: 8),
        _verteilungB(verteilung, gesamtStunden, schwarz, grauLinie, grauHell),
        pw.SizedBox(height: 24),

        // Tagesauflistung
        _sektionTitelB('III. Einzelnachweis', schwarz, grauLinie),
        pw.SizedBox(height: 8),
        _einzelnachweisB(tage, schwarz, grauLinie, grauHell),
        pw.SizedBox(height: 40),

        // Unterschrift
        _unterschriftB(schwarz, grauLinie, grauDunkel),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _metadatenB(PdfColor schwarz, PdfColor linie, PdfColor grauHell) {
  pw.Widget zelle(String label, String wert) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: linie),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8, letterSpacing: 1)),
            pw.SizedBox(height: 2),
            pw.Text(wert,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: schwarz)),
          ],
        ),
      ),
    );
  }

  return pw.Row(
    children: [
      zelle('LEISTUNGSERBRINGER', 'Musterfirma GmbH'),
      zelle('MITARBEITER:IN', 'Anna Fachkraft'),
      zelle('TEAM', 'Team Mitte'),
      zelle('BERICHTSDATUM', DateFormat('dd.MM.yyyy').format(DateTime.now())),
    ],
  );
}

pw.Widget _sektionTitelB(String titel, PdfColor schwarz, PdfColor linie) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey200,
      border: pw.Border(bottom: pw.BorderSide(color: schwarz, width: 1)),
    ),
    child: pw.Text(titel,
        style: pw.TextStyle(
            fontSize: 12, fontWeight: pw.FontWeight.bold, color: schwarz)),
  );
}

pw.Widget _zusammenfassungB({
  required double gesamtStunden,
  required int eintraege,
  required double durchschnitt,
  required double ueberstunden,
  required PdfColor schwarz,
  required PdfColor grauHell,
  required PdfColor grauLinie,
  required PdfColor akzentRot,
}) {
  pw.TableRow row(String label, String wert, {bool rot = false, bool bold = false}) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10,
                  color: schwarz,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(wert,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: rot ? akzentRot : schwarz)),
        ),
      ],
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(color: grauLinie, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('Kennzahl',
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Wert',
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
      row('Anzahl Arbeitszeiteintraege', '$eintraege'),
      row('Gesamtarbeitszeit', '${gesamtStunden.toStringAsFixed(2)} h', bold: true),
      row('Durchschnitt pro Arbeitstag', '${durchschnitt.toStringAsFixed(2)} h'),
      row('Ueberstundensaldo', '+${ueberstunden.toStringAsFixed(2)} h', rot: true, bold: true),
    ],
  );
}

pw.Widget _verteilungB(Map<String, double> data, double total,
    PdfColor schwarz, PdfColor linie, PdfColor grauHell) {
  return pw.Table(
    border: pw.TableBorder.all(color: linie, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(1),
      2: pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _th('Taetigkeit'),
          _th('Stunden', right: true),
          _th('Anteil', right: true),
        ],
      ),
      ...data.entries.map((e) {
        final anteil = e.value / total * 100;
        return pw.TableRow(
          children: [
            _td(e.key),
            _td('${e.value.toStringAsFixed(2)} h', right: true),
            _td('${anteil.toStringAsFixed(1)} %', right: true),
          ],
        );
      }),
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          _td('Gesamt', bold: true),
          _td('${total.toStringAsFixed(2)} h', right: true, bold: true),
          _td('100,0 %', right: true, bold: true),
        ],
      ),
    ],
  );
}

pw.Widget _einzelnachweisB(
    List<(String, double, String)> tage, PdfColor schwarz, PdfColor linie,
    PdfColor grauHell) {
  return pw.Table(
    border: pw.TableBorder.all(color: linie, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.2),
      1: pw.FlexColumnWidth(2),
      2: pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _th('Datum'),
          _th('Taetigkeit'),
          _th('Stunden', right: true),
        ],
      ),
      ...tage.map((t) => pw.TableRow(
            children: [
              _td(t.$1),
              _td(t.$3),
              _td('${t.$2.toStringAsFixed(2)} h', right: true),
            ],
          )),
    ],
  );
}

pw.Widget _th(String t, {bool right = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(6),
    alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    child: pw.Text(t,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
  );
}

pw.Widget _td(String t, {bool right = false, bool bold = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(6),
    alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    child: pw.Text(t,
        style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
  );
}

pw.Widget _unterschriftB(
    PdfColor schwarz, PdfColor linie, PdfColor grauDunkel) {
  pw.Widget unterschriftSpalte(String label) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
              height: 40,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: schwarz, width: 0.8),
                ),
              )),
          pw.SizedBox(height: 4),
          pw.Text(label,
              style: pw.TextStyle(fontSize: 8, color: grauDunkel)),
        ],
      ),
    );
  }

  return pw.Row(
    children: [
      unterschriftSpalte('Ort, Datum'),
      pw.SizedBox(width: 32),
      unterschriftSpalte('Unterschrift Mitarbeiter:in'),
      pw.SizedBox(width: 32),
      unterschriftSpalte('Unterschrift Teamleitung'),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
// STIL C - Hybrid (modern + behoerdlich)
// ═══════════════════════════════════════════════════════════════════

Future<List<int>> _baueStilC({
  required DateTime zeitraumVon,
  required DateTime zeitraumBis,
  required DateFormat df,
  required double gesamtStunden,
  required int eintraege,
  required double durchschnitt,
  required double ueberstunden,
  required Map<String, double> verteilung,
  required List<(String, double, String)> tage,
}) async {
  final pdf = pw.Document();

  // Design-System
  const primaer = PdfColor.fromInt(0xFF1E3A5F);  // dunkles Behoerden-Blau
  const text = PdfColor.fromInt(0xFF1F2937);
  const muted = PdfColor.fromInt(0xFF6B7280);
  const divider = PdfColor.fromInt(0xFFE5E7EB);
  const accent = PdfColor.fromInt(0xFF0F766E);    // Teal-Gruen fuer Positiv
  const warn = PdfColor.fromInt(0xFFB91C1C);      // Rot
  const tableHeader = PdfColor.fromInt(0xFFF3F4F6);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),

      // BEHOERDLICHER HEADER
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: primaer, width: 2)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FEGH-Dokumentation',
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: primaer)),
                pw.SizedBox(height: 2),
                pw.Text('Eingliederungshilfe nach SGB IX',
                    style: pw.TextStyle(fontSize: 8, color: muted)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('ARBEITSZEIT-NACHWEIS',
                    style: pw.TextStyle(
                        fontSize: 9,
                        color: muted,
                        letterSpacing: 2)),
                pw.SizedBox(height: 2),
                pw.Text('AZ: 2026/03-FEGH',
                    style: pw.TextStyle(fontSize: 8, color: muted)),
              ],
            ),
          ],
        ),
      ),

      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: divider, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
                'Erstellt ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: muted)),
            pw.Text('FEGH-Dokumentation',
                style: pw.TextStyle(fontSize: 8, color: muted)),
            pw.Text('Seite ${ctx.pageNumber} von ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: muted)),
          ],
        ),
      ),

      build: (ctx) => [
        pw.SizedBox(height: 28),

        // MODERNE HERO-SEKTION
        pw.Text('ZEITRAUM',
            style: pw.TextStyle(
                fontSize: 9, color: muted, letterSpacing: 2)),
        pw.SizedBox(height: 4),
        pw.Text('Maerz 2026',
            style: pw.TextStyle(
                fontSize: 30,
                fontWeight: pw.FontWeight.bold,
                color: primaer)),
        pw.SizedBox(height: 2),
        pw.Text(
            '${df.format(zeitraumVon)} bis ${df.format(zeitraumBis)}',
            style: pw.TextStyle(fontSize: 11, color: muted)),
        pw.SizedBox(height: 32),

        // KPI-REIHE - modern mit feinen Trennern
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: pw.BoxDecoration(
            color: tableHeader,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: divider),
          ),
          child: pw.Row(
            children: [
              _kpiC('Gesamtarbeitszeit',
                  '${gesamtStunden.toStringAsFixed(1)} h', primaer, muted, true),
              _kpiTrenner(divider),
              _kpiC('Eintraege', '$eintraege', text, muted, false),
              _kpiTrenner(divider),
              _kpiC('Durchschnitt',
                  '${durchschnitt.toStringAsFixed(1)} h/Tag', text, muted, false),
              _kpiTrenner(divider),
              _kpiC('Ueberstunden',
                  '+${ueberstunden.toStringAsFixed(1)} h', accent, muted, false),
            ],
          ),
        ),
        pw.SizedBox(height: 32),

        // SEKTION I - VERTEILUNG mit Balken (aus A) in Tabellenform
        _sektionTitelC('I', 'Verteilung nach Taetigkeit', primaer),
        pw.SizedBox(height: 14),
        _verteilungC(verteilung, gesamtStunden, primaer, text, muted, divider, tableHeader),
        pw.SizedBox(height: 28),

        // SEKTION II - KENNZAHLEN als strenge Tabelle
        _sektionTitelC('II', 'Zusammenfassung', primaer),
        pw.SizedBox(height: 14),
        _kennzahlenC(
            gesamtStunden: gesamtStunden,
            eintraege: eintraege,
            durchschnitt: durchschnitt,
            ueberstunden: ueberstunden,
            primaer: primaer,
            text: text,
            divider: divider,
            tableHeader: tableHeader,
            warn: warn),
        pw.SizedBox(height: 28),

        // SEKTION III - TAGESAUFLISTUNG
        _sektionTitelC('III', 'Einzelnachweis', primaer),
        pw.SizedBox(height: 14),
        _tageC(tage, primaer, text, muted, divider, tableHeader),
        pw.SizedBox(height: 40),

        // UNTERSCHRIFTEN - behoerdlich, aber schlanker
        _unterschriftenC(text, muted, divider),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _kpiC(String label, String value, PdfColor valueColor,
    PdfColor labelColor, bool hero) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(),
            style: pw.TextStyle(
                fontSize: 8, color: labelColor, letterSpacing: 1)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: hero ? 20 : 16,
                fontWeight: pw.FontWeight.bold,
                color: valueColor)),
      ],
    ),
  );
}

pw.Widget _kpiTrenner(PdfColor c) {
  return pw.Container(
    width: 1,
    height: 32,
    color: c,
    margin: const pw.EdgeInsets.symmetric(horizontal: 16),
  );
}

pw.Widget _sektionTitelC(String nummer, String titel, PdfColor farbe) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Container(
        width: 28,
        height: 28,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: farbe,
          borderRadius: pw.BorderRadius.circular(14),
        ),
        child: pw.Text(nummer,
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white)),
      ),
      pw.SizedBox(width: 10),
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(titel,
            style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: farbe)),
      ),
    ],
  );
}

pw.Widget _verteilungC(Map<String, double> data, double total, PdfColor primaer,
    PdfColor text, PdfColor muted, PdfColor divider, PdfColor tableHeader) {
  final max = data.values.reduce((a, b) => a > b ? a : b);
  return pw.Column(
    children: data.entries.map((e) {
      final anteil = e.value / total * 100;
      final barWidth = (e.value / max) * 240;
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(
              width: 130,
              child: pw.Text(e.key,
                  style: pw.TextStyle(fontSize: 10, color: text)),
            ),
            pw.SizedBox(
              width: 250,
              child: pw.Stack(
                children: [
                  pw.Container(
                    height: 8,
                    width: 240,
                    decoration: pw.BoxDecoration(
                      color: tableHeader,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                  pw.Container(
                    height: 8,
                    width: barWidth,
                    decoration: pw.BoxDecoration(
                      color: primaer,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.SizedBox(
              width: 60,
              child: pw.Text('${e.value.toStringAsFixed(1)} h',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold, color: text)),
            ),
            pw.SizedBox(width: 8),
            pw.SizedBox(
              width: 50,
              child: pw.Text('${anteil.toStringAsFixed(0)} %',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 10, color: muted)),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

pw.Widget _kennzahlenC({
  required double gesamtStunden,
  required int eintraege,
  required double durchschnitt,
  required double ueberstunden,
  required PdfColor primaer,
  required PdfColor text,
  required PdfColor divider,
  required PdfColor tableHeader,
  required PdfColor warn,
}) {
  pw.TableRow row(String label, String wert, {PdfColor? farbe, bool bold = false}) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: pw.Text(label,
              style: pw.TextStyle(fontSize: 10, color: text)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(wert,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: farbe ?? text)),
        ),
      ],
    );
  }

  return pw.Table(
    border: pw.TableBorder.symmetric(
      inside: pw.BorderSide(color: divider, width: 0.5),
      outside: pw.BorderSide(color: divider, width: 0.8),
    ),
    columnWidths: const {
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: tableHeader),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: pw.Text('KENNZAHL',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: primaer,
                    letterSpacing: 1)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            alignment: pw.Alignment.centerRight,
            child: pw.Text('WERT',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: primaer,
                    letterSpacing: 1)),
          ),
        ],
      ),
      row('Anzahl Arbeitszeiteintraege', '$eintraege'),
      row('Gesamtarbeitszeit', '${gesamtStunden.toStringAsFixed(2)} h',
          farbe: primaer, bold: true),
      row('Durchschnitt pro Arbeitstag', '${durchschnitt.toStringAsFixed(2)} h'),
      row('Ueberstundensaldo', '+${ueberstunden.toStringAsFixed(2)} h',
          farbe: warn, bold: true),
    ],
  );
}

pw.Widget _tageC(List<(String, double, String)> tage, PdfColor primaer,
    PdfColor text, PdfColor muted, PdfColor divider, PdfColor tableHeader) {
  return pw.Table(
    columnWidths: const {
      0: pw.FlexColumnWidth(1.2),
      1: pw.FlexColumnWidth(2.5),
      2: pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: tableHeader),
        children: [
          _thC('Datum', primaer),
          _thC('Taetigkeit', primaer),
          _thC('Stunden', primaer, right: true),
        ],
      ),
      ...tage.map((t) => pw.TableRow(
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: divider, width: 0.5)),
            ),
            children: [
              _tdC(t.$1, muted),
              _tdC(t.$3, text),
              _tdC('${t.$2.toStringAsFixed(1)} h', text, right: true, bold: true),
            ],
          )),
    ],
  );
}

pw.Widget _thC(String t, PdfColor primaer, {bool right = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    child: pw.Text(t.toUpperCase(),
        style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: primaer,
            letterSpacing: 1)),
  );
}

pw.Widget _tdC(String t, PdfColor color, {bool right = false, bool bold = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
    alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    child: pw.Text(t,
        style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color)),
  );
}

pw.Widget _unterschriftenC(PdfColor text, PdfColor muted, PdfColor divider) {
  pw.Widget spalte(String label) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
              height: 36,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: text, width: 0.6),
                ),
              )),
          pw.SizedBox(height: 4),
          pw.Text(label,
              style: pw.TextStyle(fontSize: 8, color: muted, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  return pw.Row(
    children: [
      spalte('ORT, DATUM'),
      pw.SizedBox(width: 24),
      spalte('UNTERSCHRIFT MITARBEITER:IN'),
      pw.SizedBox(width: 24),
      spalte('UNTERSCHRIFT TEAMLEITUNG'),
    ],
  );
}
