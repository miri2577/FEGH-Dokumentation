import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shift.dart';
import '../services/shift_reader_service.dart';

/// Read-only-Ansicht der kommenden eigenen Schichten fuer die
/// Mitarbeiter:in. Daten werden aus dem gemeinsamen `shifts.json`
/// gelesen, das die Verwaltung pflegt.
class MyShiftsScreen extends StatefulWidget {
  final String employeeId;
  final String? employeeName;

  const MyShiftsScreen({
    super.key,
    required this.employeeId,
    this.employeeName,
  });

  @override
  State<MyShiftsScreen> createState() => _MyShiftsScreenState();
}

class _MyShiftsScreenState extends State<MyShiftsScreen> {
  final _service = ShiftReaderService();
  late Future<List<Shift>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadForEmployee(widget.employeeId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.loadForEmployee(widget.employeeId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEEE, dd.MM.yyyy', 'de_DE');
    final tf = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeName != null
            ? 'Meine Schichten – ${widget.employeeName}'
            : 'Meine Schichten'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Shift>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final shifts = snap.data ?? const [];
            if (shifts.isEmpty) {
              return _empty(context);
            }
            final now = DateTime.now();
            final upcoming = shifts
                .where((s) =>
                    s.endTime.isAfter(now) &&
                    s.status != ShiftStatus.cancelled)
                .toList();
            final past = shifts
                .where((s) => s.endTime.isBefore(now))
                .toList()
              ..sort((a, b) => b.startTime.compareTo(a.startTime));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Kommende Schichten (${upcoming.length})',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (upcoming.isEmpty)
                  Text('Aktuell keine kommenden Schichten.',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ...upcoming.map((s) => _shiftCard(context, s, df, tf)),
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Letzte Schichten',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...past.take(5).map((s) => _shiftCard(context, s, df, tf)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.event_note,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        const Text('Keine Schichten hinterlegt.',
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Schichten werden von der Verwaltung eingetragen und bei der '
          'naechsten Synchronisation geladen.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _shiftCard(
      BuildContext context, Shift s, DateFormat df, DateFormat tf) {
    final theme = Theme.of(context);
    final color = _statusColor(theme, s.status);
    return Card(
      child: ListTile(
        leading: Container(
          width: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(df.format(s.startTime)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${tf.format(s.startTime)} – ${tf.format(s.endTime)} '
                '(${s.scheduledHours.toStringAsFixed(1)} h)'),
            if (s.location != null && s.location!.isNotEmpty)
              Text(s.location!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
        trailing: Text(s.status.displayName,
            style: TextStyle(color: color, fontSize: 12)),
      ),
    );
  }

  Color _statusColor(ThemeData theme, ShiftStatus status) {
    switch (status) {
      case ShiftStatus.scheduled:
        return theme.colorScheme.primary;
      case ShiftStatus.inProgress:
        return Colors.orange;
      case ShiftStatus.completed:
        return Colors.green;
      case ShiftStatus.cancelled:
      case ShiftStatus.noShow:
        return theme.colorScheme.error;
    }
  }
}
