import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/client.dart';
import '../models/appointment.dart';
import '../services/export_service.dart';
import '../utils/responsive_utils.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  Client? selectedClient;
  DateTime startDate = DateTime.now(); // Default: today
  DateTime endDate = DateTime.now(); // Default: today
  bool showingClientPicker = false;
  String generatedReport = '';
  bool isGeneratingReport = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final filteredAppointments = _getFilteredAppointments(appProvider);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Termine & Dokumentation'),
            elevation: ResponsiveUtils.isDesktop(context) ? 0 : null,
          ),
          body: _buildBody(context, appProvider, filteredAppointments),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppProvider appProvider, List<Appointment> filteredAppointments) {
    if (ResponsiveUtils.isDesktop(context)) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildReportGenerator(context, appProvider, filteredAppointments),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 1,
            child: _buildAppointmentsList(context, appProvider, filteredAppointments),
          ),
        ],
      );
    } else {
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.description), text: 'Berichte'),
                Tab(icon: Icon(Icons.event), text: 'Alle Termine'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildReportGenerator(context, appProvider, filteredAppointments),
                  _buildAppointmentsList(context, appProvider, filteredAppointments),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildReportGenerator(BuildContext context, AppProvider appProvider, List<Appointment> filteredAppointments) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Klient auswählen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showClientPicker(context, appProvider),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedClient?.name ?? 'Klient auswählen',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: selectedClient == null 
                                        ? Theme.of(context).hintColor 
                                        : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                if (selectedClient != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    selectedClient!.berufsgruppe ?? 'Nicht angegeben',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    selectedClient!.eingliederung ?? 'Nicht angegeben',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📅 Zeitraum',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Von'),
                          subtitle: Text(_formatDate(startDate)),
                          leading: const Icon(Icons.calendar_today),
                          onTap: () => _selectStartDate(context),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Bis'),
                          subtitle: Text(_formatDate(endDate)),
                          leading: const Icon(Icons.calendar_today),
                          onTap: () => _selectEndDate(context),
                        ),
                      ),
                    ],
                  ),
                  if (selectedClient != null) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.event_note),
                      title: const Text('Gefundene Termine'),
                      trailing: Text(
                        '${filteredAppointments.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (selectedClient != null && filteredAppointments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📄 Bericht erstellen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isGeneratingReport ? null : () => _generateAndShareReport(context, appProvider, filteredAppointments),
                        icon: isGeneratingReport 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.description),
                        label: Text(isGeneratingReport ? 'Wird erstellt...' : 'Bericht erstellen & exportieren'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstellt einen detaillierten Zeitraum-Bericht für ${selectedClient!.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          if (selectedClient != null && filteredAppointments.isEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Keine Termine gefunden',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Für den ausgewählten Zeitraum wurden keine Termine für ${selectedClient!.name} gefunden.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(BuildContext context, AppProvider appProvider, List<Appointment> filteredAppointments) {
    if (appProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredAppointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Keine Termine gefunden',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Wählen Sie einen Klienten und Zeitraum aus',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final sortedAppointments = List<Appointment>.from(filteredAppointments)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedAppointments.length,
      itemBuilder: (context, index) {
        final appointment = sortedAppointments[index];
        final client = appProvider.getClientById(appointment.clientId);
        
        final isIndirect = appointment.isIndirect;
        final allocCount = appointment.clientAllocations?.length ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIndirect
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: isIndirect
                  ? Icon(Icons.groups, color: Colors.orange[700], size: 20)
                  : Text(
                      appointment.clientName[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            title: Text(isIndirect
                ? '${appointment.effectiveTerminArt.displayName} ($allocCount Klienten)'
                : appointment.clientName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDateTime(appointment.date)),
                if (!isIndirect && client != null) Text('${client.berufsgruppe} • ${client.eingliederung}'),
                if (isIndirect && appointment.clientAllocations != null)
                  Text(
                    appointment.clientAllocations!.map((a) => '${a.clientName} (${a.minuten} Min)').join(', '),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (appointment.notes.isNotEmpty || appointment.recordedText.isNotEmpty)
                  Text(
                    'Dokumentiert',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAppointmentDetails(context, appointment, client),
          ),
        );
      },
    );
  }

  List<Appointment> _getFilteredAppointments(AppProvider appProvider) {
    if (selectedClient == null) return [];

    final filteredAppointments = appProvider.appointments.where((appointment) {
      // Auch indirekte Termine einbeziehen, die eine Allocation für den Klienten haben
      final clientMatch = appointment.clientId == selectedClient!.id ||
          (appointment.isIndirect && appointment.clientAllocations?.any((a) => a.clientId == selectedClient!.id) == true);
      final dateInRange = appointment.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                         appointment.date.isBefore(endDate.add(const Duration(days: 1)));

      return clientMatch && dateInRange;
    }).toList();
    
    // Debug output only when client is selected and we have results
    if (selectedClient != null) {
      print('🔍 Filter Debug: Client "${selectedClient!.name}" (${selectedClient!.id}) - Found ${filteredAppointments.length}/${appProvider.appointments.length} appointments in range ${_formatDate(startDate)} - ${_formatDate(endDate)}');
    }
    
    filteredAppointments.sort((a, b) => a.date.compareTo(b.date));
    return filteredAppointments;
  }

  void _showClientPicker(BuildContext context, AppProvider appProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Klient auswählen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: appProvider.clients.length,
                itemBuilder: (context, index) {
                  final client = appProvider.clients[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                      child: Text(
                        client.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(client.name),
                    subtitle: Text('${client.berufsgruppe} • ${client.eingliederung}'),
                    onTap: () {
                      setState(() {
                        selectedClient = client;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now();
    final initialDate = startDate.isBefore(firstDate) ? firstDate : 
                       startDate.isAfter(lastDate) ? lastDate : startDate;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
        if (startDate.isAfter(endDate)) {
          endDate = startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final firstDate = startDate;
    final lastDate = DateTime.now();
    final initialDate = endDate.isBefore(firstDate) ? firstDate : 
                       endDate.isAfter(lastDate) ? lastDate : endDate;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
    }
  }

  Future<void> _generateAndShareReport(BuildContext context, AppProvider appProvider, List<Appointment> filteredAppointments) async {
    setState(() {
      isGeneratingReport = true;
    });

    try {
      final report = _generateReport(filteredAppointments);
      final fileName = '${_generateFileName()}.txt';

      await ExportService.saveAndShare(
        context: context,
        bytes: Uint8List.fromList(report.codeUnits),
        filename: fileName,
        mimeType: 'text/plain',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Export: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingReport = false;
        });
      }
    }
  }

  String _generateReport(List<Appointment> appointments) {
    final client = selectedClient!;
    
    String report = '''
ZEITRAUM-DOKUMENTATION - EINGLIEDERUNGSHILFE
============================================================

KLIENT: ${client.name}
BERUFSGRUPPE: ${client.berufsgruppe}
EINGLIEDERUNGSHILFE: ${client.eingliederung}

ZEITRAUM: ${_formatDate(startDate)} - ${_formatDate(endDate)}
ANZAHL TERMINE: ${appointments.length}

============================================================

''';

    if (appointments.isEmpty) {
      report += '''
⚠️ KEINE TERMINE GEFUNDEN

Für den ausgewählten Zeitraum wurden keine Termine für diesen Klienten gefunden.

''';
    } else {
      // Termine nach Datum gruppieren
      final groupedAppointments = <String, List<Appointment>>{};
      for (final appointment in appointments) {
        final dateKey = _formatDate(appointment.date);
        groupedAppointments.putIfAbsent(dateKey, () => []).add(appointment);
      }

      final sortedDates = groupedAppointments.keys.toList()..sort();

      for (final dateKey in sortedDates) {
        final dayAppointments = groupedAppointments[dateKey]!;
        
        report += '''
📅 $dateKey
----------------------------------------

''';

        for (int i = 0; i < dayAppointments.length; i++) {
          final appointment = dayAppointments[i];
          report += '''
TERMIN ${i + 1}:
Zeit: ${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}

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

          report += '${List.filled(30, '.').join()}\n\n';
        }
      }

      // Zusammenfassung
      final totalDuration = _calculateTotalDuration(appointments);
      final averageDuration = appointments.isNotEmpty ? totalDuration / appointments.length : 0.0;

      report += '''

============================================================
ZUSAMMENFASSUNG
============================================================

📊 STATISTIK:
• Gesamtanzahl Termine: ${appointments.length}
• Gesamtdauer: ${_formatDuration(totalDuration)}
• Durchschnittliche Dauer: ${_formatDuration(averageDuration)}
• Erste Dokumentation: ${_formatDate(appointments.first.date)}
• Letzte Dokumentation: ${_formatDate(appointments.last.date)}

📋 DOKUMENTATIONSRATE:
• Termine mit Notizen: ${appointments.where((a) => a.notes.isNotEmpty).length}
• Termine mit Sprachaufzeichnung: ${appointments.where((a) => a.recordedText.isNotEmpty).length}
• Vollständig dokumentiert: ${appointments.where((a) => a.notes.isNotEmpty || a.recordedText.isNotEmpty).length}

============================================================
Erstellt am: ${_formatDateTime(DateTime.now())}
Eingliederungshilfe-App (Flutter Version)
============================================================
''';
    }

    return report;
  }

  String _generateFileName() {
    final client = selectedClient!;
    final startFormatted = _formatDateForFilename(startDate);
    final endFormatted = _formatDateForFilename(endDate);
    
    return '${client.name}_${startFormatted}_bis_${endFormatted}'
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
  }

  double _calculateTotalDuration(List<Appointment> appointments) {
    double total = 0;
    for (final appointment in appointments) {
      final duration = appointment.endTime.difference(appointment.startTime).inMinutes;
      total += duration;
    }
    return total;
  }

  String _formatDuration(double minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins.round()}min';
    }
    return '${mins.round()}min';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDateForFilename(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }

  void _showAppointmentDetails(BuildContext context, Appointment appointment, Client? client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appointment.clientName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📅 ${_formatDateTime(appointment.date)}'),
              if (client != null) ...[
                const SizedBox(height: 8),
                Text('👤 ${client.berufsgruppe}'),
                Text('🏥 ${client.eingliederung}'),
              ],
              if (appointment.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('📝 Notizen:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(appointment.notes),
              ],
              if (appointment.recordedText.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('🎤 Sprachaufzeichnung:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(appointment.recordedText),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}