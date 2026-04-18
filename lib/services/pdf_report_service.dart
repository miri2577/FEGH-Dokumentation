import 'dart:typed_data' show Uint8List;
import 'package:fegh_pdf_kit/fegh_pdf_kit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/arbeitszeit.dart';
import '../models/appointment.dart';
import '../models/client.dart';

/// App-Reports fuer die FEGH-Dokumentation.
///
/// Design-System und Layout-Bausteine kommen aus
/// `package:fegh_pdf_kit/fegh_pdf_kit.dart` (Header, Footer, Hero,
/// KpiRow, SectionHeading, SignatureRow, StandardTable, BarList,
/// EmptyState, PreviewScreen). Hier bleiben nur die App-spezifischen
/// Reports (Arbeitszeit, FLS, Klienten) und deren Tabellen/Karten.
class PdfReportService {
  static const _appName = 'FEGH-Dokumentation';
  static const _appTagline = 'Eingliederungshilfe nach SGB IX';

  // App-interne Aliasse fuer Design-Tokens (Klient-Karten nutzen sie).
  static const PdfColor primaer = PdfDesignTokens.primaer;
  static const PdfColor text = PdfDesignTokens.text;
  static const PdfColor muted = PdfDesignTokens.muted;
  static const PdfColor divider = PdfDesignTokens.divider;
  static const PdfColor accent = PdfDesignTokens.accent;
  static const PdfColor warn = PdfDesignTokens.warn;

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
    final theme = await PdfFontCache.theme();
    final pdf = pw.Document(theme: theme);
    final df = DateFormat('dd.MM.yyyy');

    final stats = _arbeitszeitStats(arbeitszeiten);
    final gesamtH = stats.gesamtStunden;
    final durchschnittH = stats.durchschnittH;
    final zeitraumLabel = _zeitraumLabel(startDate, endDate);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => buildHeader(
        title: 'Arbeitszeit-Bericht',
        appName: _appName,
        appTagline: _appTagline,
        aktenzeichen: aktenzeichen,
      ),
      footer: buildFooter(appName: _appName),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        buildHero(
          label: 'ZEITRAUM',
          title: zeitraumLabel,
          subtitle: '${df.format(startDate)} bis ${df.format(endDate)}',
        ),
        pw.SizedBox(height: 32),
        buildKpiRow([
          PdfKpi(label: 'Gesamtarbeitszeit', value: '${gesamtH.toStringAsFixed(1)} h', color: primaer, hero: true),
          PdfKpi(label: 'Eintraege', value: '${arbeitszeiten.length}', color: text),
          PdfKpi(label: 'Durchschnitt', value: '${durchschnittH.toStringAsFixed(1)} h/Tag', color: text),
          if (stats.ueberstunden.abs() > 0.01)
            PdfKpi(
              label: 'Saldo',
              value: '${stats.ueberstunden >= 0 ? "+" : ""}${stats.ueberstunden.toStringAsFixed(1)} h',
              color: stats.ueberstunden >= 0 ? accent : warn,
            ),
        ]),
        pw.SizedBox(height: 32),
        if (stats.verteilung.isNotEmpty) ...[
          buildSectionHeading('I', 'Verteilung nach Taetigkeit'),
          pw.SizedBox(height: 14),
          buildHorizontalBarList(stats.verteilung, total: gesamtH),
          pw.SizedBox(height: 28),
        ],
        buildSectionHeading(stats.verteilung.isNotEmpty ? 'II' : 'I', 'Einzelnachweis'),
        pw.SizedBox(height: 14),
        if (arbeitszeiten.isEmpty)
          buildEmptyState('Keine Arbeitszeiten im gewaehlten Zeitraum.')
        else
          _arbeitszeitenTabelle(arbeitszeiten),
        pw.SizedBox(height: 40),
        buildSignatureRow(authorName: autor),
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
    final theme = await PdfFontCache.theme();
    final pdf = pw.Document(theme: theme);
    final df = DateFormat('dd.MM.yyyy');

