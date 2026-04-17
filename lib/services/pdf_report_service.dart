import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/arbeitszeit.dart';
import '../models/appointment.dart';
import '../models/client.dart';

/// Einheitliches PDF-Design-System fuer alle App-Reports.
///
/// Hybrid-Stil: behoerdlicher Kopf + Unterschriften, moderne Typografie
/// und Balken-Diagramme. Robotofont eingebettet fuer korrekte Umlaute.
class PdfReportService {
  // ── Design-Tokens ────────────────────────────────────────────────
  static const PdfColor primaer = PdfColor.fromInt(0xFF1E3A5F);
  static const PdfColor text = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor divider = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor accent = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor warn = PdfColor.fromInt(0xFFB91C1C);
  static const PdfColor tableHeader = PdfColor.fromInt(0xFFF3F4F6);

  // ── Font-Cache (einmalig geladen) ────────────────────────────────
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<pw.ThemeData> _theme() async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    return pw.ThemeData.withFont(
      base: _regular!,
      bold: _bold!,
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // OEFFENTLICHE REPORT-METHODEN
  // ═════════════════════════════════════════════════════════════════

  /// Arbeitszeit-Report mit Verteilung und Tagesliste.
  static Future<Uint8List> generateArbeitszeitenReport({
    required List<Arbeitszeit> arbeitszeiten,
    required DateTime startDate,
    required DateTime endDate,
    String? autor,
    String? aktenzeichen,
  }) async {
    final theme = await _theme();
    final pdf = pw.Document(theme: theme);
    final df = DateFormat('dd.MM.yyyy');

    final stats = _arbeitszeitStats(arbeitszeiten);
    final gesamtH = stats.gesamtStunden;
    final durchschnittH = stats.durchschnittH;
    final zeitraumLabel = _zeitraumLabel(startDate, endDate);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => _header('Arbeitszeit-Bericht', aktenzeichen),
      footer: _footer,
      build: (ctx) => [
        pw.SizedBox(height: 20),
        _hero(titel: zeitraumLabel,
            untertitel: '${df.format(startDate)} bis ${df.format(endDate)}'),
        pw.SizedBox(height: 32),
        _kpiReihe([
          _KpiDaten('Gesamtarbeitszeit', '${gesamtH.toStringAsFixed(1)} h', primaer, hero: true),
          _KpiDaten('Eintraege', '${arbeitszeiten.length}', text),
          _KpiDaten('Durchschnitt', '${durchschnittH.toStringAsFixed(1)} h/Tag', text),
          if (stats.ueberstunden.abs() > 0.01)
            _KpiDaten(
              'Saldo',
              '${stats.ueberstunden >= 0 ? "+" : ""}${stats.ueberstunden.toStringAsFixed(1)} h',
              stats.ueberstunden >= 0 ? accent : warn,
            ),
        ]),
        pw.SizedBox(height: 32),

        if (stats.verteilung.isNotEmpty) ...[
          _sektion('I', 'Verteilung nach Taetigkeit'),
          pw.SizedBox(height: 14),
          _balken(stats.verteilung, gesamtH),
          pw.SizedBox(height: 28),
        ],

        _sektion(stats.verteilung.isNotEmpty ? 'II' : 'I', 'Einzelnachweis'),
        pw.SizedBox(height: 14),
        if (arbeitszeiten.isEmpty)
          _keineDaten('Keine Arbeitszeiten im gewaehlten Zeitraum.')
        else
          _arbeitszeitenTabelle(arbeitszeiten),
        pw.SizedBox(height: 40),
        _unterschriften(autor),
      ],
    ));
    return pdf.save();
  }

  /// Fachleistungsstunden-Report pro Klient.
  static Future<Uint8List> generateFachleistungsstundenReport({
    required List<Appointment> appointments,
    required DateTime startDate,
    required DateTime endDate,
    String? autor,
    String? aktenzeichen,
  }) async {
    final theme = await _theme();
    final pdf = pw.Document(theme: theme);
    final df = DateFormat('dd.MM.yyyy');

    final relevante = appointments.where((a) => a.fachleistungsstunden > 0).toList();
    final stats = _flsStats(relevante);
    final zeitraumLabel = _zeitraumLabel(startDate, endDate);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => _header('Fachleistungsstunden', aktenzeichen),
      footer: _footer,
      build: (ctx) => [
        pw.SizedBox(height: 20),
        _hero(titel: zeitraumLabel,
            untertitel: '${df.format(startDate)} bis ${df.format(endDate)}'),
        pw.SizedBox(height: 32),
        _kpiReihe([
          _KpiDaten('Gesamt-FLS', '${stats.gesamt.toStringAsFixed(2)} h', primaer, hero: true),
          _KpiDaten('Termine', '${relevante.length}', text),
          _KpiDaten('Klienten', '${stats.proKlient.length}', text),
          if (stats.proKlient.isNotEmpty)
            _KpiDaten('Top-Klient', '${stats.proKlient.values.first.toStringAsFixed(1)} h', accent),
        ]),
        pw.SizedBox(height: 32),

        if (stats.proKlient.isNotEmpty) ...[
          _sektion('I', 'Verteilung pro Klient'),
          pw.SizedBox(height: 14),
          _balken(stats.proKlient, stats.gesamt),
          pw.SizedBox(height: 28),
        ],

        _sektion(stats.proKlient.isNotEmpty ? 'II' : 'I', 'Einzelnachweis'),
        pw.SizedBox(height: 14),
        if (relevante.isEmpty)
          _keineDaten('Keine Fachleistungsstunden im gewaehlten Zeitraum.')
        else
          _flsTabelle(relevante),
        pw.SizedBox(height: 40),
        _unterschriften(autor),
      ],
    ));
    return pdf.save();
  }

  /// Klienten-Uebersicht als Report.
  static Future<Uint8List> generateKlientenReport({
    required List<Client> clients,
    String? autor,
    String? aktenzeichen,
  }) async {
    final theme = await _theme();
    final pdf = pw.Document(theme: theme);

    int mitEinwilligung = 0;
    double totalFlsBewilligt = 0;
    double totalFlsVerbraucht = 0;
    for (final c in clients) {
      if (c.einwilligungVorhanden) mitEinwilligung++;
      if (c.fachleistungsstunden != null) {
        totalFlsBewilligt += c.fachleistungsstunden!.toDouble();
        totalFlsVerbraucht += c.verbrauchteStunden;
      }
    }
    final auslastung = totalFlsBewilligt > 0
        ? (totalFlsVerbraucht / totalFlsBewilligt * 100)
        : 0.0;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => _header('Klienten-Uebersicht', aktenzeichen),
      footer: _footer,
      build: (ctx) => [
        pw.SizedBox(height: 20),
        _hero(titel: 'Klienten-Uebersicht',
            untertitel: 'Stand ${DateFormat('dd.MM.yyyy').format(DateTime.now())}'),
        pw.SizedBox(height: 32),
        _kpiReihe([
          _KpiDaten('Klienten gesamt', '${clients.length}', primaer, hero: true),
          _KpiDaten('Mit Einwilligung', '$mitEinwilligung / ${clients.length}',
              mitEinwilligung == clients.length ? accent : warn),
          if (totalFlsBewilligt > 0)
            _KpiDaten('FLS bewilligt', '${totalFlsBewilligt.toStringAsFixed(0)} h', text),
          if (totalFlsBewilligt > 0)
            _KpiDaten('Auslastung', '${auslastung.toStringAsFixed(0)} %',
                auslastung >= 90 ? warn : (auslastung >= 75 ? accent : text)),
        ]),
        pw.SizedBox(height: 32),

        _sektion('I', 'Klienten-Liste'),
        pw.SizedBox(height: 14),
        if (clients.isEmpty)
          _keineDaten('Keine Klienten erfasst.')
        else
          _klientenTabelle(clients),
        pw.SizedBox(height: 40),
        _unterschriften(autor),
      ],
    ));
    return pdf.save();
  }

  // ═════════════════════════════════════════════════════════════════
  // GEMEINSAME BAUSTEINE (Design-System)
  // ═════════════════════════════════════════════════════════════════

  static pw.Widget _header(String titel, String? aktenzeichen) {
    return pw.Container(
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
                      fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaer)),
              pw.SizedBox(height: 2),
              pw.Text('Eingliederungshilfe nach SGB IX',
                  style: pw.TextStyle(fontSize: 8, color: muted)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(titel.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 9, color: muted, letterSpacing: 2)),
              if (aktenzeichen != null && aktenzeichen.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text('AZ: $aktenzeichen',
                    style: pw.TextStyle(fontSize: 8, color: muted)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
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
    );
  }

  static pw.Widget _hero({required String titel, required String untertitel}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ZEITRAUM',
            style: pw.TextStyle(fontSize: 9, color: muted, letterSpacing: 2)),
        pw.SizedBox(height: 4),
        pw.Text(titel,
            style: pw.TextStyle(
                fontSize: 30, fontWeight: pw.FontWeight.bold, color: primaer)),
        pw.SizedBox(height: 2),
        pw.Text(untertitel,
            style: pw.TextStyle(fontSize: 11, color: muted)),
      ],
    );
  }

  static pw.Widget _kpiReihe(List<_KpiDaten> kpis) {
    final widgets = <pw.Widget>[];
    for (int i = 0; i < kpis.length; i++) {
      widgets.add(pw.Expanded(child: _kpi(kpis[i])));
      if (i < kpis.length - 1) {
        widgets.add(pw.Container(
          width: 1,
          height: 32,
          color: divider,
          margin: const pw.EdgeInsets.symmetric(horizontal: 16),
        ));
      }
    }
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: pw.BoxDecoration(
        color: tableHeader,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: divider),
      ),
      child: pw.Row(children: widgets),
    );
  }

  static pw.Widget _kpi(_KpiDaten k) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(k.label.toUpperCase(),
            style: pw.TextStyle(fontSize: 8, color: muted, letterSpacing: 1)),
        pw.SizedBox(height: 4),
        pw.Text(k.value,
            style: pw.TextStyle(
                fontSize: k.hero ? 20 : 16,
                fontWeight: pw.FontWeight.bold,
                color: k.farbe)),
      ],
    );
  }

  static pw.Widget _sektion(String nummer, String titel) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          width: 28,
          height: 28,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: primaer,
            borderRadius: pw.BorderRadius.circular(14),
          ),
          child: pw.Text(nummer,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        ),
        pw.SizedBox(width: 10),
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Text(titel,
              style: pw.TextStyle(
                  fontSize: 15, fontWeight: pw.FontWeight.bold, color: primaer)),
        ),
      ],
    );
  }

  static pw.Widget _balken(Map<String, double> data, double total) {
    if (data.isEmpty) return pw.SizedBox();
    final sortiert = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sortiert.first.value;
    return pw.Column(
      children: sortiert.map((e) {
        final anteil = total > 0 ? e.value / total * 100 : 0;
        final barWidth = max > 0 ? (e.value / max) * 240 : 0.0;
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                width: 140,
                child: pw.Text(e.key,
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                    style: pw.TextStyle(fontSize: 10, color: text)),
              ),
              pw.SizedBox(
                width: 250,
                child: pw.Stack(children: [
                  pw.Container(
                    height: 8, width: 240,
                    decoration: pw.BoxDecoration(
                      color: tableHeader,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                  pw.Container(
                    height: 8, width: barWidth,
                    decoration: pw.BoxDecoration(
                      color: primaer,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                ]),
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

  static pw.Widget _unterschriften(String? autor) {
    pw.Widget spalte(String label) {
      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
                height: 36,
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: text, width: 0.6)),
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
        spalte(autor != null && autor.isNotEmpty
            ? 'UNTERSCHRIFT ${autor.toUpperCase()}'
            : 'UNTERSCHRIFT MITARBEITER:IN'),
        pw.SizedBox(width: 24),
        spalte('UNTERSCHRIFT TEAMLEITUNG'),
      ],
    );
  }

  static pw.Widget _keineDaten(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: tableHeader,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 11, fontStyle: pw.FontStyle.italic, color: muted)),
    );
  }

  // ── Tabellen-Helper ──────────────────────────────────────────────

  static pw.Widget _arbeitszeitenTabelle(List<Arbeitszeit> list) {
    final sorted = List<Arbeitszeit>.from(list)
      ..sort((a, b) => a.datum.compareTo(b.datum));
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(2.5),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        _tabelleKopf(['Datum', 'Zeit', 'Taetigkeit', 'Stunden'], [false, false, false, true]),
        ...sorted.map((a) {
          final stunden = (a.arbeitszeit.inMinutes / 60.0).toStringAsFixed(2);
          return _tabelleZeile([
            DateFormat('dd.MM.yyyy').format(a.datum),
            '${a.formatierteStartzeit} - ${a.formatierteEndzeit}',
            a.taetigkeit,
            '$stunden h',
          ], [false, false, false, true]);
        }),
      ],
    );
  }

  static pw.Widget _flsTabelle(List<Appointment> list) {
    final sorted = List<Appointment>.from(list)
      ..sort((a, b) => a.date.compareTo(b.date));
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(2.5),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        _tabelleKopf(['Datum', 'Zeit', 'Klient', 'FLS'], [false, false, false, true]),
        ...sorted.map((a) {
          return _tabelleZeile([
            DateFormat('dd.MM.yyyy').format(a.date),
            '${DateFormat('HH:mm').format(a.startTime)} - ${DateFormat('HH:mm').format(a.endTime)}',
            a.clientName,
            '${a.fachleistungsstunden.toStringAsFixed(2)} h',
          ], [false, false, false, true]);
        }),
      ],
    );
  }

  static pw.Widget _klientenTabelle(List<Client> list) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(0.8),
      },
      children: [
        _tabelleKopf(
            ['Name', 'Kostentraeger', 'FLS bewilligt', 'Verbraucht', 'Einwill.'],
            [false, false, true, true, false]),
        ...list.map((c) {
          final bew = c.fachleistungsstunden != null ? '${c.fachleistungsstunden} h' : '-';
          final verb = c.fachleistungsstunden != null
              ? '${c.verbrauchteStunden.toStringAsFixed(1)} h (${c.stundenverbrauchProzent.toStringAsFixed(0)} %)'
              : '-';
          return _tabelleZeile([
            c.vollstaendigerName,
            c.kostenuebernahme ?? '-',
            bew,
            verb,
            c.einwilligungVorhanden ? 'ja' : 'nein',
          ], [false, false, true, true, false],
              warnIdx: c.einwilligungVorhanden ? null : 4);
        }),
      ],
    );
  }

  static pw.TableRow _tabelleKopf(List<String> texte, List<bool> rechts) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: tableHeader),
      children: List.generate(texte.length, (i) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          alignment: rechts[i] ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          child: pw.Text(texte[i].toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: primaer,
                  letterSpacing: 1)),
        );
      }),
    );
  }

  static pw.TableRow _tabelleZeile(List<String> texte, List<bool> rechts, {int? warnIdx}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: divider, width: 0.5)),
      ),
      children: List.generate(texte.length, (i) {
        final farbe = (warnIdx != null && i == warnIdx) ? warn : text;
        final bold = (warnIdx != null && i == warnIdx) ||
            (rechts[i] && texte[i].contains('h'));
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
          alignment: rechts[i] ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          child: pw.Text(texte[i],
              maxLines: 2,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                  fontSize: 10,
                  color: farbe,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        );
      }),
    );
  }

  // ── Statistik-Helfer ─────────────────────────────────────────────

  static _ArbeitszeitStats _arbeitszeitStats(List<Arbeitszeit> list) {
    double gesamt = 0;
    final verteilung = <String, double>{};
    final tage = <DateTime>{};
    for (final a in list) {
      final h = a.arbeitszeit.inMinutes / 60.0;
      gesamt += h;
      final typ = a.typ.displayName;
      verteilung[typ] = (verteilung[typ] ?? 0) + h;
      tage.add(DateTime(a.datum.year, a.datum.month, a.datum.day));
    }
    final arbeitstage = tage.isEmpty ? 1 : tage.length;
    final durchschnitt = gesamt / arbeitstage;
    final sollStunden = arbeitstage * 8.0;
    final saldo = gesamt - sollStunden;
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
      'Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];
    if (start.year == end.year && start.month == end.month) {
      return '${monate[start.month - 1]} ${start.year}';
    }
    if (start.year == end.year) {
      return '${start.year}';
    }
    return '${start.year} - ${end.year}';
  }
}

// ── Hilfsklassen ───────────────────────────────────────────────────

class _KpiDaten {
  final String label;
  final String value;
  final PdfColor farbe;
  final bool hero;
  _KpiDaten(this.label, this.value, this.farbe, {this.hero = false});
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
