import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../models/arbeitszeit.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../models/informationsbericht.dart';
import '../providers/app_provider.dart';

class PdfGeneratorService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF1976D2);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF0D47A1);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF2196F3);
  static const PdfColor lightGray = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor darkGray = PdfColor.fromInt(0xFF424242);

  static Future<Uint8List> generateArbeitszeitenPDF(
    String content,
    List<Arbeitszeit> arbeitszeiten,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final pdf = pw.Document();

    // Statistiken berechnen
    final stats = _calculateArbeitszeitStats(arbeitszeiten);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Arbeitszeit-Export'),
        footer: (context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            _buildTitle('Arbeitszeit-Export'),
            pw.SizedBox(height: 10),
            _buildDateRange(startDate, endDate),
            pw.SizedBox(height: 20),

            // Übersichts-Statistiken
            _buildStatsCards(stats),
            pw.SizedBox(height: 30),

            // Tortendiagramm für Tätigkeitsverteilung
            if (stats['stundenNachTyp'].isNotEmpty) ...[
              _buildSectionTitle('Tätigkeitsverteilung'),
              pw.SizedBox(height: 20),
              _buildPieChart(stats['stundenNachTyp'], 'Stunden nach Tätigkeit'),
              pw.SizedBox(height: 30),
            ],

            // Balkendiagramm für tägliche Arbeitszeiten
            if (arbeitszeiten.isNotEmpty) ...[
              _buildSectionTitle('Tägliche Arbeitszeiten'),
              pw.SizedBox(height: 20),
              _buildDailyHoursBarChart(arbeitszeiten),
              pw.SizedBox(height: 30),
            ],

            // Detaillierte Tabelle
            _buildSectionTitle('Detaillierte Auflistung'),
            pw.SizedBox(height: 20),
            _buildArbeitszeitenTable(arbeitszeiten),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateFachleistungsstundenPDF(
    String content,
    List<Appointment> appointments,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final pdf = pw.Document();
    final stats = _calculateFachleistungsStats(appointments);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Fachleistungsstunden-Export'),
        footer: (context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            _buildTitle('Fachleistungsstunden-Export'),
            pw.SizedBox(height: 10),
            _buildDateRange(startDate, endDate),
            pw.SizedBox(height: 20),

            // Statistik-Karten
            pw.Row(
              children: [
                pw.Expanded(child: _buildStatCard('Termine', '${appointments.length}')),
                pw.SizedBox(width: 20),
                pw.Expanded(child: _buildStatCard('Gesamt-Stunden', '${stats['gesamtStunden'].toStringAsFixed(1)}h')),
                pw.SizedBox(width: 20),
                pw.Expanded(child: _buildStatCard('Durchschnitt', '${stats['durchschnittProTermin'].toStringAsFixed(1)}h')),
              ],
            ),
            pw.SizedBox(height: 30),

            // Tortendiagramm Stundenverteilung pro Klient
            if (stats['stundenProKlient'].isNotEmpty) ...[
              _buildSectionTitle('Stundenverteilung pro Klient'),
              pw.SizedBox(height: 20),
              _buildPieChart(stats['stundenProKlient'], 'Stunden pro Klient'),
              pw.SizedBox(height: 30),
            ],

            // Balkendiagramm monatliche Verteilung
            _buildSectionTitle('Monatliche Verteilung'),
            pw.SizedBox(height: 20),
            _buildMonthlyBarChart(appointments),
            pw.SizedBox(height: 30),

            // Detaillierte Tabelle
            _buildSectionTitle('Detaillierte Termine'),
            pw.SizedBox(height: 20),
            _buildAppointmentsTable(appointments),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateKlientenPDF(
    String content,
    List<Client> clients,
  ) async {
    final pdf = pw.Document();
    final stats = _calculateClientStats(clients);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Klienten-Übersicht'),
        footer: (context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            _buildTitle('Klienten-Übersicht'),
            pw.SizedBox(height: 10),
            pw.Text('Erstellt: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 20),

            // Statistik-Karten
            pw.Row(
              children: [
                pw.Expanded(child: _buildStatCard('Gesamt-Klienten', '${clients.length}')),
                pw.SizedBox(width: 20),
                pw.Expanded(child: _buildStatCard('Aktive Betreuung', '${stats['activeClients']}')),
                pw.SizedBox(width: 20),
                pw.Expanded(child: _buildStatCard('Ø Verbrauch', '${stats['avgUsage'].toStringAsFixed(1)}%')),
              ],
            ),
            pw.SizedBox(height: 30),

            // Tortendiagramm Stundenverbrauch-Status
            if (stats['usageDistribution'].isNotEmpty) ...[
              _buildSectionTitle('Stundenverbrauch-Status'),
              pw.SizedBox(height: 20),
              _buildUsageStatusPieChart(stats['usageDistribution']),
              pw.SizedBox(height: 30),
            ],

            // Balkendiagramm Top Klienten nach Stundenverbrauch
            if (clients.where((c) => c.fachleistungsstunden != null).isNotEmpty) ...[
              _buildSectionTitle('Top 10 Klienten nach Stundenverbrauch'),
              pw.SizedBox(height: 20),
              _buildClientUsageBarChart(clients),
              pw.SizedBox(height: 30),
            ],

            // Klienten-Tabelle
            _buildSectionTitle('Klienten-Details'),
            pw.SizedBox(height: 20),
            _buildClientsTable(clients),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Header
  static pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Eingliederungshilfe',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              color: darkGray,
            ),
          ),
        ],
      ),
    );
  }

  // Footer
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: lightGray)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Seite ${context.pageNumber} von ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: darkGray),
          ),
          pw.Text(
            'Erstellt am ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: darkGray),
          ),
        ],
      ),
    );
  }

  // Title
  static pw.Widget _buildTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  // Section Title
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: darkGray,
        ),
      ),
    );
  }

  // Date Range
  static pw.Widget _buildDateRange(DateTime start, DateTime end) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: lightGray),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        children: [
          pw.Icon(pw.IconData(0xe935), color: primaryColor, size: 20),
          pw.SizedBox(width: 10),
          pw.Text(
            'Zeitraum: ${DateFormat('dd.MM.yyyy').format(start)} - ${DateFormat('dd.MM.yyyy').format(end)}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Stat Card
  static pw.Widget _buildStatCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: accentColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Stats Cards Row
  static pw.Widget _buildStatsCards(Map<String, dynamic> stats) {
    return pw.Row(
      children: [
        pw.Expanded(child: _buildStatCard('Einträge', '${stats['anzahlEintraege']}')),
        pw.SizedBox(width: 20),
        pw.Expanded(child: _buildStatCard('Gesamt-Stunden', '${stats['gesamtStunden'].toStringAsFixed(1)}h')),
        pw.SizedBox(width: 20),
        pw.Expanded(child: _buildStatCard('Durchschnitt', '${stats['durchschnittProTag'].toStringAsFixed(1)}h')),
      ],
    );
  }

  // Pie Chart
  static pw.Widget _buildPieChart(Map<String, double> data, String title) {
    final total = data.values.fold(0.0, (sum, value) => sum + value);
    final colors = [
      PdfColor.fromInt(0xFF2196F3),
      PdfColor.fromInt(0xFF4CAF50),
      PdfColor.fromInt(0xFFFF9800),
      PdfColor.fromInt(0xFFF44336),
      PdfColor.fromInt(0xFF9C27B0),
      PdfColor.fromInt(0xFF00BCD4),
      PdfColor.fromInt(0xFFFFEB3B),
      PdfColor.fromInt(0xFF795548),
    ];

    return pw.Row(
      children: [
        // Pie Chart
        pw.Container(
          width: 200,
          height: 200,
          child: pw.CustomPaint(
            painter: (PdfGraphics canvas, PdfPoint size) {
              double currentAngle = 0;
              int colorIndex = 0;

              for (final entry in data.entries) {
                final sweepAngle = (entry.value / total) * 2 * math.pi;

                canvas
                  ..setFillColor(colors[colorIndex % colors.length])
                  ..moveTo(100, 100)
                  ..lineTo(
                    100 + 80 * math.cos(currentAngle),
                    100 + 80 * math.sin(currentAngle),
                  );

                // Zeichne Kreisbogen
                for (double angle = currentAngle; angle <= currentAngle + sweepAngle; angle += 0.1) {
                  canvas.lineTo(
                    100 + 80 * math.cos(angle),
                    100 + 80 * math.sin(angle),
                  );
                }

                canvas
                  ..lineTo(100, 100)
                  ..fillPath();

                currentAngle += sweepAngle;
                colorIndex++;
              }
            },
          ),
        ),
        pw.SizedBox(width: 30),
        // Legend
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: data.entries.map((entry) {
              final index = data.keys.toList().indexOf(entry.key);
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 15,
                      height: 15,
                      color: colors[index % colors.length],
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text(
                        '${entry.key}: ${entry.value.toStringAsFixed(1)}h ($percentage%)',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Usage Status Pie Chart
  static pw.Widget _buildUsageStatusPieChart(Map<String, int> data) {
    final total = data.values.fold(0, (sum, value) => sum + value);
    final colors = {
      'Grün (<75%)': PdfColor.fromInt(0xFF4CAF50),
      'Gelb (75-89%)': PdfColor.fromInt(0xFFFF9800),
      'Rot (≥90%)': PdfColor.fromInt(0xFFF44336),
    };

    return pw.Row(
      children: [
        // Pie Chart
        pw.Container(
          width: 200,
          height: 200,
          child: pw.CustomPaint(
            painter: (PdfGraphics canvas, PdfPoint size) {
              double currentAngle = 0;

              for (final entry in data.entries) {
                final sweepAngle = (entry.value / total) * 2 * math.pi;

                canvas
                  ..setFillColor(colors[entry.key] ?? PdfColors.grey)
                  ..moveTo(100, 100)
                  ..lineTo(
                    100 + 80 * math.cos(currentAngle),
                    100 + 80 * math.sin(currentAngle),
                  );

                for (double angle = currentAngle; angle <= currentAngle + sweepAngle; angle += 0.1) {
                  canvas.lineTo(
                    100 + 80 * math.cos(angle),
                    100 + 80 * math.sin(angle),
                  );
                }

                canvas
                  ..lineTo(100, 100)
                  ..fillPath();

                currentAngle += sweepAngle;
              }
            },
          ),
        ),
        pw.SizedBox(width: 30),
        // Legend
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: data.entries.map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 5),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 15,
                      height: 15,
                      color: colors[entry.key] ?? PdfColors.grey,
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text(
                        '${entry.key}: ${entry.value} Klienten ($percentage%)',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Vereinfachtes Balkendiagramm für tägliche Arbeitszeiten
  static pw.Widget _buildDailyHoursBarChart(List<Arbeitszeit> arbeitszeiten) {
    final dailyHours = <DateTime, double>{};

    for (final az in arbeitszeiten) {
      final date = DateTime(az.datum.year, az.datum.month, az.datum.day);
      final hours = az.arbeitszeit.inMinutes / 60.0;
      dailyHours[date] = (dailyHours[date] ?? 0) + hours;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: lightGray),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Tägliche Stunden-Übersicht:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...dailyHours.entries.take(10).map((entry) =>
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                children: [
                  pw.Text('${DateFormat('dd.MM').format(entry.key)}: '),
                  pw.Container(
                    width: entry.value * 20,
                    height: 15,
                    color: primaryColor,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text('${entry.value.toStringAsFixed(1)}h'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vereinfachtes Balkendiagramm für monatliche Verteilung
  static pw.Widget _buildMonthlyBarChart(List<Appointment> appointments) {
    final monthlyHours = <String, double>{};

    for (final apt in appointments) {
      final monthKey = DateFormat('MM/yyyy').format(apt.date);
      monthlyHours[monthKey] = (monthlyHours[monthKey] ?? 0) + apt.fachleistungsstunden;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: lightGray),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Monatliche Stunden-Verteilung:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...monthlyHours.entries.map((entry) =>
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                children: [
                  pw.Text('${entry.key}: '),
                  pw.Container(
                    width: entry.value * 5,
                    height: 15,
                    color: accentColor,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text('${entry.value.toStringAsFixed(1)}h'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vereinfachtes Balkendiagramm für Client Usage
  static pw.Widget _buildClientUsageBarChart(List<Client> clients) {
    final clientsWithHours = clients
        .where((c) => c.fachleistungsstunden != null && c.fachleistungsstunden! > 0)
        .toList()
      ..sort((a, b) => b.verbrauchteStunden.compareTo(a.verbrauchteStunden));

    final topClients = clientsWithHours.take(10).toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: lightGray),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Top Klienten nach Stundenverbrauch:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...topClients.map((client) {
            // Farbcodierung basierend auf Verbrauch
            PdfColor barColor;
            final percentage = client.stundenverbrauchProzent;
            if (percentage >= 90) {
              barColor = PdfColor.fromInt(0xFFF44336); // Rot
            } else if (percentage >= 75) {
              barColor = PdfColor.fromInt(0xFFFF9800); // Orange
            } else {
              barColor = PdfColor.fromInt(0xFF4CAF50); // Grün
            }

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('${client.vollstaendigerName}: '),
                  ),
                  pw.Container(
                    width: client.verbrauchteStunden * 3,
                    height: 15,
                    color: barColor,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text('${client.verbrauchteStunden.toStringAsFixed(1)}h (${percentage.toStringAsFixed(1)}%)'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Tables
  static pw.Widget _buildArbeitszeitenTable(List<Arbeitszeit> arbeitszeiten) {
    return pw.Table(
      border: pw.TableBorder.all(color: lightGray),
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FixedColumnWidth(60),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: primaryColor),
          children: [
            _buildTableHeader('Datum'),
            _buildTableHeader('Von'),
            _buildTableHeader('Bis'),
            _buildTableHeader('Tätigkeit'),
            _buildTableHeader('Stunden'),
          ],
        ),
        // Data rows
        ...arbeitszeiten.take(20).map((az) => pw.TableRow(
          children: [
            _buildTableCell(DateFormat('dd.MM.yy').format(az.datum)),
            _buildTableCell(az.formatierteStartzeit),
            _buildTableCell(az.formatierteEndzeit),
            _buildTableCell(az.taetigkeit),
            _buildTableCell((az.arbeitszeit.inMinutes / 60.0).toStringAsFixed(1)),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildAppointmentsTable(List<Appointment> appointments) {
    return pw.Table(
      border: pw.TableBorder.all(color: lightGray),
      columnWidths: {
        0: const pw.FixedColumnWidth(70),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FixedColumnWidth(50),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: primaryColor),
          children: [
            _buildTableHeader('Datum'),
            _buildTableHeader('Zeit'),
            _buildTableHeader('Klient'),
            _buildTableHeader('Berufsgruppe'),
            _buildTableHeader('Std.'),
          ],
        ),
        // Data rows
        ...appointments.take(20).map((apt) => pw.TableRow(
          children: [
            _buildTableCell(DateFormat('dd.MM.yy').format(apt.date)),
            _buildTableCell(DateFormat('HH:mm').format(apt.startTime)),
            _buildTableCell(apt.clientName),
            _buildTableCell(apt.berufsgruppe),
            _buildTableCell(apt.fachleistungsstunden.toString()),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildClientsTable(List<Client> clients) {
    return pw.Table(
      border: pw.TableBorder.all(color: lightGray),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FixedColumnWidth(60),
        4: const pw.FixedColumnWidth(60),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: primaryColor),
          children: [
            _buildTableHeader('Name'),
            _buildTableHeader('Berufsgruppe'),
            _buildTableHeader('Gesamt'),
            _buildTableHeader('Verbraucht'),
            _buildTableHeader('Status'),
          ],
        ),
        // Data rows
        ...clients.take(15).map((client) {
          final percentage = client.stundenverbrauchProzent;
          String status;
          PdfColor statusColor;

          if (percentage >= 90) {
            status = 'Kritisch';
            statusColor = PdfColor.fromInt(0xFFF44336);
          } else if (percentage >= 75) {
            status = 'Warnung';
            statusColor = PdfColor.fromInt(0xFFFF9800);
          } else {
            status = 'OK';
            statusColor = PdfColor.fromInt(0xFF4CAF50);
          }

          return pw.TableRow(
            children: [
              _buildTableCell(client.vollstaendigerName),
              _buildTableCell(client.berufsgruppe ?? '-'),
              _buildTableCell('${client.fachleistungsstunden ?? 0}h'),
              _buildTableCell('${client.verbrauchteStunden.toStringAsFixed(1)}h'),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: statusColor,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    status,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Statistics calculation methods
  static Map<String, dynamic> _calculateArbeitszeitStats(List<Arbeitszeit> arbeitszeiten) {
    double gesamtStunden = 0;
    Map<String, double> stundenNachTyp = {};

    for (final az in arbeitszeiten) {
      final stunden = az.arbeitszeit.inMinutes / 60.0;
      gesamtStunden += stunden;
      stundenNachTyp[az.taetigkeit] = (stundenNachTyp[az.taetigkeit] ?? 0) + stunden;
    }

    return {
      'anzahlEintraege': arbeitszeiten.length,
      'gesamtStunden': gesamtStunden,
      'durchschnittProTag': arbeitszeiten.isNotEmpty ? gesamtStunden / arbeitszeiten.length : 0,
      'stundenNachTyp': stundenNachTyp,
    };
  }

  static Map<String, dynamic> _calculateFachleistungsStats(List<Appointment> appointments) {
    double gesamtStunden = 0;
    Map<String, double> stundenProKlient = {};

    for (final apt in appointments) {
      gesamtStunden += apt.fachleistungsstunden;
      stundenProKlient[apt.clientName] = (stundenProKlient[apt.clientName] ?? 0) + apt.fachleistungsstunden;
    }

    return {
      'gesamtStunden': gesamtStunden,
      'durchschnittProTermin': appointments.isNotEmpty ? gesamtStunden / appointments.length : 0,
      'stundenProKlient': stundenProKlient,
    };
  }

  static Map<String, dynamic> _calculateClientStats(List<Client> clients) {
    int activeClients = clients.where((c) => c.fachleistungsstunden != null && c.fachleistungsstunden! > 0).length;

    double totalUsage = 0;
    int clientsWithHours = 0;
    Map<String, int> usageDistribution = {
      'Grün (<75%)': 0,
      'Gelb (75-89%)': 0,
      'Rot (≥90%)': 0,
    };

    for (final client in clients) {
      if (client.fachleistungsstunden != null && client.fachleistungsstunden! > 0) {
        final percentage = client.stundenverbrauchProzent;
        totalUsage += percentage;
        clientsWithHours++;

        if (percentage >= 90) {
          usageDistribution['Rot (≥90%)'] = usageDistribution['Rot (≥90%)']! + 1;
        } else if (percentage >= 75) {
          usageDistribution['Gelb (75-89%)'] = usageDistribution['Gelb (75-89%)']! + 1;
        } else {
          usageDistribution['Grün (<75%)'] = usageDistribution['Grün (<75%)']! + 1;
        }
      }
    }

    return {
      'activeClients': activeClients,
      'avgUsage': clientsWithHours > 0 ? totalUsage / clientsWithHours : 0,
      'usageDistribution': usageDistribution,
    };
  }

  // ============================================================
  // Informationsbericht PDF (App-Layout mit Logo)
  // ============================================================

  static Future<Uint8List> generateInformationsberichtPDF(
    Informationsbericht bericht,
  ) async {
    final pdf = pw.Document();
    final df = DateFormat('dd.MM.yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 15),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Informationsbericht',
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                        pw.Text(
                          'fuer Leistungen der Eingliederungshilfe (V1.01)',
                          style: const pw.TextStyle(fontSize: 11, color: darkGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          // Seite 2+
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 1)),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'Informationsbericht: ${bericht.vorname ?? ""} ${bericht.familienname ?? ""}',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
          );
        },
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: lightGray)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Informationsbericht V1.01', style: const pw.TextStyle(fontSize: 9, color: darkGray)),
              pw.Text(
                'Seite ${context.pageNumber} von ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: darkGray),
              ),
            ],
          ),
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 10),

            // Kopfdaten
            _buildBerichtSection('Kopfdaten', [
              _buildBerichtRow('Teilhabefachdienst Soziales', bericht.teilhabefachdienst),
              _buildBerichtRow('ID Kostenuebernahme', bericht.idKostenuebernahme),
              _buildBerichtRow('Berichtszeitraum',
                bericht.berichtszeitraumVon != null && bericht.berichtszeitraumBis != null
                  ? '${df.format(bericht.berichtszeitraumVon!)} - ${df.format(bericht.berichtszeitraumBis!)}'
                  : null),
              _buildBerichtRow('Leistungstyp', bericht.leistungstyp),
              _buildBerichtRow('Leistungserbringer', bericht.leistungserbringer),
              _buildBerichtRow('E-Mail / Tel Nr', bericht.emailTelNr),
              _buildBerichtRow('Adresse', _buildAdresse(bericht)),
            ]),
            pw.SizedBox(height: 15),

            // 1. Persoenliche Daten
            _buildBerichtSection('1. Angaben zur leistungsberechtigten Person', [
              _buildBerichtRow('Anrede', bericht.anrede),
              _buildBerichtRow('Titel', bericht.titel),
              _buildBerichtRow('Familienname', bericht.familienname),
              _buildBerichtRow('Vorname(n)', bericht.vorname),
              _buildBerichtRow('Geburtsname', bericht.geburtsname),
              _buildBerichtRow('Geburtsdatum', bericht.geburtsdatum != null ? df.format(bericht.geburtsdatum!) : null),
              _buildBerichtRow('Geburtsort', bericht.geburtsort),
              _buildBerichtRow('Geschlecht', bericht.geschlecht),
              _buildBerichtRow('Familienstand', bericht.familienstand),
              _buildBerichtRow('Telefon (Festnetz)', bericht.telefonFestnetz),
              _buildBerichtRow('Telefon (Mobil)', bericht.telefonMobil),
              _buildBerichtRow('E-Mail', bericht.email),
            ]),
            pw.SizedBox(height: 15),

            // 2. Allgemeine Informationen
            _buildBerichtSection('2. Allgemeine Informationen', []),
            pw.Container(
              width: double.infinity,
              constraints: const pw.BoxConstraints(minHeight: 60),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lightGray),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                bericht.allgemeineInformationen ?? '',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 15),

            // 3. Teilhabeziele
            _buildBerichtSection('3. Bericht zu vereinbarten Teilhabezielen', []),
            if (bericht.teilhabeziele != null)
              ...bericht.teilhabeziele!.asMap().entries.map((entry) {
                final tz = entry.value;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: lightGray),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (tz.leitzielNr != null || tz.leitzielText != null)
                        pw.Text(
                          'Leitziel ${tz.leitzielNr ?? ""}: ${tz.leitzielText ?? ""}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      if (tz.teilhabezielNr != null || tz.teilhabezielText != null)
                        pw.Text(
                          'Teilhabeziel ${tz.teilhabezielNr ?? ""}: ${tz.teilhabezielText ?? ""}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      if (tz.indikator != null && tz.indikator!.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text('Indikator: ${tz.indikator}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                      if (tz.zielerreichung != null) ...[
                        pw.SizedBox(height: 6),
                        pw.Text('Zielerreichung:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        _ibCheckboxLine('Das Ziel wurde voll erreicht.', tz.zielerreichung == ZielerreichungStatus.vollErreicht),
                        _ibCheckboxLine('Das Ziel wurde teilweise erreicht.', tz.zielerreichung == ZielerreichungStatus.teilweiseErreicht),
                        _ibCheckboxLine('Das Ziel wurde nicht erreicht.', tz.zielerreichung == ZielerreichungStatus.nichtErreicht),
                        _ibCheckboxLine('Die Zielerreichung kann nicht beurteilt werden.', tz.zielerreichung == ZielerreichungStatus.nichtBeurteilbar),
                      ],
                      if (tz.abweichendeEinschaetzung != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text('Abweichende Einschaetzung:  ', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(tz.abweichendeEinschaetzung == false ? '\u2611' : '\u2610', style: const pw.TextStyle(fontSize: 11)),
                            pw.Text(' Nein  ', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(tz.abweichendeEinschaetzung == true ? '\u2611' : '\u2610', style: const pw.TextStyle(fontSize: 11)),
                            pw.Text(' Ja', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                      if (tz.erlaeuterung != null && tz.erlaeuterung!.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text('Erlaeuterung:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(tz.erlaeuterung!, style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                );
              }),
            pw.SizedBox(height: 10),

            // Weitere Anmerkungen
            _buildBerichtSection('Weitere Anmerkungen zu den Zielen', []),
            pw.Container(
              width: double.infinity,
              constraints: const pw.BoxConstraints(minHeight: 40),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lightGray),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(bericht.weitereAnmerkungen ?? '', style: const pw.TextStyle(fontSize: 10)),
            ),
            pw.SizedBox(height: 8),

            // Nacht-Assistenz
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lightGray),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Leistungen zur Erreichbarkeit in der Nacht in Anspruch genommen?',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Text(bericht.nachtAssistenz == false ? '\u2611' : '\u2610', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(' Nein  ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(bericht.nachtAssistenz == true ? '\u2611' : '\u2610', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(' Ja', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // 4. Zusammenfassung
            _buildBerichtSection('4. Zusammenfassung / Ausblick', []),
            pw.Container(
              width: double.infinity,
              constraints: const pw.BoxConstraints(minHeight: 60),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lightGray),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(bericht.zusammenfassung ?? '', style: const pw.TextStyle(fontSize: 10)),
            ),
            pw.SizedBox(height: 15),

            // 5. Unterschriften
            _buildBerichtSection('5. Unterschriften', []),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Ort, Datum', style: const pw.TextStyle(fontSize: 9, color: darkGray)),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 35),
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: lightGray),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(bericht.ortDatum ?? '', style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Leistungserbringer (Ansprechperson/Bezugsbetreuung)', style: const pw.TextStyle(fontSize: 9, color: darkGray)),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 35),
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: lightGray),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(bericht.leistungserbringerUnterschrift ?? '', style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Unterschriftslinien
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: darkGray)),
                        ),
                        height: 40,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Unterschrift Leistungserbringer', style: const pw.TextStyle(fontSize: 8, color: darkGray)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: darkGray)),
                        ),
                        height: 40,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Unterschrift leistungsberechtigte Person', style: const pw.TextStyle(fontSize: 8, color: darkGray)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // 6. Eintragungen
            _buildBerichtSection('6. Eintragungen der leistungsberechtigten Person', []),
            pw.Container(
              width: double.infinity,
              constraints: const pw.BoxConstraints(minHeight: 60),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lightGray),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(bericht.eintragungKlient ?? '', style: const pw.TextStyle(fontSize: 10)),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _ibCheckboxLine(String label, bool checked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Text(checked ? '\u2611' : '\u2610', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(width: 6),
          pw.Expanded(child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  static pw.Widget _buildBerichtSection(String title, List<pw.Widget> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: primaryColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        if (rows.isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(children: rows),
          ),
      ],
    );
  }

  static pw.Widget _buildBerichtRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Text(label,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkGray)),
          ),
          pw.Expanded(
            child: pw.Text(value ?? '-', style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static String? _buildAdresse(Informationsbericht b) {
    final parts = <String>[];
    if (b.strasse != null && b.strasse!.isNotEmpty) {
      parts.add('${b.strasse} ${b.hausnummer ?? ""}'.trim());
    }
    if (b.weitererAdresshinweis != null && b.weitererAdresshinweis!.isNotEmpty) {
      parts.add(b.weitererAdresshinweis!);
    }
    if (b.postleitzahl != null || b.ort != null) {
      parts.add('${b.postleitzahl ?? ""} ${b.ort ?? ""}'.trim());
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String _zielerreichungText(ZielerreichungStatus status) {
    switch (status) {
      case ZielerreichungStatus.vollErreicht:
        return 'Das Ziel wurde voll erreicht.';
      case ZielerreichungStatus.teilweiseErreicht:
        return 'Das Ziel wurde teilweise erreicht.';
      case ZielerreichungStatus.nichtErreicht:
        return 'Das Ziel wurde nicht erreicht.';
      case ZielerreichungStatus.nichtBeurteilbar:
        return 'Die Zielerreichung kann nicht beurteilt werden.';
    }
  }

  // ============================================================
  // Version B: Original-Layout Nachbau mit pdf Package
  // ============================================================

  static const PdfColor _olDarkBlue = PdfColor.fromInt(0xFF1A237E);
  static const PdfColor _olBorderGray = PdfColor.fromInt(0xFF999999);


  static Future<Uint8List> generateInformationsberichtOriginalLayout(
    Informationsbericht bericht,
  ) async {
    final pdf = pw.Document();
    final df = DateFormat('dd.MM.yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // "Land Berlin / Teilhabefachdienst Soziales" + Dropdown-Wert
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Land Berlin / Teilhabefachdienst Soziales',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _olBorderGray, width: 0.5),
                      ),
                      child: pw.Text(
                        bericht.teilhabefachdienst ?? '',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                // Titel
                pw.Text(
                  'Informationsbericht fuer Leistungen der Eingliederungshilfe',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _olDarkBlue,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Container(
                  height: 1,
                  color: _olDarkBlue,
                ),
                pw.SizedBox(height: 10),
              ],
            );
          }
          // Seite 2+
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _olBorderGray, width: 0.5)),
            ),
            child: pw.Text(
              'Informationsbericht zu den Leistungen ${bericht.vorname ?? ""}, ${bericht.familienname ?? ""}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          );
        },
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _olBorderGray, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Informationsbericht V1.01', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Text(
                'Seite ${context.pageNumber} von ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (pw.Context context) {
          return [
            // Kopfdaten Tabelle
            _olFieldTable([
              _olFieldRow('ID Kostenuebernahme', bericht.idKostenuebernahme),
              _olFieldRow('Berichtszeitraum von',
                bericht.berichtszeitraumVon != null ? df.format(bericht.berichtszeitraumVon!) : null),
              _olFieldRow('Berichtszeitraum bis',
                bericht.berichtszeitraumBis != null ? df.format(bericht.berichtszeitraumBis!) : null),
              _olFieldRow('Leistungstyp', bericht.leistungstyp),
              _olFieldRow('Leistungserbringer', bericht.leistungserbringer),
              _olFieldRow('E-Mail / Tel Nr', bericht.emailTelNr),
              _olFieldRow('Strasse', bericht.strasse),
              _olFieldRow('Hausnummer', bericht.hausnummer),
              _olFieldRow('Weiterer Adresshinweis', bericht.weitererAdresshinweis),
              _olFieldRow('Postleitzahl', bericht.postleitzahl),
              _olFieldRow('Ort', bericht.ort),
            ]),
            pw.SizedBox(height: 12),

            // 1. Angaben zur leistungsberechtigten Person
            _olSectionHeader('1. Angaben zur leistungsberechtigten Person'),
            _olFieldTable([
              _olFieldRow('Anrede', bericht.anrede),
              _olFieldRow('Titel', bericht.titel),
              _olFieldRow('Familienname', bericht.familienname),
              _olFieldRow('Vorname(n)', bericht.vorname),
              _olFieldRow('Geburtsname', bericht.geburtsname),
              _olFieldRow('Geburtsdatum', bericht.geburtsdatum != null ? df.format(bericht.geburtsdatum!) : null),
              _olFieldRow('Geburtsort', bericht.geburtsort),
              _olFieldRow('Geschlecht', bericht.geschlecht),
              _olFieldRow('Familienstand', bericht.familienstand),
              _olFieldRow('Telefon (Festnetz)', bericht.telefonFestnetz),
              _olFieldRow('Telefon (Mobil)', bericht.telefonMobil),
              _olFieldRow('E-Mail', bericht.email),
            ]),
            pw.SizedBox(height: 12),

            // 2. Allgemeine Informationen
            _olSectionHeader('2. Allgemeine Informationen'),
            _olTextArea(bericht.allgemeineInformationen, minHeight: 80),
            pw.SizedBox(height: 12),

            // 3. Bericht zu vereinbarten Teilhabezielen
            _olSectionHeader('3. Bericht zu vereinbarten Teilhabezielen'),
            if (bericht.teilhabeziele != null)
              ...bericht.teilhabeziele!.asMap().entries.map((entry) {
                final tz = entry.value;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _olBorderGray, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Leitziel
                      _olInnerFieldRow('Leitziel Nr.', tz.leitzielNr?.toString()),
                      _olInnerFieldRow('Leitziel', tz.leitzielText),
                      _olInnerFieldRow('Teilhabeziel Nr.', tz.teilhabezielNr?.toString()),
                      _olInnerFieldRow('Teilhabeziel', tz.teilhabezielText),
                      _olInnerFieldRow('Indikator', tz.indikator),
                      // Zielerreichung
                      if (tz.zielerreichung != null)
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(top: pw.BorderSide(color: _olBorderGray, width: 0.5)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Zielerreichung:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 2),
                              _olCheckLine('Das Ziel wurde voll erreicht.', tz.zielerreichung == ZielerreichungStatus.vollErreicht),
                              _olCheckLine('Das Ziel wurde teilweise erreicht.', tz.zielerreichung == ZielerreichungStatus.teilweiseErreicht),
                              _olCheckLine('Das Ziel wurde nicht erreicht.', tz.zielerreichung == ZielerreichungStatus.nichtErreicht),
                              _olCheckLine('Die Zielerreichung kann nicht beurteilt werden.', tz.zielerreichung == ZielerreichungStatus.nichtBeurteilbar),
                            ],
                          ),
                        ),
                      // Abweichende Einschaetzung
                      if (tz.abweichendeEinschaetzung != null)
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(top: pw.BorderSide(color: _olBorderGray, width: 0.5)),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Text('Abweichende Einschaetzung der leistungsberechtigten Person:  ',
                                style: const pw.TextStyle(fontSize: 9)),
                              pw.Text(tz.abweichendeEinschaetzung == false ? '\u2611' : '\u2610',
                                style: const pw.TextStyle(fontSize: 10)),
                              pw.Text(' Nein  ', style: const pw.TextStyle(fontSize: 9)),
                              pw.Text(tz.abweichendeEinschaetzung == true ? '\u2611' : '\u2610',
                                style: const pw.TextStyle(fontSize: 10)),
                              pw.Text(' Ja', style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                      // Erlaeuterung
                      if (tz.erlaeuterung != null && tz.erlaeuterung!.isNotEmpty)
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(8),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(top: pw.BorderSide(color: _olBorderGray, width: 0.5)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Erlaeuterung:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 2),
                              pw.Text(tz.erlaeuterung!, style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }),
            pw.SizedBox(height: 6),

            // Weitere Anmerkungen
            _olSectionHeader('Weitere Anmerkungen zu den Zielen'),
            _olTextArea(bericht.weitereAnmerkungen, minHeight: 50),
            pw.SizedBox(height: 8),

            // Nacht-Assistenz
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _olBorderGray, width: 0.5),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Leistungen zur Erreichbarkeit in der Nacht in Anspruch genommen?',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Text(bericht.nachtAssistenz == false ? '\u2611' : '\u2610', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(' Nein  ', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(bericht.nachtAssistenz == true ? '\u2611' : '\u2610', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(' Ja', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 4. Zusammenfassung / Ausblick
            _olSectionHeader('4. Zusammenfassung / Ausblick'),
            _olTextArea(bericht.zusammenfassung, minHeight: 80),
            pw.SizedBox(height: 12),

            // 5. Unterschriften
            _olSectionHeader('5. Unterschriften'),
            pw.SizedBox(height: 6),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Ort, Datum', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 3),
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 30),
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _olBorderGray, width: 0.5),
                        ),
                        child: pw.Text(bericht.ortDatum ?? '', style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Leistungserbringer (Ansprechperson/Bezugsbetreuung)',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 3),
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 30),
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _olBorderGray, width: 0.5),
                        ),
                        child: pw.Text(bericht.leistungserbringerUnterschrift ?? '', style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            // Unterschriftslinien
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                        ),
                        height: 35,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text('Unterschrift Leistungserbringer', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 30),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                        ),
                        height: 35,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text('Unterschrift leistungsberechtigte Person', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // 6. Eintragungen
            _olSectionHeader('6. Eintragungen der leistungsberechtigten Person'),
            _olTextArea(bericht.eintragungKlient, minHeight: 80),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- Hilfs-Widgets fuer Original-Layout ---

  static pw.Widget _olSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _olDarkBlue,
        ),
      ),
    );
  }

  static pw.TableRow _olFieldRow(String label, String? value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pw.Text(label,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pw.Text(value ?? '',
            style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  static pw.Widget _olFieldTable(List<pw.TableRow> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _olBorderGray, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows,
    );
  }

  static pw.Widget _olInnerFieldRow(String label, String? value) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _olBorderGray, width: 0.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value ?? '',
              style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _olTextArea(String? value, {double minHeight = 60}) {
    return pw.Container(
      width: double.infinity,
      constraints: pw.BoxConstraints(minHeight: minHeight),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _olBorderGray, width: 0.5),
      ),
      child: pw.Text(value ?? '', style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _olCheckLine(String label, bool checked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Text(checked ? '\u2611' : '\u2610', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 5),
          pw.Expanded(child: pw.Text(label, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  // ============================================================
  // Syncfusion: Original-PDF-Template befuellen
  // ============================================================

  static Future<Uint8List> generateInformationsberichtSyncfusion(
    Informationsbericht bericht,
  ) async {
    final df = DateFormat('dd.MM.yyyy');

    final templateBytes = await rootBundle.load('assets/informationsbericht_101.pdf');
    final doc = sf.PdfDocument(inputBytes: templateBytes.buffer.asUint8List());
    final form = doc.form;

    // Hilfs-Map fuer schnelleren Zugriff
    final fieldMap = <String, sf.PdfField>{};
    for (int i = 0; i < form.fields.count; i++) {
      final fname = form.fields[i].name;
      if (fname != null) fieldMap[fname] = form.fields[i];
    }

    void setText(String name, String? value) {
      if (value == null || value.isEmpty) return;
      final field = fieldMap[name];
      if (field is sf.PdfTextBoxField) {
        field.text = value;
        debugPrint('[SyncfusionPDF] setText: $name = "$value" (OK)');
      } else {
        debugPrint('[SyncfusionPDF] setText: $name = "$value" (FIELD NOT FOUND or wrong type: ${field?.runtimeType})');
      }
    }

    void setCombo(String name, String? value) {
      if (value == null || value.isEmpty) return;
      final field = fieldMap[name];
      if (field is sf.PdfComboBoxField) {
        for (int j = 0; j < field.items.count; j++) {
          final itemText = field.items[j].text.trim();
          if (itemText == value || itemText.contains(value) || value.contains(itemText)) {
            field.selectedIndex = j;
            return;
          }
        }
        debugPrint('[SyncfusionPDF] ComboBox-Wert nicht gefunden: $name = $value');
      }
    }

    void setCheck(String name, bool checked) {
      final field = fieldMap[name];
      if (field is sf.PdfCheckBoxField) {
        field.isChecked = checked;
      }
    }

    // --- Kopf: Bezirksauswahl ---
    setCombo('IB_S1_02_02', bericht.teilhabefachdienst);

    // --- Kopfdaten ---
    // _06_02 = ID Kostenuebernahme (Wertfeld)
    setText('IB_S1_06_02', bericht.idKostenuebernahme);
    // _07_02 = Berichtszeitraum von, _07_04 = bis
    if (bericht.berichtszeitraumVon != null) {
      setText('IB_S1_07_02', df.format(bericht.berichtszeitraumVon!));
    }
    if (bericht.berichtszeitraumBis != null) {
      setText('IB_S1_07_04', df.format(bericht.berichtszeitraumBis!));
    }
    // _08_02 = Leistungstyp (Wertfeld)
    setText('IB_S1_08_02', bericht.leistungstyp);
    // _09_02 = Leistungserbringer (Wertfeld)
    setText('IB_S1_09_02', bericht.leistungserbringer);
    // _10_02 = E-Mail/Tel Nr (Wertfeld)
    setText('IB_S1_10_02', bericht.emailTelNr);
    // _12_02 = Strasse, _13_02 = Hausnummer, _14_02 = Adresshinweis
    setText('IB_S1_12_02', bericht.strasse);
    setText('IB_S1_13_02', bericht.hausnummer);
    setText('IB_S1_14_02', bericht.weitererAdresshinweis);
    // _15_02 = PLZ, _16_02 = Ort
    setText('IB_S1_15_02', bericht.postleitzahl);
    setText('IB_S1_16_02', bericht.ort);

    // --- 1. Persoenliche Daten ---
    setCombo('IB_S1_18_02', bericht.anrede);
    setCombo('IB_S1_19_02', bericht.titel);
    setText('IB_S1_20_02', bericht.familienname);
    setText('IB_S1_21_02', bericht.vorname);
    setText('IB_S1_22_02', bericht.geburtsname);
    if (bericht.geburtsdatum != null) {
      setText('IB_S1_23_02', df.format(bericht.geburtsdatum!));
    }
    setText('IB_S1_24_02', bericht.geburtsort);
    setCombo('IB_S1_25_02', bericht.geschlecht);
    setCombo('IB_S1_26_02', bericht.familienstand);
    setText('IB_S1_28_02', bericht.telefonFestnetz);
    setText('IB_S1_29_02', bericht.telefonMobil);
    setText('IB_S1_30_02', bericht.email);

    // --- Seiten-Header (Seite 2+) ---
    // IB_gesamt_02 = Vorname (nach "fuer:"), IB_gesamt_04 = Familienname
    setText('IB_gesamt_02', bericht.vorname);
    setText('IB_gesamt_04', bericht.familienname);

    // --- 2. Allgemeine Informationen ---
    // IB_S2_05_01 = Freitextfeld fuer allgemeine Infos
    setText('IB_S2_05_01', bericht.allgemeineInformationen);

    // --- 3. Teilhabeziele (erstes Ziel - Template hat Platz fuer eins) ---
    if (bericht.teilhabeziele != null && bericht.teilhabeziele!.isNotEmpty) {
      final tz = bericht.teilhabeziele!.first;
      // IB_S3_02_02_a = Leitziel Nr (Wertfeld), IB_S3_02_03_a = Leitziel Text
      setText('IB_S3_02_02_a', tz.leitzielNr?.toString());
      setText('IB_S3_02_03_a', tz.leitzielText);
      // IB_S3_03_02_a = Teilhabeziel Nr (Wertfeld), IB_S3_03_04_a = Text
      setText('IB_S3_03_02_a', tz.teilhabezielNr?.toString());
      setText('IB_S3_03_04_a', tz.teilhabezielText);
      // IB_S3_04_02_a = Indikator (Wertfeld)
      setText('IB_S3_04_02_a', tz.indikator);

      // Zielerreichung Checkboxen
      if (tz.zielerreichung != null) {
        setCheck('IB_S3_06_01_a', tz.zielerreichung == ZielerreichungStatus.vollErreicht);
        setCheck('IB_S3_07_01_a', tz.zielerreichung == ZielerreichungStatus.teilweiseErreicht);
        setCheck('IB_S3_08_01_a', tz.zielerreichung == ZielerreichungStatus.nichtErreicht);
        setCheck('IB_S3_09_01_a', tz.zielerreichung == ZielerreichungStatus.nichtBeurteilbar);
      }

      // Abweichende Einschaetzung
      if (tz.abweichendeEinschaetzung != null) {
        setCheck('IB_S3_11_01_a', tz.abweichendeEinschaetzung == false);
        setCheck('IB_S3_11_03_a', tz.abweichendeEinschaetzung == true);
      }

      // IB_S3_14_01_a = Erlaeuterung Freitextfeld
      setText('IB_S3_14_01_a', tz.erlaeuterung);
    }

    // --- Weitere Anmerkungen ---
    // IB_S4_03_01 = Freitextfeld fuer weitere Anmerkungen
    setText('IB_S4_03_01', bericht.weitereAnmerkungen);

    // --- Nacht-Assistenz ---
    if (bericht.nachtAssistenz != null) {
      setCheck('IB_S4_05_01', bericht.nachtAssistenz == false);
      setCheck('IB_S4_05_03', bericht.nachtAssistenz == true);
    }

    // --- 4. Zusammenfassung (Sektion 8 im PDF) ---
    // IB_S8_02_01 und IB_S8_05_01 = Zusammenfassung/Ausblick Freitextfelder
    setText('IB_S8_02_01', bericht.zusammenfassung);
    setText('IB_S8_05_01', bericht.zusammenfassung);

    // --- 5. Unterschriften ---
    // IB_S8_08_02 = Ort, Datum
    setText('IB_S8_08_02', bericht.ortDatum);
    // IB_S8_08_01 = Leistungserbringer (Wertfeld - beschreibender Text ueberschreiben)
    setText('IB_S8_08_01', bericht.leistungserbringerUnterschrift);

    // --- 6. Eintragungen ---
    // IB_S8_09_01 = Eintragungen der leistungsberechtigten Person
    setText('IB_S8_09_01', bericht.eintragungKlient);

    // IB_S8_04_01.0 und .1 sind Labels fuer Sektion 6 - nicht ueberschreiben

    // Kein flattenAllFields() - das loescht die Feldwerte bei diesem PDF.
    // Felder bleiben als ausfuellbare Formularfelder erhalten.

    final bytes = Uint8List.fromList(doc.saveSync());
    doc.dispose();
    return bytes;
  }
}