    final relevante = appointments.where((a) => a.fachleistungsstunden > 0).toList();
    final stats = _flsStats(relevante);
    final zeitraumLabel = _zeitraumLabel(startDate, endDate);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
      header: (ctx) => buildHeader(
        title: 'Fachleistungsstunden',
        appName: _appName,
        appTagline: _appTagline,
        aktenzeichen: aktenzeichen,
      ),
      footer: buildFooter(appName: _appName),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        buildHero(
          label: 'ZEITRAUM',
          title: zeitraumLabel,
          subtitle: '${df.format(startDate)} bis ${df.format(endDate)}',
        ),
        pw.SizedBox(height: 32),
        buildKpiRow([
          PdfKpi(label: 'Gesamt-FLS', value: '${stats.gesamt.toStringAsFixed(2)} h', color: primaer, hero: true),
          PdfKpi(label: 'Termine', value: '${relevante.length}', color: text),
          PdfKpi(label: 'Klienten', value: '${stats.proKlient.length}', color: text),
          if (stats.proKlient.isNotEmpty)
            PdfKpi(
              label: 'Top-Klient',
              value: '${stats.proKlient.values.first.toStringAsFixed(1)} h',
              color: accent,
            ),
        ]),
        pw.SizedBox(height: 32),
        if (stats.proKlient.isNotEmpty) ...[
          buildSectionHeading('I', 'Verteilung pro Klient'),
          pw.SizedBox(height: 14),
          buildHorizontalBarList(stats.proKlient, total: stats.gesamt),
          pw.SizedBox(height: 28),
        ],
        buildSectionHeading(stats.proKlient.isNotEmpty ? 'II' : 'I', 'Einzelnachweis'),
        pw.SizedBox(height: 14),
        if (relevante.isEmpty)
          buildEmptyState('Keine Fachleistungsstunden im gewaehlten Zeitraum.')
        else
          _flsTabelle(relevante),
        pw.SizedBox(height: 40),
        buildSignatureRow(authorName: autor),
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
    final theme = await PdfFontCache.theme();
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
      header: (ctx) => buildHeader(
        title: 'Klienten-Uebersicht',
        appName: _appName,
        appTagline: _appTagline,
        aktenzeichen: aktenzeichen,
      ),
      footer: buildFooter(appName: _appName),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        buildHero(
          label: 'ZEITRAUM',
          title: 'Klienten-Uebersicht',
          subtitle: 'Stand ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
        ),
        pw.SizedBox(height: 32),
        buildKpiRow([
          PdfKpi(label: 'Klienten gesamt', value: '${clients.length}', color: primaer, hero: true),
          PdfKpi(
            label: 'Mit Einwilligung',
            value: '$mitEinwilligung / ${clients.length}',
            color: mitEinwilligung == clients.length ? accent : warn,
          ),
          if (totalFlsBewilligt > 0)
            PdfKpi(
              label: 'FLS bewilligt',
              value: '${totalFlsBewilligt.toStringAsFixed(0)} h',
              color: text,
            ),
          if (totalFlsBewilligt > 0)
            PdfKpi(
              label: 'Auslastung',
              value: '${auslastung.toStringAsFixed(0)} %',
              color: auslastung >= 90 ? warn : (auslastung >= 75 ? accent : text),
            ),
        ]),
        pw.SizedBox(height: 32),
        buildSectionHeading('I', 'Klienten-Liste'),
        pw.SizedBox(height: 14),
        if (clients.isEmpty)
          buildEmptyState('Keine Klienten erfasst.')
        else
          _klientenTabelle(clients),
        pw.SizedBox(height: 40),
        buildSignatureRow(authorName: autor),
      ],
    ));
    return pdf.save();
  }

  // ═════════════════════════════════════════════════════════════════
  // APP-SPEZIFISCHE TABELLEN UND KARTEN
  // ═════════════════════════════════════════════════════════════════

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
        buildTableHeader(
          ['Datum', 'Zeit', 'Taetigkeit', 'Stunden'],
          alignRight: const [false, false, false, true],
        ),
        ...sorted.map((a) {
          final stunden = (a.arbeitszeit.inMinutes / 60.0).toStringAsFixed(2);
          return buildTableRow(
            [
              DateFormat('dd.MM.yyyy').format(a.datum),
              '${a.formatierteStartzeit} - ${a.formatierteEndzeit}',
              a.taetigkeit,
              '$stunden h',
            ],
            alignRight: const [false, false, false, true],
          );
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
        buildTableHeader(
          ['Datum', 'Zeit', 'Klient', 'FLS'],
          alignRight: const [false, false, false, true],
        ),
        ...sorted.map((a) {
          return buildTableRow(
            [
              DateFormat('dd.MM.yyyy').format(a.date),
              '${DateFormat('HH:mm').format(a.startTime)} - ${DateFormat('HH:mm').format(a.endTime)}',
              a.clientName,
              '${a.fachleistungsstunden.toStringAsFixed(2)} h',
            ],
            alignRight: const [false, false, false, true],
          );
        }),
      ],
    );
  }

  static pw.Widget _klientenTabelle(List<Client> list) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: list.map(_klientKarte).toList(),
    );
  }

  static pw.Widget _klientKarte(Client c) {
    final hatFls = c.fachleistungsstunden != null;
    final prozent = hatFls ? c.stundenverbrauchProzent : 0.0;
    final einwilligungFarbe = c.einwilligungVorhanden ? accent : warn;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfDesignTokens.tableHeader,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: divider, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Text(
                  c.vollstaendigerName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: primaer,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: PdfColor(einwilligungFarbe.red, einwilligungFarbe.green,
                      einwilligungFarbe.blue, 0.15),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  c.einwilligungVorhanden ? 'Einwilligung: Ja' : 'Einwilligung: Nein',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: einwilligungFarbe,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (c.kostenuebernahme != null && c.kostenuebernahme!.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              c.kostenuebernahme!,
              style: pw.TextStyle(fontSize: 10, color: muted),
            ),
          ],
          if (hatFls) ...[
            pw.SizedBox(height: 10),
            _klientFlsBalken(c, prozent),
          ],
        ],
      ),
    );
  }

  static pw.Widget _klientFlsBalken(Client c, double prozent) {
    final bewilligt = c.fachleistungsstunden!;
    final verbraucht = c.verbrauchteStunden;
    final PdfColor balkenFarbe = prozent >= 90
        ? warn
        : (prozent >= 75 ? PdfDesignTokens.warnSoft : accent);
    const breiteGesamt = 320.0;
    final breiteVerbraucht = (prozent.clamp(0, 100) / 100.0) * breiteGesamt;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Fachleistungsstunden',
                      style: pw.TextStyle(fontSize: 9, color: muted)),
                  pw.Text(
                    '${verbraucht.toStringAsFixed(1)} / $bewilligt h  (${prozent.toStringAsFixed(0)} %)',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: text,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Stack(
                children: [
                  pw.Container(
                    height: 6,
                    width: breiteGesamt,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(3),
                      border: pw.Border.all(color: divider, width: 0.5),
                    ),
                  ),
                  pw.Container(
                    height: 6,
                    width: breiteVerbraucht,
                    decoration: pw.BoxDecoration(
                      color: balkenFarbe,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Statistik-Helfer ────────────────────────────────────────────

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

// ── Hilfsklassen ─────────────────────────────────────────────────────

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
