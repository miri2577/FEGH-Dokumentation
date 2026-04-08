import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/arbeitszeit.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../models/fahrweg.dart';
import '../models/export_format.dart';
import '../services/export_service.dart';
import '../utils/responsive_utils.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export & Berichte'),
        elevation: ResponsiveUtils.isDesktop(context) ? 0 : null,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return SingleChildScrollView(
            padding: ResponsiveUtils.getScreenPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateRangeSection(),
                const SizedBox(height: 24),
                _buildExportOptionsSection(appProvider),
                const SizedBox(height: 24),
                _buildQuickExportsSection(appProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Zeitraum auswählen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Von'),
                    subtitle: Text(_formatDate(_startDate)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectStartDate(context),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('Bis'),
                    subtitle: Text(_formatDate(_endDate)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectEndDate(context),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptionsSection(AppProvider appProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Detaillierte Exporte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildExportTile(
              title: 'Arbeitszeit Export',
              subtitle: 'Alle Arbeitszeiten im ausgewählten Zeitraum',
              icon: Icons.schedule,
              color: Colors.blue,
              onTap: () => _exportArbeitszeiten(appProvider),
            ),
            const Divider(),
            _buildExportTile(
              title: 'Fachleistungsstunden Export',
              subtitle: 'Alle Termine mit Fachleistungsstunden',
              icon: Icons.person_outline,
              color: Colors.green,
              onTap: () => _exportFachleistungsstunden(appProvider),
            ),
            const Divider(),
            _buildExportTile(
              title: 'Dokumentation Export',
              subtitle: 'Alle dokumentierten Termine und Notizen',
              icon: Icons.description,
              color: Colors.orange,
              onTap: () => _exportDokumentation(appProvider),
            ),
            const Divider(),
            _buildExportTile(
              title: 'Klienten-Übersicht',
              subtitle: 'Vollständige Klientenliste mit allen Daten',
              icon: Icons.people,
              color: Colors.purple,
              onTap: () => _exportKlienten(appProvider),
            ),
            const Divider(),
            _buildExportTile(
              title: 'Fahrwege Export',
              subtitle: 'Fahrten mit km-Statistik für Fahrtkostenerstattung',
              icon: Icons.directions_car,
              color: Colors.deepOrange,
              onTap: () => _exportFahrwege(appProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExportsSection(AppProvider appProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚡ Schnell-Exporte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickExportButton(
                    title: 'Diese Woche',
                    subtitle: 'Arbeitszeiten',
                    icon: Icons.date_range,
                    onTap: () => _exportThisWeek(appProvider),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickExportButton(
                    title: 'Dieser Monat',
                    subtitle: 'Vollständig',
                    icon: Icons.calendar_month,
                    onTap: () => _exportThisMonth(appProvider),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickExportButton(
                    title: 'Alle Daten',
                    subtitle: 'Vollbackup',
                    icon: Icons.backup,
                    onTap: () => _exportAllData(appProvider),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickExportButton(
                    title: 'Statistiken',
                    subtitle: 'Übersicht',
                    icon: Icons.analytics,
                    onTap: () => _exportStatistics(appProvider),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha:0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: _isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      onTap: _isExporting ? null : onTap,
    );
  }

  Widget _buildQuickExportButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isExporting ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Date selection methods
  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // Export methods
  Future<void> _exportArbeitszeiten(AppProvider appProvider) async {
    final format = await ExportService.showFormatSelectionDialog(context);
    if (format == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      final arbeitszeiten = appProvider.getArbeitszeitenByDateRange(_startDate, _endDate);
      final content = _generateArbeitszeitenReport(arbeitszeiten);
      final filename = 'Arbeitszeiten_${_formatDateForFilename(_startDate)}_bis_${_formatDateForFilename(_endDate)}';

      final success = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        arbeitszeiten: arbeitszeiten,
        startDate: _startDate,
        endDate: _endDate,
        exportType: 'arbeitszeiten',
      );

      if (mounted) {
        if (success) {
          _showSuccessMessage('Arbeitszeiten erfolgreich als ${format.displayName} exportiert');
        } else {
          _showErrorMessage('Fehler beim Exportieren der Arbeitszeiten');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Fehler beim Exportieren der Arbeitszeiten: $e');
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportFachleistungsstunden(AppProvider appProvider) async {
    final format = await ExportService.showFormatSelectionDialog(context);
    if (format == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      final appointments = appProvider.appointments.where((apt) =>
          apt.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          apt.date.isBefore(_endDate.add(const Duration(days: 1))) &&
          apt.fachleistungsstunden > 0
      ).toList();

      final content = _generateFachleistungsstundenReport(appointments);
      final filename = 'Fachleistungsstunden_${_formatDateForFilename(_startDate)}_bis_${_formatDateForFilename(_endDate)}';

      final success = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        appointments: appointments,
        startDate: _startDate,
        endDate: _endDate,
        exportType: 'fachleistungsstunden',
      );

      if (mounted) {
        if (success) {
          _showSuccessMessage('Fachleistungsstunden erfolgreich als ${format.displayName} exportiert');
        } else {
          _showErrorMessage('Fehler beim Exportieren der Fachleistungsstunden');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Fehler beim Exportieren der Fachleistungsstunden: $e');
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportDokumentation(AppProvider appProvider) async {
    final format = await ExportService.showFormatSelectionDialog(context);
    if (format == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      final appointments = appProvider.appointments.where((apt) =>
          apt.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          apt.date.isBefore(_endDate.add(const Duration(days: 1))) &&
          (apt.notes.isNotEmpty || apt.recordedText.isNotEmpty)
      ).toList();

      final content = _generateDokumentationReport(appointments);
      final filename = 'Dokumentation_${_formatDateForFilename(_startDate)}_bis_${_formatDateForFilename(_endDate)}';

      final success = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        appointments: appointments,
        startDate: _startDate,
        endDate: _endDate,
        exportType: 'dokumentation',
      );

      if (mounted) {
        if (success) {
          _showSuccessMessage('Dokumentation erfolgreich als ${format.displayName} exportiert');
        } else {
          _showErrorMessage('Fehler beim Exportieren der Dokumentation');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Fehler beim Exportieren der Dokumentation: $e');
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportKlienten(AppProvider appProvider) async {
    final format = await ExportService.showFormatSelectionDialog(context);
    if (format == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      final content = _generateKlientenReport(appProvider.clients);
      final filename = 'Klienten_Uebersicht_${_formatDateForFilename(DateTime.now())}';

      final success = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        clients: appProvider.clients,
        exportType: 'klienten',
      );

      if (mounted) {
        if (success) {
          _showSuccessMessage('Klienten-Übersicht erfolgreich als ${format.displayName} exportiert');
        } else {
          _showErrorMessage('Fehler beim Exportieren der Klienten');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Fehler beim Exportieren der Klienten: $e');
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportThisWeek(AppProvider appProvider) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    setState(() {
      _startDate = startOfWeek;
      _endDate = endOfWeek;
    });

    await _exportArbeitszeiten(appProvider);
  }

  Future<void> _exportThisMonth(AppProvider appProvider) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    setState(() {
      _startDate = startOfMonth;
      _endDate = endOfMonth;
    });
    
    await _exportAllInRange(appProvider);
  }

  Future<void> _exportAllInRange(AppProvider appProvider) async {
    final format = await ExportService.showFormatSelectionDialog(context);
    if (format == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      final arbeitszeiten = appProvider.getArbeitszeitenByDateRange(_startDate, _endDate);
      final appointments = appProvider.appointments.where((apt) =>
          apt.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          apt.date.isBefore(_endDate.add(const Duration(days: 1)))
      ).toList();

      final content = _generateCompleteReport(arbeitszeiten, appointments);
      final filename = 'Vollstaendiger_Bericht_${_formatDateForFilename(_startDate)}_bis_${_formatDateForFilename(_endDate)}';

      final success = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        arbeitszeiten: arbeitszeiten,
        appointments: appointments,
      );

      if (mounted) {
        if (success) {
          _showSuccessMessage('Vollständiger Bericht erfolgreich als ${format.displayName} exportiert');
        } else {
          _showErrorMessage('Fehler beim Exportieren');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Fehler beim Exportieren: $e');
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportAllData(AppProvider appProvider) async {
    final format = await ExportService.showFormatSelectionDialog(context);
    if (format == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      final data = await appProvider.exportAllData();
      if (!mounted) return;
      final content = _generateBackupReport(data);
      final filename = 'Vollbackup_${_formatDateForFilename(DateTime.now())}';

      final success = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        arbeitszeiten: appProvider.arbeitszeiten,
        appointments: appProvider.appointments,
        clients: appProvider.clients,
      );

      if (mounted) {
        if (success) {
          _showSuccessMessage('Vollbackup erfolgreich als ${format.displayName} exportiert');
        } else {
          _showErrorMessage('Fehler beim Exportieren des Backups');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Fehler beim Exportieren des Backups: $e');
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportStatistics(AppProvider appProvider) async {
    final format = await ExportService.showFormatSelectionDialog(context);
    if (format == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      final content = _generateStatisticsReport(appProvider);
      final filename = 'Statistiken_${_formatDateForFilename(DateTime.now())}';

      final success = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
      );

      if (mounted) {
        if (success) {
          _showSuccessMessage('Statistiken erfolgreich als ${format.displayName} exportiert');
        } else {
          _showErrorMessage('Fehler beim Exportieren der Statistiken');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Fehler beim Exportieren der Statistiken: $e');
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportFahrwege(AppProvider appProvider) async {
    final format = await ExportService.showFormatSelectionDialog(context);
    if (format == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      final fahrwege = appProvider.getFahrwegeByDateRange(_startDate, _endDate);
      final content = _generateFahrwegeReport(fahrwege, appProvider);
      final filename = 'Fahrwege_${_formatDateForFilename(_startDate)}_bis_${_formatDateForFilename(_endDate)}';

      final success = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
      );

      if (mounted) {
        if (success) {
          _showSuccessMessage('Fahrwege erfolgreich als ${format.displayName} exportiert');
        } else {
          _showErrorMessage('Fehler beim Exportieren der Fahrwege');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Fehler beim Exportieren der Fahrwege: $e');
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  String _generateFahrwegeReport(List<Fahrweg> fahrwege, AppProvider appProvider) {
    final sorted = List<Fahrweg>.from(fahrwege)..sort((a, b) => a.datum.compareTo(b.datum));
    final totalKm = sorted.fold<double>(0.0, (sum, f) => sum + f.distanzKm);

    String report = '''
FAHRWEGE-EXPORT
============================================================

ZEITRAUM: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}
ANZAHL FAHRTEN: ${sorted.length}
GESAMT-KM: ${totalKm.toStringAsFixed(1)} km
ERSTELLT: ${_formatDateTime(DateTime.now())}

============================================================

''';

    // CSV-kompatible Tabelle
    report += 'Datum;Start;Ziel;km;Klient;Notizen\n';
    report += '------;-----;----;--;------;-------\n';

    for (final f in sorted) {
      final clientName = f.clientId != null
          ? appProvider.clients.where((c) => c.id == f.clientId).map((c) => c.name).firstOrNull ?? ''
          : '';
      report += '${DateFormat('dd.MM.yyyy').format(f.datum)};${f.startStandortName};${f.zielStandortName};${f.distanzKm.toStringAsFixed(1)};$clientName;${f.notizen ?? ''}\n';
    }

    report += '\n============================================================\n';
    report += 'ZUSAMMENFASSUNG\n\n';

    // km pro Klient
    final kmPerClient = <String, double>{};
    for (final f in sorted) {
      if (f.clientId != null) {
        final name = f.zielStandortName;
        kmPerClient[name] = (kmPerClient[name] ?? 0.0) + f.distanzKm;
      }
    }

    if (kmPerClient.isNotEmpty) {
      report += 'km pro Standort:\n';
      final sortedClients = kmPerClient.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedClients) {
        report += '  ${entry.key}: ${entry.value.toStringAsFixed(1)} km\n';
      }
    }

    report += '\nGesamt: ${totalKm.toStringAsFixed(1)} km\n';

    return report;
  }

  // Report generation methods
  String _generateArbeitszeitenReport(List<Arbeitszeit> arbeitszeiten) {
    final sortedArbeitszeiten = List<Arbeitszeit>.from(arbeitszeiten)
      ..sort((a, b) => a.datum.compareTo(b.datum));

    String report = '''
ARBEITSZEIT-EXPORT
============================================================

ZEITRAUM: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}
ANZAHL EINTRÄGE: ${sortedArbeitszeiten.length}
ERSTELLT: ${_formatDateTime(DateTime.now())}

============================================================

''';

    if (sortedArbeitszeiten.isEmpty) {
      report += 'Keine Arbeitszeiten im ausgewählten Zeitraum gefunden.\n';
    } else {
      double gesamtStunden = 0;
      Map<ArbeitszeitTyp, double> stundenNachTyp = {};

      for (final arbeitszeit in sortedArbeitszeiten) {
        final stunden = arbeitszeit.arbeitszeit.inMinutes / 60.0;
        gesamtStunden += stunden;
        stundenNachTyp[arbeitszeit.typ] = (stundenNachTyp[arbeitszeit.typ] ?? 0) + stunden;

        report += '''
${_formatDate(arbeitszeit.datum)} | ${arbeitszeit.formatierteStartzeit} - ${arbeitszeit.formatierteEndzeit}
Tätigkeit: ${arbeitszeit.taetigkeit}
Dauer: ${arbeitszeit.formatierteArbeitszeit}
${arbeitszeit.notizen.isNotEmpty ? 'Notizen: ${arbeitszeit.notizen}' : ''}

''';
      }

      report += '''
============================================================
ZUSAMMENFASSUNG
============================================================

Gesamtstunden: ${gesamtStunden.toStringAsFixed(2)}h
Durchschnitt pro Tag: ${(gesamtStunden / (sortedArbeitszeiten.length > 0 ? sortedArbeitszeiten.length : 1)).toStringAsFixed(2)}h

STUNDENVERTEILUNG NACH TÄTIGKEIT:
''';

      stundenNachTyp.forEach((typ, stunden) {
        report += '${typ.displayName}: ${stunden.toStringAsFixed(2)}h\n';
      });
    }

    return report;
  }

  String _generateFachleistungsstundenReport(List<Appointment> appointments) {
    final sortedAppointments = List<Appointment>.from(appointments)
      ..sort((a, b) => a.date.compareTo(b.date));

    String report = '''
FACHLEISTUNGSSTUNDEN-EXPORT
============================================================

ZEITRAUM: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}
ANZAHL TERMINE: ${sortedAppointments.length}
ERSTELLT: ${_formatDateTime(DateTime.now())}

============================================================

''';

    if (sortedAppointments.isEmpty) {
      report += 'Keine Termine mit Fachleistungsstunden im ausgewählten Zeitraum.\n';
    } else {
      double gesamtStunden = 0;
      Map<String, double> stundenProKlient = {};

      for (final appointment in sortedAppointments) {
        // Indirekte Termine: Stunden über clientAllocations verteilen
        if (appointment.isIndirect && appointment.clientAllocations != null) {
          for (final alloc in appointment.clientAllocations!) {
            gesamtStunden += alloc.stunden;
            stundenProKlient[alloc.clientName] = (stundenProKlient[alloc.clientName] ?? 0) + alloc.stunden;
          }

          final allocDetails = appointment.clientAllocations!
              .map((a) => '${a.clientName}: ${a.stunden.toStringAsFixed(2)}h (${a.minuten} Min)')
              .join(', ');

          report += '''
${_formatDate(appointment.date)} | ${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}
TerminArt: ${appointment.effectiveTerminArt.displayName} (indirekt)
Verteilung: $allocDetails
Gesamtdauer: ${appointment.fachleistungsstunden.toStringAsFixed(2)}h
${appointment.notes.isNotEmpty ? 'Notizen: ${appointment.notes}' : ''}

''';
        } else {
          // Direkter Termin: wie bisher
          gesamtStunden += appointment.fachleistungsstunden;
          stundenProKlient[appointment.clientName] = (stundenProKlient[appointment.clientName] ?? 0) + appointment.fachleistungsstunden;

          report += '''
${_formatDate(appointment.date)} | ${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}
Klient: ${appointment.clientName}
Fachleistungsstunden: ${appointment.fachleistungsstunden}h
Berufsgruppe: ${appointment.berufsgruppe}
${_generateTIBZieleSection(appointment)}
${appointment.notes.isNotEmpty ? 'Notizen: ${appointment.notes}' : ''}

''';
        }
      }

      report += '''
============================================================
ZUSAMMENFASSUNG
============================================================

Gesamt-Fachleistungsstunden: ${gesamtStunden.toStringAsFixed(2)}h

STUNDEN PRO KLIENT:
''';

      stundenProKlient.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) {
          report += '${entry.key}: ${entry.value.toStringAsFixed(2)}h\n';
        });
    }

    return report;
  }

  String _generateDokumentationReport(List<Appointment> appointments) {
    final sortedAppointments = List<Appointment>.from(appointments)
      ..sort((a, b) => a.date.compareTo(b.date));

    String report = '''
DOKUMENTATIONS-EXPORT
============================================================

ZEITRAUM: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}
ANZAHL DOKUMENTIERTE TERMINE: ${sortedAppointments.length}
ERSTELLT: ${_formatDateTime(DateTime.now())}

============================================================

''';

    if (sortedAppointments.isEmpty) {
      report += 'Keine dokumentierten Termine im ausgewählten Zeitraum.\n';
    } else {
      for (final appointment in sortedAppointments) {
        report += '''
${_formatDate(appointment.date)} | ${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}
Klient: ${appointment.clientName}
Berufsgruppe: ${appointment.berufsgruppe}
${_generateTIBZieleSection(appointment)}

''';

        if (appointment.notes.isNotEmpty) {
          report += '''
NOTIZEN:
${appointment.notes}

''';
        }

        if (appointment.recordedText.isNotEmpty) {
          report += '''
SPRACHAUFZEICHNUNG:
${appointment.recordedText}

''';
        }

        report += '${List.filled(40, '-').join()}\n\n';
      }
    }

    return report;
  }

  String _generateTIBZieleSection(Appointment appointment) {
    if (appointment.selectedTibZiele == null ||
        appointment.selectedTibZiele!.isEmpty) {
      return '';
    }

    String section = 'TIB-ZIELE:\n';

    for (final ziel in appointment.selectedTibZiele!) {
      final minuten = appointment.tibZielMinuten?[ziel] ?? 0;
      if (minuten > 0) {
        section += '- $ziel (${minuten} Min)\n';
      } else {
        section += '- $ziel\n';
      }
    }

    if (appointment.tibZielMinuten != null &&
        appointment.tibZielMinuten!.isNotEmpty) {
      final gesamtMinuten = appointment.tibZielMinuten!.values
          .fold(0, (sum, minuten) => sum + minuten);
      section += '\nTIB-Ziele Gesamtzeit: ${gesamtMinuten} Minuten\n';
    }

    return section;
  }

  String _generateClientTIBZiele(Client client) {
    if (client.individuelleTibZiele == null ||
        client.individuelleTibZiele!.isEmpty) {
      return '';
    }

    String section = 'TIB-ZIELE:\n';
    for (final ziel in client.individuelleTibZiele!) {
      section += '- $ziel\n';
    }

    return section;
  }

  String _generateKlientenReport(List<Client> clients) {
    String report = '''
KLIENTEN-ÜBERSICHT
============================================================

ANZAHL KLIENTEN: ${clients.length}
ERSTELLT: ${_formatDateTime(DateTime.now())}

============================================================

''';

    if (clients.isEmpty) {
      report += 'Keine Klienten erfasst.\n';
    } else {
      for (final client in clients) {
        report += '''
${client.vollstaendigerName}
Berufsgruppe: ${client.berufsgruppe ?? 'Nicht angegeben'}
Eingliederungshilfe: ${client.eingliederung}
${client.kostenuebernahme != null ? 'Kostenübernahme: ${client.kostenuebernahme}' : ''}
${client.betreuungSeit != null ? 'Betreuung seit: ${_formatDate(client.betreuungSeit!)}' : ''}
${client.fachleistungsstunden != null ? 'Fachleistungsstunden: ${client.fachleistungsstunden}h' : ''}
${client.fachleistungsstunden != null ? 'Verbrauchte Stunden: ${client.verbrauchteStunden.toStringAsFixed(1)}h (${client.stundenverbrauchProzent.toStringAsFixed(1)}%)' : ''}
${client.fachleistungsstunden != null ? 'Verfügbare Stunden: ${client.verfuegbareStunden.toStringAsFixed(1)}h' : ''}
${_generateClientTIBZiele(client)}

''';
      }
    }

    return report;
  }

  String _generateCompleteReport(List<Arbeitszeit> arbeitszeiten, List<Appointment> appointments) {
    return '''
VOLLSTÄNDIGER BERICHT
============================================================

ZEITRAUM: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}
ERSTELLT: ${_formatDateTime(DateTime.now())}

============================================================

${_generateArbeitszeitenReport(arbeitszeiten)}

============================================================

${_generateFachleistungsstundenReport(appointments.where((a) => a.fachleistungsstunden > 0).toList())}

============================================================

${_generateDokumentationReport(appointments.where((a) => a.notes.isNotEmpty || a.recordedText.isNotEmpty).toList())}
''';
  }

  String _generateBackupReport(Map<String, dynamic> data) {
    return '''
VOLLBACKUP-INFORMATION
============================================================

ERSTELLT: ${_formatDateTime(DateTime.now())}

============================================================

DATENBESTAND:
- Klienten: ${(data['clients'] as List?)?.length ?? 0}
- Termine: ${(data['appointments'] as List?)?.length ?? 0}
- Arbeitszeiten: ${(data['arbeitszeiten'] as List?)?.length ?? 0}
- E-Mail-Ziele: ${(data['emailTargets'] as List?)?.length ?? 0}

HINWEIS: Vollständige Daten sind in der JSON-Struktur enthalten.

============================================================

JSON-DATEN:
${data.toString()}
''';
  }

  String _generateStatisticsReport(AppProvider appProvider) {
    return '''
STATISTIKEN-EXPORT
============================================================

ERSTELLT: ${_formatDateTime(DateTime.now())}

============================================================

ALLGEMEINE STATISTIKEN:
- Gesamtzahl Klienten: ${appProvider.totalClients}
- Gesamtzahl Termine: ${appProvider.totalAppointments}
- Termine diese Woche: ${appProvider.thisWeekAppointments}
- Termine dieser Monat: ${appProvider.thisMonthAppointments}
- Dokumentationsrate: ${(appProvider.documentationRate * 100).toStringAsFixed(1)}%

ARBEITSZEIT-STATISTIKEN:
- Stunden heute: ${appProvider.formatHours(appProvider.hoursWorkedToday)}
- Stunden diese Woche: ${appProvider.formatHours(appProvider.hoursWorkedThisWeek)}
- Stunden dieser Monat: ${appProvider.formatHours(appProvider.hoursWorkedThisMonth)}
- Überstunden: ${appProvider.formatOvertimeHours(appProvider.overtimeHours)}

STUNDENVERBRAUCH-STATISTIKEN:
- Durchschnittlicher Verbrauch: ${appProvider.averageHoursUsage.toStringAsFixed(1)}%
- Klienten im roten Bereich (≥90%): ${appProvider.clientsInRedZone}
- Klienten im gelben Bereich (75-89%): ${appProvider.clientsInYellowZone}
- Klienten im grünen Bereich (<75%): ${appProvider.clientsInGreenZone}
- Status: ${appProvider.hoursUsageStatus}

============================================================

BENUTZEREINSTELLUNGEN:
- Benutzername: ${appProvider.settings.userName}
- Wochenarbeitszeit: ${appProvider.settings.wochenarbeitszeit}h
- Urlaubstage: ${appProvider.settings.urlaubstage}

============================================================
''';
  }

  // Utility methods

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  String _formatDateForFilename(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}