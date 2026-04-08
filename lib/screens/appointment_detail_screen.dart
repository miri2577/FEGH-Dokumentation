import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../models/icf_bereiche.dart';
import '../models/familienhilfe_kategorien.dart';
import '../utils/responsive_utils.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokumentation Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _exportDocumentation(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final client = appProvider.getClientById(appointment.clientId);
          return SingleChildScrollView(
            padding: ResponsiveUtils.getScreenPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(context, client),
                const SizedBox(height: 24),
                _buildBasicInfoSection(context),
                const SizedBox(height: 24),
                _buildDocumentationSection(context),
                const SizedBox(height: 24),
                _buildICFSection(context),
                const SizedBox(height: 24),
                _buildTIBSection(context),
                const SizedBox(height: 24),
                _buildFamilienhilfeSection(context),
                const SizedBox(height: 24),
                _buildRecordingSection(context),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, Client? client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    appointment.clientName.isNotEmpty
                        ? appointment.clientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.clientName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${appointment.berufsgruppe} • ${appointment.eingliederung}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${appointment.fachleistungsstunden.toStringAsFixed(1)} Fachleistungsstunden',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termindetails',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Datum',
              '${appointment.date.day}.${appointment.date.month}.${appointment.date.year}',
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Uhrzeit',
              '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}',
              Icons.schedule,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Dauer',
              '${_calculateDuration()} Min',
              Icons.timer,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Erstellt',
              '${appointment.createdAt.day}.${appointment.createdAt.month}.${appointment.createdAt.year}',
              Icons.edit_calendar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentationSection(BuildContext context) {
    if (appointment.notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dokumentation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                appointment.notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildICFSection(BuildContext context) {
    if (appointment.icfBereiche.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ICF-Bereiche',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...appointment.icfBereiche.map((bereichId) {
              final bereich = ICFBereiche.getById(bereichId);
              if (bereich == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bereich.titel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bereich.beschreibung,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTIBSection(BuildContext context) {
    if (appointment.tibBereiche.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TIB-Bereiche (Teilhabeinstrument Berlin)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...appointment.tibBereiche.map((bereich) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bereich,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTIBBeschreibung(bereich),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilienhilfeSection(BuildContext context) {
    if (appointment.familienhilfeKategorien.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Familienhilfe-Kategorien',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...appointment.familienhilfeKategorien.map((kategorieId) {
              final kategorie = FamilienhilfeKategorien.getById(kategorieId);
              if (kategorie == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha:0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFamilienhilfeIcon(kategorie.icon),
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kategorie.titel,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            kategorie.beschreibung,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection(BuildContext context) {
    if (appointment.recordedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sprachaufzeichnung',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                appointment.recordedText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _calculateDuration() {
    return appointment.endTime.difference(appointment.startTime).inMinutes;
  }

  String _getTIBBeschreibung(String bereich) {
    switch (bereich) {
      case 'Lernen und Wissensanwendung':
        return 'Aufmerksamkeit, Gedächtnis, Problemlösung';
      case 'Allgemeine Aufgaben und Anforderungen':
        return 'Tagesroutine, Umgang mit Stress und Anforderungen';
      case 'Kommunikation':
        return 'Verstehen und Produzieren von Sprache';
      case 'Mobilität':
        return 'Fortbewegung und Körperhaltung';
      case 'Selbstversorgung':
        return 'Körperpflege, An- und Ausziehen, Essen';
      case 'Häusliches Leben':
        return 'Haushaltsführung, Wohnen, Alltag';
      case 'Interpersonelle Interaktionen und Beziehungen':
        return 'Soziale Kontakte und Beziehungen';
      case 'Bedeutende Lebensbereiche':
        return 'Bildung, Arbeit, Wirtschaftsleben';
      case 'Gemeinschafts-, soziales und staatsbürgerliches Leben':
        return 'Gemeinschaftsleben, Erholung, Religion, Politik';
      default:
        return 'TIB-Zielbereich';
    }
  }

  IconData _getFamilienhilfeIcon(String iconName) {
    switch (iconName) {
      case 'family_care':
        return Icons.family_restroom;
      case 'child_development':
        return Icons.child_care;
      case 'educational_support':
        return Icons.school;
      case 'household_management':
        return Icons.home;
      case 'crisis_intervention':
        return Icons.emergency;
      case 'network_building':
        return Icons.group;
      case 'administrative_support':
        return Icons.description;
      case 'resource_development':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }

  void _exportDocumentation(BuildContext context) {
    // TODO: Implementiere Export-Funktionalität (PDF, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export-Funktionalität wird in einer zukünftigen Version verfügbar sein'),
      ),
    );
  }
}