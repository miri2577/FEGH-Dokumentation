import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/appointment.dart';

class DokumentationUebersichtScreen extends StatefulWidget {
  const DokumentationUebersichtScreen({super.key});

  @override
  State<DokumentationUebersichtScreen> createState() => _DokumentationUebersichtScreenState();
}

class _DokumentationUebersichtScreenState extends State<DokumentationUebersichtScreen> {
  String _searchQuery = '';
  String? _selectedClientId;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Appointment> _filteredAppointments(List<Appointment> all) {
    return all.where((a) {
      // Nur Termine mit Dokumentation (Notizen oder Transkription)
      if (a.notes.isEmpty && a.recordedText.isEmpty) return false;

      // Klient-Filter
      if (_selectedClientId != null && a.clientId != _selectedClientId) return false;

      // Datumsbereich-Filter
      if (_selectedDateRange != null) {
        if (a.date.isBefore(_selectedDateRange!.start) ||
            a.date.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Suchtext-Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!a.clientName.toLowerCase().contains(q) &&
            !a.notes.toLowerCase().contains(q) &&
            !a.recordedText.toLowerCase().contains(q)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokumentationsübersicht'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_selectedClientId != null || _selectedDateRange != null || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Filter zurücksetzen',
              onPressed: () {
                setState(() {
                  _selectedClientId = null;
                  _selectedDateRange = null;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          final appointments = _filteredAppointments(appProvider.appointments);
          final clients = appProvider.clients;

          return Column(
            children: [
              // Filter-Leiste
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    // Suchfeld
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Suche in Notizen, Transkription, Klienten...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    // Klient + Datum Filter in einer Zeile
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _selectedClientId,
                            decoration: const InputDecoration(
                              hintText: 'Alle Klienten',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Alle Klienten'),
                              ),
                              ...clients.map((c) => DropdownMenuItem<String?>(
                                    value: c.id,
                                    child: Text(
                                      c.vollstaendigerName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _selectedClientId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.date_range, size: 18),
                          label: Text(
                            _selectedDateRange != null
                                ? '${DateFormat('dd.MM').format(_selectedDateRange!.start)}–${DateFormat('dd.MM').format(_selectedDateRange!.end)}'
                                : 'Zeitraum',
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () async {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: _selectedDateRange,
                              locale: const Locale('de'),
                            );
                            if (range != null) {
                              setState(() => _selectedDateRange = range);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Ergebnis-Zähler
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${appointments.length} Einträge',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Liste
              Expanded(
                child: appointments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Keine Dokumentationen gefunden',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                            ),
                            if (_searchQuery.isNotEmpty || _selectedClientId != null || _selectedDateRange != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: () => setState(() {
                                    _selectedClientId = null;
                                    _selectedDateRange = null;
                                    _searchQuery = '';
                                    _searchController.clear();
                                  }),
                                  child: const Text('Filter zurücksetzen'),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: appointments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _DokumentationsEintrag(appointment: appointments[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DokumentationsEintrag extends StatelessWidget {
  final Appointment appointment;

  const _DokumentationsEintrag({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, dd. MMMM yyyy', 'de').format(appointment.date);
    final timeStr =
        '${DateFormat('HH:mm').format(appointment.startTime)}–${DateFormat('HH:mm').format(appointment.endTime)} Uhr';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Name + Datum + FLS
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    appointment.clientName.isNotEmpty ? appointment.clientName[0].toUpperCase() : '?',
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
                        appointment.clientName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$dateStr • $timeStr',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (appointment.fachleistungsstunden > 0)
                  Chip(
                    label: Text(
                      '${appointment.fachleistungsstunden.toStringAsFixed(1)} FLS',
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const Divider(),
            // Inhalt direkt sichtbar
            if (appointment.notes.isNotEmpty) ...[
              _SectionLabel(icon: Icons.notes, label: 'Notizen'),
              const SizedBox(height: 4),
              Text(appointment.notes),
              const SizedBox(height: 12),
            ],
            if (appointment.recordedText.isNotEmpty) ...[
              _SectionLabel(icon: Icons.mic, label: 'Transkription'),
              const SizedBox(height: 4),
              Text(
                appointment.recordedText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            if (appointment.icfBereiche.isNotEmpty) ...[
              _SectionLabel(icon: Icons.accessibility_new, label: 'ICF-Bereiche'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: appointment.icfBereiche
                    .map((icf) => Chip(
                          label: Text(icf, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (appointment.selectedTibZiele != null && appointment.selectedTibZiele!.isNotEmpty) ...[
              _SectionLabel(icon: Icons.flag, label: 'TIB-Ziele'),
              const SizedBox(height: 4),
              ...appointment.selectedTibZiele!.map((ziel) {
                final minuten = appointment.tibZielMinuten?[ziel];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(ziel, style: const TextStyle(fontSize: 13))),
                      if (minuten != null)
                        Text(
                          '$minuten min',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
