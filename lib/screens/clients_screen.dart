import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/client.dart';
import '../models/icf_bereiche.dart';
import '../models/kostentraeger.dart';
import '../utils/responsive_utils.dart';
import '../services/export_service.dart';
import '../services/permission_service.dart';
import '../widgets/gdpr_delete_dialog.dart';
import '../models/export_format.dart';
import 'package:intl/intl.dart';
import 'create_appointment_screen.dart';
import 'create_client_screen.dart';

class ClientsScreen extends StatefulWidget {
  final bool showAddDialog;
  
  const ClientsScreen({super.key, this.showAddDialog = false});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.showAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToCreateClient();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Klienten alphabetisch nach Nachnamen sortieren
        var clients = _searchQuery.isEmpty
            ? appProvider.clients
            : appProvider.searchClients(_searchQuery);

        // Sortierung nach Nachname, dann Vorname
        clients = clients.toList()..sort((a, b) {
          final nachnameA = a.nachname ?? a.name;
          final nachnameB = b.nachname ?? b.name;
          final nachnameComparison = nachnameA.toLowerCase().compareTo(nachnameB.toLowerCase());

          if (nachnameComparison != 0) {
            return nachnameComparison;
          }

          // Falls Nachname gleich, nach Vorname sortieren
          final vornameA = a.vorname ?? '';
          final vornameB = b.vorname ?? '';
          return vornameA.toLowerCase().compareTo(vornameB.toLowerCase());
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Klienten'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Klienten suchen...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          ),
          body: _buildClientsList(context, appProvider, clients),
          floatingActionButton: PermissionService(appProvider.settings.userRole).canCreateClient
              ? FloatingActionButton.extended(
                  heroTag: "clients_fab",
                  onPressed: _navigateToCreateClient,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Neuer Klient'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildClientsList(BuildContext context, AppProvider appProvider, List<Client> clients) {
    if (appProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                  ? 'Noch keine Klienten vorhanden'
                  : 'Keine Klienten gefunden',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? 'Fügen Sie Ihren ersten Klienten hinzu'
                  : 'Versuchen Sie einen anderen Suchbegriff',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (ResponsiveUtils.isDesktop(context)) {
      return _buildDesktopLayout(context, appProvider, clients);
    } else {
      return _buildMobileLayout(context, appProvider, clients);
    }
  }

  Widget _buildMobileLayout(BuildContext context, AppProvider appProvider, List<Client> clients) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: clients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final client = clients[index];
        return _buildClientCard(context, appProvider, client);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppProvider appProvider, List<Client> clients) {
    final gridColumns = ResponsiveUtils.getGridColumns(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomScrollView(
        slivers: [
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final client = clients[index];
                return _buildClientCard(context, appProvider, client);
              },
              childCount: clients.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, AppProvider appProvider, Client client) {
    final appointmentCount = appProvider.getAppointmentsForClient(client.id).length;

    return Card(
      child: InkWell(
        onTap: () => _showClientActions(context, appProvider, client),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      client.vollstaendigerName.isNotEmpty ? client.vollstaendigerName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.vollstaendigerName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          client.berufsgruppe ?? 'Nicht angegeben',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleClientAction(context, appProvider, client, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Bearbeiten'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'document',
                        child: ListTile(
                          leading: Icon(Icons.note_add),
                          title: Text('Dokumentieren'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'fls_export',
                        child: ListTile(
                          leading: Icon(Icons.file_download),
                          title: Text('FLS Export'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Löschen', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  client.eingliederung ?? 'Nicht angegeben',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.event_note,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$appointmentCount Termine',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Erstellt: ${_formatDate(client.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientActions(BuildContext context, AppProvider appProvider, Client client) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Bearbeiten'),
            onTap: () {
              Navigator.pop(context);
              _navigateToEditClient(client);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_add),
            title: const Text('Dokumentieren'),
            onTap: () {
              Navigator.pop(context);
              _navigateToNewAppointment(context, client);
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('FLS Export'),
            onTap: () {
              Navigator.pop(context);
              _exportClientFLS(context, appProvider, client);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Löschen', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteClientDialog(context, appProvider, client);
            },
          ),
        ],
      ),
    );
  }

  void _handleClientAction(BuildContext context, AppProvider appProvider, Client client, String action) {
    switch (action) {
      case 'edit':
        _navigateToEditClient(client);
        break;
      case 'document':
        _navigateToNewAppointment(context, client);
        break;
      case 'fls_export':
        _exportClientFLS(context, appProvider, client);
        break;
      case 'delete':
        _showDeleteClientDialog(context, appProvider, client);
        break;
    }
  }

  void _navigateToCreateClient() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateClientScreen(),
      ),
    );
  }

  void _navigateToEditClient(Client client) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateClientScreen(client: client),
      ),
    );
  }

  void _showDeleteClientDialog(BuildContext context, AppProvider appProvider, Client client) {
    GdprDeleteDialog.show(
      context: context,
      clientId: client.id,
      clientName: client.vollstaendigerName,
      currentUser: appProvider.settings.userName,
      onDelete: () => appProvider.deleteClient(client.id),
    ).then((deleted) {
      if (deleted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klient DSGVO-konform geloescht'), backgroundColor: Colors.green),
        );
      }
    });
    // Alter Dialog-Code entfernt, GdprDeleteDialog uebernimmt
    return;
    // Dead code below kept for reference during transition
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Klient löschen'),
        content: Text('Möchten Sie "${client.vollstaendigerName}" wirklich löschen?\n\nAlle zugehörigen Termine werden ebenfalls gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await appProvider.deleteClient(client.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Klient gelöscht')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _navigateToNewAppointment(BuildContext context, Client client) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateAppointmentScreen(preSelectedClient: client),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  // FLS-Berechnungshilfen (delegiert an AppProvider)
  double _getKalkulationsfaktor(Client c) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return appProvider.getKalkulationsfaktor(c);
  }

  double _getStundensatz(Client c) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return appProvider.getStundensatz(c);
  }

  double _getGesamtarbeitsstunden(Client c) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return appProvider.getGesamtarbeitsstunden(c);
  }

  double _getAbrechnungsbetrag(Client c) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return appProvider.getAbrechnungsbetrag(c);
  }

