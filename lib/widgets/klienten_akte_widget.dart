import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/appointment.dart';

class KlientenAkteWidget extends StatefulWidget {
  final String clientId;
  final String clientName;

  const KlientenAkteWidget({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<KlientenAkteWidget> createState() => _KlientenAkteWidgetState();
}

class _KlientenAkteWidgetState extends State<KlientenAkteWidget> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final appointments = appProvider.appointments
            .where((a) => a.clientId == widget.clientId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        final filtered = _searchQuery.isEmpty
            ? appointments
            : appointments.where((a) {
                final query = _searchQuery.toLowerCase();
                return a.notes.toLowerCase().contains(query) ||
                    a.recordedText.toLowerCase().contains(query) ||
                    a.clientName.toLowerCase().contains(query);
              }).toList();

        return Column(
          children: [
            // Suchleiste
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'In Dokumentation suchen...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.folder_open, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dokumentation: ${widget.clientName}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${filtered.length} Eintraege',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Eintraege
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Keine Dokumentation vorhanden'
                            : 'Keine Treffer fuer "$_searchQuery"',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final appointment = filtered[index];
                        return _buildDokuEintrag(context, appointment);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDokuEintrag(BuildContext context, Appointment appointment) {
    final volltext = _buildVolltext(appointment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Datum und Zeit Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatDate(appointment.date),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            // Kopieren-Button
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Text kopieren',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: volltext));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Text in Zwischenablage kopiert'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Notizen
        if (appointment.notes.isNotEmpty) ...[
          SelectableText(
            appointment.notes,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
        ],

        // Sprachaufzeichnung
        if (appointment.recordedText.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mic, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Sprachaufzeichnung:',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  appointment.recordedText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ICF-Bereiche
        if (appointment.icfBereiche.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: appointment.icfBereiche.map((bereich) {
              return Chip(
                label: Text(bereich, style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
      ],
    );
  }

  String _buildVolltext(Appointment appointment) {
    final buffer = StringBuffer();
    buffer.writeln('Datum: ${_formatDate(appointment.date)}');
    buffer.writeln('Zeit: ${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}');
    buffer.writeln();
    if (appointment.notes.isNotEmpty) {
      buffer.writeln(appointment.notes);
      buffer.writeln();
    }
    if (appointment.recordedText.isNotEmpty) {
      buffer.writeln('Sprachaufzeichnung:');
      buffer.writeln(appointment.recordedText);
    }
    return buffer.toString().trim();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
