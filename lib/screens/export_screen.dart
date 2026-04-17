import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/arbeitszeit.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../models/fahrweg.dart';
import '../models/export_format.dart';
import '../services/audit_logger.dart';
import '../services/export_service.dart';
import '../utils/responsive_utils.dart';
import 'backup_screen.dart';
import 'berichte_screen.dart';

/// Export-Screen: reiner Export-Hub fuer strukturierte Daten.
///
/// Arbeitet gegen 4 klare Kategorien:
/// 1. Amtliche Einreichung (verlinkt auf Berichte-Screen)
/// 2. Betriebswirtschaftliche Auswertungen (CSV/XLSX)
/// 3. Analyse-Reports (PDF)
/// 4. Backup (verlinkt auf Backup-Screen)
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
        title: const Text('Export'),
        elevation: ResponsiveUtils.isDesktop(context) ? 0 : null,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return SingleChildScrollView(
            padding: ResponsiveUtils.getScreenPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateRangeCard(),
                const SizedBox(height: 20),

                _buildSectionTitle('Amtliche Einreichung'),
                _buildNavigationCard(
                  icon: Icons.gavel,
                  color: Colors.blue,
                  title: 'Berichte & Formulare',
                  subtitle: 'Berliner Formular 101, XRechnung-Abrechnung, '
                      'amtliche Formulare aller Bundeslaender',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BerichteScreen())),
                ),
                const SizedBox(height: 20),

                _buildSectionTitle('Betriebswirtschaft (CSV/Excel)'),
                _buildExportTile(
                  icon: Icons.schedule,
                  color: Colors.indigo,
                  title: 'Arbeitszeiten',
                  subtitle: 'Fuer Lohnabrechnung - mit Taetigkeitsverteilung',
                  onTap: () => _exportArbeitszeiten(appProvider),
                ),
                _buildExportTile(
                  icon: Icons.person_outline,
                  color: Colors.green,
                  title: 'Fachleistungsstunden',
                  subtitle: 'Fuer Controlling - Stunden pro Klient und Zeitraum',
                  onTap: () => _exportFachleistungsstunden(appProvider),
                ),
                _buildExportTile(
                  icon: Icons.directions_car,
                  color: Colors.deepOrange,
                  title: 'Fahrwege',
                  subtitle: 'Fuer Kilometerabrechnung - mit km-Statistik',
                  onTap: () => _exportFahrwege(appProvider),
                ),
                const SizedBox(height: 20),

                _buildSectionTitle('Dokumentation & Analyse'),
                _buildExportTile(
                  icon: Icons.description,
                  color: Colors.orange,
                  title: 'Termin-Dokumentation',
                  subtitle: 'Alle dokumentierten Termine als Text-Report',
                  onTap: () => _exportDokumentation(appProvider),
                ),
                _buildExportTile(
                  icon: Icons.people,
                  color: Colors.purple,
                  title: 'Klienten-Uebersicht',
                  subtitle: 'Stammdaten-Liste (DSGVO-sensibel)',
                  onTap: () => _exportKlienten(appProvider),
                ),
                _buildExportTile(
                  icon: Icons.analytics,
                  color: Colors.teal,
                  title: 'Statistik-Export',
                  subtitle: 'Kennzahlen und Uebersichten',
                  onTap: () => _exportStatistics(appProvider),
                ),
                const SizedBox(height: 20),

                _buildSectionTitle('Backup & Archiv'),
                _buildNavigationCard(
                  icon: Icons.backup,
                  color: Colors.grey,
                  title: 'Backup & Wiederherstellung',
                  subtitle: 'Verschluesselter Gesamt-Datenexport, '
                      'Wiederherstellung aus Backup-Datei',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BackupScreen())),
                ),
                const SizedBox(height: 20),

                _buildSectionTitle('Schnell-Exporte'),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickExportButton(
                        title: 'Dieser Monat',
                        subtitle: 'Alle Daten',
                        icon: Icons.calendar_month,
                        onTap: () => _exportThisMonth(appProvider),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Bausteine ────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              )),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Zeitraum',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectStartDate(context),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Von: ${_formatDate(_startDate)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectEndDate(context),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Bis: ${_formatDate(_endDate)}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: _isExporting
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download),
        onTap: _isExporting ? null : onTap,
      ),
    );
  }

  Widget _buildQuickExportButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: _isExporting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ── Datums-Auswahl ───────────────────────────────────────────────

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
        if (_startDate.isAfter(_endDate)) _endDate = _startDate;
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
      setState(() => _endDate = picked);
    }
  }

  // ── Export-Funktionen ────────────────────────────────────────────

  Future<void> _exportArbeitszeiten(AppProvider appProvider) async {
    final options = await ExportService.showFormatAndDestinationDialog(context);
    if (options == null || !mounted) return;
    final format = options.format;
    setState(() => _isExporting = true);
    try {
      final arbeitszeiten = appProvider.getArbeitszeitenByDateRange(_startDate, _endDate);
      final content = _generateArbeitszeitenCsv(arbeitszeiten);
      final filename = 'Arbeitszeiten_${_fd(_startDate)}_bis_${_fd(_endDate)}';

      final ok = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        ziel: options.ziel,
        arbeitszeiten: arbeitszeiten,
        startDate: _startDate,
        endDate: _endDate,
        exportType: 'arbeitszeiten',
      );
      if (mounted) _feedback(ok, 'Arbeitszeiten', format);
    } catch (e) {
      if (mounted) _showErrorMessage('Fehler: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportFachleistungsstunden(AppProvider appProvider) async {
    final options = await ExportService.showFormatAndDestinationDialog(context);
    if (options == null || !mounted) return;
    final format = options.format;
    setState(() => _isExporting = true);
    try {
      final appointments = appProvider.appointments.where((a) =>
          a.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          a.date.isBefore(_endDate.add(const Duration(days: 1))) &&
          a.fachleistungsstunden > 0).toList();
      final content = _generateFlsCsv(appointments);
      final filename = 'FLS_${_fd(_startDate)}_bis_${_fd(_endDate)}';
      final ok = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        ziel: options.ziel,
        appointments: appointments,
        startDate: _startDate,
        endDate: _endDate,
        exportType: 'fachleistungsstunden',
      );
      if (mounted) _feedback(ok, 'Fachleistungsstunden', format);
    } catch (e) {
      if (mounted) _showErrorMessage('Fehler: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportFahrwege(AppProvider appProvider) async {
    final options = await ExportService.showFormatAndDestinationDialog(context);
    if (options == null || !mounted) return;
    final format = options.format;
    setState(() => _isExporting = true);
    try {
      final fahrwege = appProvider.getFahrwegeByDateRange(_startDate, _endDate);
      final content = _generateFahrwegeCsv(fahrwege, appProvider);
      final filename = 'Fahrwege_${_fd(_startDate)}_bis_${_fd(_endDate)}';
      final ok = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        ziel: options.ziel,
      );
      if (mounted) _feedback(ok, 'Fahrwege', format);
    } catch (e) {
      if (mounted) _showErrorMessage('Fehler: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportDokumentation(AppProvider appProvider) async {
    final options = await ExportService.showFormatAndDestinationDialog(context);
    if (options == null || !mounted) return;
    final format = options.format;
    setState(() => _isExporting = true);
    try {
      final appointments = appProvider.appointments.where((a) =>
          a.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          a.date.isBefore(_endDate.add(const Duration(days: 1))) &&
          (a.notes.isNotEmpty || a.recordedText.isNotEmpty)).toList();
      final content = _generateDokumentationReport(appointments);
      final filename = 'Dokumentation_${_fd(_startDate)}_bis_${_fd(_endDate)}';
      final ok = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        ziel: options.ziel,
        appointments: appointments,
        startDate: _startDate,
        endDate: _endDate,
        exportType: 'dokumentation',
      );
      if (mounted) _feedback(ok, 'Dokumentation', format);
    } catch (e) {
      if (mounted) _showErrorMessage('Fehler: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportKlienten(AppProvider appProvider) async {
    // DSGVO-Check: wie viele Klienten haben KEINE Einwilligung?
    final ohneEinwilligung = appProvider.clients
        .where((c) => !c.einwilligungVorhanden)
        .toList();
    if (ohneEinwilligung.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 48),
          title: const Text('DSGVO-Hinweis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fuer ${ohneEinwilligung.length} von ${appProvider.clients.length} '
                'Klienten liegt keine dokumentierte DSGVO-Einwilligung vor.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Der Export dieser personenbezogenen Daten (Art. 9 DSGVO) '
                'darf nur zu zweckgebundenen, dokumentierten Zwecken erfolgen. '
                'Der Export wird im Audit-Log protokolliert.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Betroffene Klienten:\n'
                  '${ohneEinwilligung.take(5).map((c) => "• ${c.vollstaendigerName}").join("\n")}'
                  '${ohneEinwilligung.length > 5 ? "\n• ... und ${ohneEinwilligung.length - 5} weitere" : ""}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Trotzdem exportieren'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      if (!mounted) return;
    }

    final options = await ExportService.showFormatAndDestinationDialog(context);
    if (options == null || !mounted) return;
    final format = options.format;
    setState(() => _isExporting = true);
    try {
      final content = _generateKlientenCsv(appProvider.clients);
      final filename = 'Klienten_${_fd(DateTime.now())}';
      final ok = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        ziel: options.ziel,
        clients: appProvider.clients,
        exportType: 'klienten',
      );
      if (mounted) _feedback(ok, 'Klienten', format);
    } catch (e) {
      if (mounted) _showErrorMessage('Fehler: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportStatistics(AppProvider appProvider) async {
    final options = await ExportService.showFormatAndDestinationDialog(context);
    if (options == null || !mounted) return;
    final format = options.format;
    setState(() => _isExporting = true);
    try {
      final content = _generateStatisticsReport(appProvider);
      final filename = 'Statistiken_${_fd(DateTime.now())}';
      final ok = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        ziel: options.ziel,
      );
      if (mounted) _feedback(ok, 'Statistiken', format);
    } catch (e) {
      if (mounted) _showErrorMessage('Fehler: $e');
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
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
    final options = await ExportService.showFormatAndDestinationDialog(context);
    if (options == null || !mounted) return;
    final format = options.format;
    setState(() => _isExporting = true);
    try {
      final arbeitszeiten = appProvider.getArbeitszeitenByDateRange(_startDate, _endDate);
      final appointments = appProvider.appointments.where((a) =>
          a.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          a.date.isBefore(_endDate.add(const Duration(days: 1)))).toList();
      final content = _generateMonthsReport(arbeitszeiten, appointments);
      final filename = 'Monatsbericht_${_fd(_startDate)}';
      final ok = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        ziel: options.ziel,
        arbeitszeiten: arbeitszeiten,
        appointments: appointments,
      );
      if (mounted) _feedback(ok, 'Monatsbericht', format);
    } catch (e) {
      if (mounted) _showErrorMessage('Fehler: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // ── Report-Generierung (CSV-bevorzugt) ──────────────────────────

  String _generateArbeitszeitenCsv(List<Arbeitszeit> arbeitszeiten) {
    final sorted = List<Arbeitszeit>.from(arbeitszeiten)
      ..sort((a, b) => a.datum.compareTo(b.datum));
    final buf = StringBuffer();
    buf.writeln('Datum;Start;Ende;Dauer (h);Taetigkeit;Typ;Notizen');
    for (final a in sorted) {
      final stunden = (a.arbeitszeit.inMinutes / 60.0).toStringAsFixed(2);
      final notiz = _csvEscape(a.notizen);
      buf.writeln('${_formatDate(a.datum)};${a.formatierteStartzeit};${a.formatierteEndzeit};$stunden;${_csvEscape(a.taetigkeit)};${a.typ.displayName};$notiz');
    }
    return buf.toString();
  }

  String _generateFlsCsv(List<Appointment> appointments) {
    final sorted = List<Appointment>.from(appointments)
      ..sort((a, b) => a.date.compareTo(b.date));
    final buf = StringBuffer();
    buf.writeln('Datum;Start;Ende;Klient;FLS (h);Berufsgruppe;Notizen');
    for (final a in sorted) {
      if (a.isIndirect && a.clientAllocations != null) {
        for (final alloc in a.clientAllocations!) {
          buf.writeln('${_formatDate(a.date)};${_formatTime(a.startTime)};${_formatTime(a.endTime)};${_csvEscape(alloc.clientName)};${alloc.stunden.toStringAsFixed(2)};${_csvEscape(a.berufsgruppe)};${_csvEscape(a.notes)}');
        }
      } else {
        buf.writeln('${_formatDate(a.date)};${_formatTime(a.startTime)};${_formatTime(a.endTime)};${_csvEscape(a.clientName)};${a.fachleistungsstunden.toStringAsFixed(2)};${_csvEscape(a.berufsgruppe)};${_csvEscape(a.notes)}');
      }
    }
    return buf.toString();
  }

  String _generateFahrwegeCsv(List<Fahrweg> fahrwege, AppProvider appProvider) {
    final sorted = List<Fahrweg>.from(fahrwege)..sort((a, b) => a.datum.compareTo(b.datum));
    final buf = StringBuffer();
    buf.writeln('Datum;Start;Ziel;km;Klient;Notizen');
    for (final f in sorted) {
      final clientName = f.clientId != null
          ? (appProvider.clients.where((c) => c.id == f.clientId).map((c) => c.name).firstOrNull ?? '')
          : '';
      buf.writeln('${_formatDate(f.datum)};${_csvEscape(f.startStandortName)};${_csvEscape(f.zielStandortName)};${f.distanzKm.toStringAsFixed(1)};${_csvEscape(clientName)};${_csvEscape(f.notizen ?? "")}');
    }
    return buf.toString();
  }

  String _generateKlientenCsv(List<Client> clients) {
    final buf = StringBuffer();
    buf.writeln('Name;Vorname;Nachname;Geburtsdatum;Kostentraeger;Betreuung seit;FLS bewilligt;FLS verbraucht;FLS %;Einwilligung');
    for (final c in clients) {
      final bew = c.fachleistungsstunden?.toString() ?? '';
      final verbr = c.fachleistungsstunden != null ? c.verbrauchteStunden.toStringAsFixed(1) : '';
      final prozent = c.fachleistungsstunden != null ? '${c.stundenverbrauchProzent.toStringAsFixed(1)}%' : '';
      final geb = c.geburtsdatum != null ? _formatDate(c.geburtsdatum!) : '';
      final seit = c.betreuungSeit != null ? _formatDate(c.betreuungSeit!) : '';
      final einw = c.einwilligungVorhanden ? 'ja' : 'nein';
      buf.writeln('${_csvEscape(c.vollstaendigerName)};${_csvEscape(c.vorname ?? "")};${_csvEscape(c.nachname ?? "")};$geb;${_csvEscape(c.kostenuebernahme ?? "")};$seit;$bew;$verbr;$prozent;$einw');
    }
    return buf.toString();
  }

  String _generateDokumentationReport(List<Appointment> appointments) {
    final sorted = List<Appointment>.from(appointments)
      ..sort((a, b) => a.date.compareTo(b.date));
    final buf = StringBuffer();
    buf.writeln('Dokumentations-Export');
    buf.writeln('Zeitraum: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}');
    buf.writeln('Anzahl: ${sorted.length} Termine');
    buf.writeln('Erstellt: ${_formatDateTime(DateTime.now())}\n');

    if (sorted.isEmpty) {
      buf.writeln('Keine dokumentierten Termine im Zeitraum.');
      return buf.toString();
    }

    for (final a in sorted) {
      buf.writeln('${_formatDate(a.date)} | ${_formatTime(a.startTime)} - ${_formatTime(a.endTime)}');
      buf.writeln('Klient: ${a.clientName}');
      buf.writeln('Berufsgruppe: ${a.berufsgruppe}');
      if (a.notes.isNotEmpty) buf.writeln('Notizen: ${a.notes}');
      if (a.recordedText.isNotEmpty) buf.writeln('Sprachaufzeichnung: ${a.recordedText}');
      buf.writeln('');
    }
    return buf.toString();
  }

  String _generateMonthsReport(List<Arbeitszeit> arbeitszeiten, List<Appointment> appointments) {
    final az = arbeitszeiten.fold<double>(0, (s, a) => s + a.arbeitszeit.inMinutes / 60.0);
    final fls = appointments.fold<double>(0, (s, a) => s + a.fachleistungsstunden);
    final buf = StringBuffer();
    buf.writeln('Monatsbericht ${_formatDate(_startDate)} bis ${_formatDate(_endDate)}');
    buf.writeln('Arbeitszeit gesamt: ${az.toStringAsFixed(2)} h');
    buf.writeln('FLS gesamt: ${fls.toStringAsFixed(2)} h');
    buf.writeln('Anzahl Termine: ${appointments.length}');
    buf.writeln('Anzahl Arbeitszeit-Eintraege: ${arbeitszeiten.length}');
    return buf.toString();
  }

  String _generateStatisticsReport(AppProvider app) {
    final buf = StringBuffer();
    buf.writeln('Statistiken (${_formatDateTime(DateTime.now())})');
    buf.writeln('');
    buf.writeln('Klienten gesamt: ${app.totalClients}');
    buf.writeln('Termine gesamt: ${app.totalAppointments}');
    buf.writeln('Termine diese Woche: ${app.thisWeekAppointments}');
    buf.writeln('Termine dieser Monat: ${app.thisMonthAppointments}');
    buf.writeln('Dokumentationsrate: ${(app.documentationRate * 100).toStringAsFixed(1)}%');
    buf.writeln('');
    buf.writeln('Arbeitszeit:');
    buf.writeln('  heute: ${app.formatHours(app.hoursWorkedToday)}');
    buf.writeln('  diese Woche: ${app.formatHours(app.hoursWorkedThisWeek)}');
    buf.writeln('  dieser Monat: ${app.formatHours(app.hoursWorkedThisMonth)}');
    buf.writeln('  Ueberstunden: ${app.formatOvertimeHours(app.overtimeHours)}');
    buf.writeln('');
    buf.writeln('Stundenverbrauch:');
    buf.writeln('  Durchschnitt: ${app.averageHoursUsage.toStringAsFixed(1)}%');
    buf.writeln('  Rot (>=90%): ${app.clientsInRedZone}');
    buf.writeln('  Gelb (75-89%): ${app.clientsInYellowZone}');
    buf.writeln('  Gruen (<75%): ${app.clientsInGreenZone}');
    return buf.toString();
  }

  // ── Utility ──────────────────────────────────────────────────────

  String _csvEscape(String s) {
    if (s.contains(';') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  void _feedback(bool ok, String label, ExportFormat format) {
    if (ok) {
      _showSuccessMessage('$label als ${format.displayName} exportiert');
      // Audit-Log: erfolgreicher Export wird protokolliert (DSGVO)
      final userId = context.read<AppProvider>().settings.userName;
      AuditLogger.instance.logDataExport(userId, '$label.${format.extension}');
    } else {
      _showErrorMessage('Export fehlgeschlagen: $label');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);
  String _formatDateTime(DateTime d) => DateFormat('dd.MM.yyyy HH:mm').format(d);
  String _formatTime(DateTime d) => DateFormat('HH:mm').format(d);
  String _fd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