  Future<void> _exportClientFLS(BuildContext context, AppProvider appProvider, Client client) async {
    try {
      // Dialog für Zeitraum und Format-Auswahl
      final result = await _showClientFLSExportDialog(context);
      if (result == null || !context.mounted) return;

      final startDate = result['startDate'] as DateTime;
      final endDate = result['endDate'] as DateTime;
      final format = result['format'] as ExportFormat;

      // Termine des Klienten im ausgewählten Zeitraum filtern
      final clientAppointments = appProvider.appointments.where((appointment) =>
          appointment.clientId == client.id &&
          appointment.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          appointment.date.isBefore(endDate.add(const Duration(days: 1))) &&
          appointment.fachleistungsstunden > 0
      ).toList();

      if (clientAppointments.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Keine Fachleistungsstunden für ${client.name} im ausgewählten Zeitraum gefunden.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Export-Inhalt generieren
      final content = _generateClientFLSReport(client, clientAppointments, startDate, endDate);
      final filename = 'FLS_${client.name.replaceAll(' ', '_')}_${_formatDateForFilename(startDate)}_bis_${_formatDateForFilename(endDate)}';

      // Export durchführen
      final success = await ExportService.exportData(
        context: context,
        content: content,
        filename: filename,
        format: format,
        appointments: clientAppointments,
        startDate: startDate,
        endDate: endDate,
        exportType: 'client_fls',
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('FLS für ${client.name} erfolgreich als ${format.displayName} exportiert'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fehler beim Export'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim FLS-Export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showClientFLSExportDialog(BuildContext context) async {
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();
    ExportFormat selectedFormat = ExportFormat.pdf;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('FLS Export - Zeitraum wählen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Schnell-Auswahl für Monate
              const Text('Schnell-Auswahl:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final now = DateTime.now();
                      final startOfMonth = DateTime(now.year, now.month, 1);
                      final endOfMonth = DateTime(now.year, now.month + 1, 0);
                      setState(() {
                        startDate = startOfMonth;
                        endDate = endOfMonth;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Aktueller Monat'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final now = DateTime.now();
                      final lastMonth = DateTime(now.year, now.month - 1, 1);
                      final startOfMonth = lastMonth;
                      final endOfMonth = DateTime(lastMonth.year, lastMonth.month + 1, 0);
                      setState(() {
                        startDate = startOfMonth;
                        endDate = endOfMonth;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Letzter Monat'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final now = DateTime.now();
                      final twoMonthsAgo = DateTime(now.year, now.month - 2, 1);
                      final startOfMonth = twoMonthsAgo;
                      final endOfMonth = DateTime(twoMonthsAgo.year, twoMonthsAgo.month + 1, 0);
                      setState(() {
                        startDate = startOfMonth;
                        endDate = endOfMonth;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Vorletzter Monat'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Von'),
                subtitle: Text(_formatDate(startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => startDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Bis'),
                subtitle: Text(_formatDate(endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: startDate,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => endDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExportFormat>(
                decoration: const InputDecoration(
                  labelText: 'Export-Format',
                  border: OutlineInputBorder(),
                ),
                value: selectedFormat,
                items: ExportFormat.values.map((format) {
                  return DropdownMenuItem(
                    value: format,
                    child: Text(format.displayName),
                  );
                }).toList(),
                onChanged: (format) {
                  if (format != null) {
                    setState(() => selectedFormat = format);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop({
                'startDate': startDate,
                'endDate': endDate,
                'format': selectedFormat,
              }),
              child: const Text('Exportieren'),
            ),
          ],
        ),
      ),
    );
  }

  String _generateClientFLSReport(Client client, List<dynamic> appointments, DateTime startDate, DateTime endDate) {
    final sortedAppointments = List.from(appointments)
      ..sort((a, b) => a.date.compareTo(b.date));

    String report = '''
FACHLEISTUNGSSTUNDEN - EINZELKLIENT
============================================================

KLIENT: ${client.vollstaendigerName}
ZEITRAUM: ${_formatDate(startDate)} - ${_formatDate(endDate)}
ANZAHL TERMINE: ${sortedAppointments.length}
ERSTELLT: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}

============================================================

''';

    if (sortedAppointments.isEmpty) {
      report += 'Keine Termine mit Fachleistungsstunden im ausgewählten Zeitraum.\n';
    } else {
      double gesamtStunden = 0;
      Map<String, int> tibZielMinutenGesamt = {};

      for (final appointment in sortedAppointments) {
        gesamtStunden += appointment.fachleistungsstunden;

        // TIB-Ziele Minuten sammeln
        if (appointment.tibZielMinuten != null) {
          appointment.tibZielMinuten.forEach((ziel, minuten) {
            tibZielMinutenGesamt[ziel] = (tibZielMinutenGesamt[ziel] ?? 0) + (minuten as int);
          });
        }

        report += '''
${_formatDate(appointment.date)} | ${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}
Fachleistungsstunden: ${appointment.fachleistungsstunden}h
Berufsgruppe: ${appointment.berufsgruppe}
${_generateTIBZieleSection(appointment)}
${appointment.notes.isNotEmpty ? 'Notizen: ${appointment.notes}' : ''}

''';
      }

      report += '''
============================================================

ZUSAMMENFASSUNG:
Gesamt-Fachleistungsstunden: ${gesamtStunden.toStringAsFixed(2)}h
''';

      // TIB-Ziele Gesamtübersicht
      if (tibZielMinutenGesamt.isNotEmpty) {
        report += '''

TIB-ZIELE GESAMTÜBERSICHT:
''';
        tibZielMinutenGesamt.forEach((ziel, minuten) {
          final stunden = (minuten / 60).toStringAsFixed(1);
          report += '- $ziel: ${minuten} Min (${stunden}h)\n';
        });

        final gesamtTibMinuten = tibZielMinutenGesamt.values.fold(0, (sum, minuten) => sum + minuten);
        final gesamtTibStunden = (gesamtTibMinuten / 60).toStringAsFixed(1);
        report += '\nTIB-Ziele Gesamtzeit: ${gesamtTibMinuten} Min (${gesamtTibStunden}h)\n';
      }

      // Klient-Informationen
      report += '''

============================================================

KLIENT-INFORMATIONEN:
Berufsgruppe: ${client.berufsgruppe ?? 'Nicht angegeben'}
Eingliederungshilfe: ${client.eingliederung}
${client.betreuungSeit != null ? 'Betreuung seit: ${_formatDate(client.betreuungSeit!)}' : ''}
${client.fachleistungsstunden != null ? 'Bewilligte Fachleistungsstunden: ${client.fachleistungsstunden}h' : ''}
${client.fachleistungsstunden != null ? 'Verbrauchte Stunden: ${client.verbrauchteStunden.toStringAsFixed(1)}h (${client.stundenverbrauchProzent.toStringAsFixed(1)}%)' : ''}
${client.fachleistungsstunden != null ? 'Verfügbare Stunden: ${client.verfuegbareStunden.toStringAsFixed(1)}h' : ''}
${client.fachleistungsstunden != null ? 'Gesamtarbeitszeit (mit KLE): ${_getGesamtarbeitsstunden(client).toStringAsFixed(1)}h (Faktor: ${_getKalkulationsfaktor(client).toStringAsFixed(2)}${client.kalkulationsfaktorOverride != null ? " - klientenspezifisch" : ""})' : ''}
${client.fachleistungsstunden != null ? 'Abrechnungsbetrag: ${_getAbrechnungsbetrag(client).toStringAsFixed(2)} EUR (Satz: ${_getStundensatz(client).toStringAsFixed(2)} EUR${client.stundensatzOverride != null ? " - klientenspezifisch" : ""})' : ''}

''';

      // Individuelle TIB-Ziele des Klienten
      if (client.individuelleTibZiele != null && client.individuelleTibZiele!.isNotEmpty) {
        report += '''
INDIVIDUELLE TIB-ZIELE DES KLIENTEN:
''';
        for (final ziel in client.individuelleTibZiele!) {
          report += '- $ziel\n';
        }
        report += '\n';
      }
    }

    return report;
  }

  String _generateTIBZieleSection(dynamic appointment) {
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

    return section;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateForFilename(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}

