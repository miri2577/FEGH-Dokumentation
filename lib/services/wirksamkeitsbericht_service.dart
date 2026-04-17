import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../models/teilhabeziel.dart';
import '../models/zielmessung.dart';
import '../models/pos_messung.dart';
import 'wirkungsmessung_service.dart';

/// Erzeugt Wirksamkeitsberichte nach §128 SGB IX als PDF.
/// Enthaelt Teilhabeziele, GAS-Verlaeufe und POS-Lebensqualitaet.
class WirksamkeitsberichtService {
  static const _primary = PdfColor.fromInt(0xFF1976D2);
  static const _dark = PdfColor.fromInt(0xFF424242);
  static const _light = PdfColor.fromInt(0xFFE0E0E0);
  static const _good = PdfColor.fromInt(0xFF2E7D32);
  static const _bad = PdfColor.fromInt(0xFFC62828);
  static const _neutral = PdfColor.fromInt(0xFF757575);

  final _service = WirkungsmessungService();

  /// Erstellt einen Wirksamkeitsbericht fuer einen einzelnen Klienten.
  Future<Uint8List> generateClientReport({
    required Client client,
    DateTime? von,
    DateTime? bis,
    String? autor,
  }) async {
    final pdf = pw.Document();
    final df = DateFormat('dd.MM.yyyy');
    final zeitraumText = (von != null && bis != null)
        ? '${df.format(von)} - ${df.format(bis)}'
        : 'Gesamter Verlauf';

    final ziele = await _service.zieleFuerClient(client.id);
    final messungenMap = <String, List<Zielmessung>>{};
    for (final z in ziele) {
      var msgs = await _service.messungenFuerZiel(z.id);
      if (von != null) msgs = msgs.where((m) => !m.messdatum.isBefore(von)).toList();
      if (bis != null) msgs = msgs.where((m) => !m.messdatum.isAfter(bis)).toList();
      messungenMap[z.id] = msgs;
    }
    var pos = await _service.posMessungenFuerClient(client.id);
    if (von != null) pos = pos.where((m) => !m.messdatum.isBefore(von)).toList();
    if (bis != null) pos = pos.where((m) => !m.messdatum.isAfter(bis)).toList();
    pos.sort((a, b) => a.messdatum.compareTo(b.messdatum));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _header('Wirksamkeitsbericht nach §128 SGB IX'),
        footer: _footer,
        build: (ctx) => [
          _title('Wirksamkeitsbericht'),
          pw.SizedBox(height: 16),
          _clientInfo(client, zeitraumText, autor),
          pw.SizedBox(height: 20),
          _section('1. Zusammenfassung'),
          pw.SizedBox(height: 8),
          _zusammenfassung(ziele, messungenMap, pos),
          pw.SizedBox(height: 20),
          _section('2. Teilhabeziele nach SMART-Kriterien'),
          pw.SizedBox(height: 8),
          if (ziele.isEmpty)
            _hinweis('Keine Teilhabeziele im Zeitraum erfasst.')
          else
            ...ziele.map((z) => _zielAbschnitt(z, messungenMap[z.id] ?? [])),
          pw.SizedBox(height: 20),
          _section('3. Lebensqualitaet (Personal Outcomes Scale)'),
          pw.SizedBox(height: 8),
          if (pos.isEmpty)
            _hinweis('Keine POS-Messung im Zeitraum vorhanden.')
          else
            _posAbschnitt(pos),
          pw.SizedBox(height: 20),
          _section('4. Fazit'),
          pw.SizedBox(height: 8),
          _fazit(ziele, messungenMap, pos),
          pw.SizedBox(height: 30),
          _unterschrift(autor),
        ],
      ),
    );
    return pdf.save();
  }

  // ── Bausteine ────────────────────────────────────────────────────

  pw.Widget _header(String titel) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('FEGH-Dokumentation',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _primary)),
          pw.Text(titel, style: const pw.TextStyle(fontSize: 11, color: _dark)),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _light)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Seite ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: _dark)),
          pw.Text('Erstellt am ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: _dark)),
        ],
      ),
    );
  }

  pw.Widget _title(String t) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: _primary, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Text(t,
          style: pw.TextStyle(
              fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  pw.Widget _section(String t) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(color: _light, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Text(t,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _dark)),
    );
  }

  pw.Widget _clientInfo(Client c, String zeitraum, String? autor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _light),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _infoRow('Klient:in', c.vollstaendigerName),
          if (c.klientenId != null) _infoRow('Klienten-ID', c.klientenId!),
          _infoRow('Zeitraum', zeitraum),
          _infoRow('Bericht erstellt', DateFormat('dd.MM.yyyy').format(DateTime.now())),
          if (autor != null) _infoRow('Ersteller:in', autor),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String wert) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.SizedBox(width: 110, child: pw.Text('$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
        pw.Expanded(child: pw.Text(wert, style: const pw.TextStyle(fontSize: 11))),
      ]),
    );
  }

  pw.Widget _hinweis(String t) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(t,
          style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: _neutral, fontSize: 11)),
    );
  }

  pw.Widget _zusammenfassung(List<Teilhabeziel> ziele,
      Map<String, List<Zielmessung>> messungen, List<PosMessung> pos) {
    final aktive = ziele.where((z) => z.status == TeilhabezielStatus.aktiv).length;
    final erreicht = ziele.where((z) => z.status == TeilhabezielStatus.erreicht).length;
    final allMsgs = messungen.values.expand((e) => e).toList();
    final gasSchnitt = allMsgs.isEmpty
        ? null
        : allMsgs.fold<int>(0, (s, m) => s + m.bewertung.wert) / allMsgs.length;
    final posDiff = pos.length >= 2 ? pos.last.gesamtProzent - pos.first.gesamtProzent : null;

    return pw.Table(
      border: pw.TableBorder.all(color: _light),
      children: [
        _tableRow(['Kennzahl', 'Wert'], header: true),
        _tableRow(['Aktive Teilhabeziele', '$aktive']),
        _tableRow(['Erreichte Ziele', '$erreicht']),
        _tableRow([
          'GAS-Durchschnitt (alle Messungen)',
          gasSchnitt == null
              ? '-'
              : '${gasSchnitt >= 0 ? "+" : ""}${gasSchnitt.toStringAsFixed(2)}'
        ]),
        _tableRow([
          'POS gesamt (letzte Messung)',
          pos.isEmpty ? '-' : '${pos.last.gesamtProzent.toStringAsFixed(1)}%'
        ]),
        if (posDiff != null)
          _tableRow([
            'POS-Entwicklung (Baseline -> Aktuell)',
            '${posDiff >= 0 ? "+" : ""}${posDiff.toStringAsFixed(1)}%'
          ]),
      ],
    );
  }

  pw.TableRow _tableRow(List<String> zellen, {bool header = false}) {
    return pw.TableRow(
      decoration: header ? const pw.BoxDecoration(color: _light) : null,
      children: zellen
          .map((t) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(t,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
                    )),
              ))
          .toList(),
    );
  }

  pw.Widget _zielAbschnitt(Teilhabeziel z, List<Zielmessung> msgs) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _light),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(z.titel,
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              _statusBadge(z.status),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${z.kategorieDisplayName} - Prio ${z.prioritaet}/5'
            '${z.icfBereich != null ? " - ICF: ${z.icfBereich}" : ""}',
            style: const pw.TextStyle(fontSize: 9, color: _dark),
          ),
          if (z.beschreibung.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(z.beschreibung, style: const pw.TextStyle(fontSize: 10)),
          ],
          if (z.spezifisch != null || z.messbar != null || z.attraktiv != null || z.realistisch != null) ...[
            pw.SizedBox(height: 6),
            pw.Text('SMART-Kriterien:',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            if (z.spezifisch != null) _smartZeile('S', z.spezifisch!),
            if (z.messbar != null) _smartZeile('M', z.messbar!),
            if (z.attraktiv != null) _smartZeile('A', z.attraktiv!),
            if (z.realistisch != null) _smartZeile('R', z.realistisch!),
            if (z.terminiert != null)
              _smartZeile('T', DateFormat('dd.MM.yyyy').format(z.terminiert!)),
          ],
          pw.SizedBox(height: 8),
          pw.Text('Messungen (${msgs.length}):',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          if (msgs.isEmpty)
            pw.Text('Noch keine Messungen erfasst.',
                style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: _neutral))
          else
            _messungenTabelle(msgs),
        ],
      ),
    );
  }

  pw.Widget _smartZeile(String buchstabe, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 4, top: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 14,
            child: pw.Text(buchstabe,
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primary)),
          ),
          pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  pw.Widget _statusBadge(TeilhabezielStatus s) {
    PdfColor c;
    String t;
    switch (s) {
      case TeilhabezielStatus.aktiv:
        c = _primary; t = 'AKTIV'; break;
      case TeilhabezielStatus.erreicht:
        c = _good; t = 'ERREICHT'; break;
      case TeilhabezielStatus.pausiert:
        c = const PdfColor.fromInt(0xFFEF6C00); t = 'PAUSIERT'; break;
      case TeilhabezielStatus.abgebrochen:
        c = _neutral; t = 'ABGEBROCHEN'; break;
    }
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColor(c.red, c.green, c.blue, 0.15),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: c)),
    );
  }

  pw.Widget _messungenTabelle(List<Zielmessung> msgs) {
    return pw.Table(
      border: pw.TableBorder.all(color: _light),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.0),
        3: pw.FlexColumnWidth(3.0),
      },
      children: [
        _tableRow(['Datum', 'Typ', 'GAS', 'Kommentar'], header: true),
        ...msgs.map((m) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(DateFormat('dd.MM.yyyy').format(m.messdatum),
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(_typName(m.typ),
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                      '${m.bewertung.wert >= 0 ? "+" : ""}${m.bewertung.wert}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: m.bewertung.wert > 0
                            ? _good
                            : (m.bewertung.wert < 0 ? _bad : _neutral),
                      )),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(m.kommentar ?? '',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
              ],
            )),
      ],
    );
  }

  String _typName(MesszeitpunktTyp t) {
    switch (t) {
      case MesszeitpunktTyp.baseline: return 'Baseline';
      case MesszeitpunktTyp.zwischenmessung: return 'Zwischen';
      case MesszeitpunktTyp.endmessung: return 'Endmessung';
      case MesszeitpunktTyp.adhoc: return 'Ad hoc';
    }
  }

  pw.Widget _posAbschnitt(List<PosMessung> pos) {
    final baseline = pos.first;
    final letzte = pos.last;
    final hatVergleich = pos.length >= 2;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          hatVergleich
              ? 'Vergleich Baseline vs. aktuelle Messung (${pos.length} Messungen insgesamt)'
              : 'Einzige Messung vom ${DateFormat('dd.MM.yyyy').format(letzte.messdatum)}',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _light),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.5),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(1),
          },
          children: [
            _tableRow(
              hatVergleich
                  ? ['Domaene', 'Baseline', 'Aktuell', 'Entwicklung']
                  : ['Domaene', 'Punkte', 'Prozent', ''],
              header: true,
            ),
            ...PosDomaene.values.map((d) {
              final aktuell = letzte.domaeneProzent(d);
              final basis = baseline.domaeneProzent(d);
              final diff = aktuell - basis;
              if (hatVergleich) {
                return pw.TableRow(children: [
                  _cell(d.displayName, bold: true),
                  _cell('${basis.toStringAsFixed(0)}%'),
                  _cell('${aktuell.toStringAsFixed(0)}%'),
                  _cell(
                    '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(0)}%',
                    color: diff > 0 ? _good : (diff < 0 ? _bad : _neutral),
                    bold: true,
                  ),
                ]);
              }
              return pw.TableRow(children: [
                _cell(d.displayName, bold: true),
                _cell('${letzte.domaenePunkte(d)}/18'),
                _cell('${aktuell.toStringAsFixed(0)}%'),
                _cell(''),
              ]);
            }),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _light),
              children: hatVergleich
                  ? [
                      _cell('GESAMT', bold: true),
                      _cell('${baseline.gesamtProzent.toStringAsFixed(0)}%', bold: true),
                      _cell('${letzte.gesamtProzent.toStringAsFixed(0)}%', bold: true),
                      _cell(
                        '${letzte.gesamtProzent - baseline.gesamtProzent >= 0 ? "+" : ""}${(letzte.gesamtProzent - baseline.gesamtProzent).toStringAsFixed(1)}%',
                        bold: true,
                        color: letzte.gesamtProzent >= baseline.gesamtProzent ? _good : _bad,
                      ),
                    ]
                  : [
                      _cell('GESAMT', bold: true),
                      _cell('${letzte.gesamtPunkte}/144', bold: true),
                      _cell('${letzte.gesamtProzent.toStringAsFixed(1)}%', bold: true),
                      _cell(''),
                    ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _cell(String t, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(t,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? _dark,
          )),
    );
  }

  pw.Widget _fazit(List<Teilhabeziel> ziele,
      Map<String, List<Zielmessung>> messungen, List<PosMessung> pos) {
    final allMsgs = messungen.values.expand((e) => e).toList();
    final gasSchnitt = allMsgs.isEmpty
        ? null
        : allMsgs.fold<int>(0, (s, m) => s + m.bewertung.wert) / allMsgs.length;
    final erreicht = ziele.where((z) => z.status == TeilhabezielStatus.erreicht).length;
    final posDiff = pos.length >= 2 ? pos.last.gesamtProzent - pos.first.gesamtProzent : null;

    final bewertung = <String>[];
    if (erreicht > 0) {
      bewertung.add('$erreicht Ziel${erreicht == 1 ? "" : "e"} wurde${erreicht == 1 ? "" : "n"} erfolgreich erreicht.');
    }
    if (gasSchnitt != null) {
      if (gasSchnitt > 0.5) {
        bewertung.add('Die GAS-Werte zeigen eine insgesamt positive Zielerreichung (Schnitt ${gasSchnitt.toStringAsFixed(1)}).');
      } else if (gasSchnitt < -0.5) {
        bewertung.add('Die GAS-Werte zeigen insgesamt Entwicklungsbedarf (Schnitt ${gasSchnitt.toStringAsFixed(1)}).');
      } else {
        bewertung.add('Die Ziele werden weitgehend wie erwartet erreicht (GAS-Schnitt ${gasSchnitt.toStringAsFixed(1)}).');
      }
    }
    if (posDiff != null) {
      if (posDiff > 5) {
        bewertung.add('Die Lebensqualitaet hat sich messbar verbessert (+${posDiff.toStringAsFixed(1)}%).');
      } else if (posDiff < -5) {
        bewertung.add('Die Lebensqualitaet zeigt einen Rueckgang (${posDiff.toStringAsFixed(1)}%).');
      } else {
        bewertung.add('Die Lebensqualitaet ist weitgehend stabil (${posDiff >= 0 ? "+" : ""}${posDiff.toStringAsFixed(1)}%).');
      }
    }
    if (bewertung.isEmpty) {
      bewertung.add('Es liegen noch zu wenige Messungen fuer eine belastbare Wirkungsaussage vor.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: bewertung
          .map((t) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(child: pw.Text(t, style: const pw.TextStyle(fontSize: 11))),
                  ],
                ),
              ))
          .toList(),
    );
  }

  pw.Widget _unterschrift(String? autor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 200, height: 1, color: _dark),
          pw.SizedBox(height: 4),
          pw.Text('Unterschrift ${autor ?? "Fachkraft"}',
              style: const pw.TextStyle(fontSize: 10, color: _dark)),
        ],
      ),
    );
  }
}
