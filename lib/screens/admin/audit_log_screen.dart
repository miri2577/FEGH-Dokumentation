import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/audit_logger.dart';

/// Zeigt das Audit-Log mit Filter- und Exportfunktion an.
/// Wichtig fuer DSGVO-Pruefungen (Art. 5 Abs. 2 Rechenschaftspflicht).
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _filterAction = 'alle';
  String _filterUser = '';
  DateTime? _filterFrom;
  DateTime? _filterTo;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await AuditLogger.instance.getLastEntries(count: 1000);
    if (mounted) {
      setState(() {
        _entries = entries.reversed.toList(); // Neueste zuerst
        _isLoading = false;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    _filtered = _entries.where((e) {
      // Aktion-Filter
      if (_filterAction != 'alle') {
        final action = e['action'] as String? ?? '';
        if (!action.startsWith(_filterAction)) return false;
      }
      // User-Filter
      if (_filterUser.isNotEmpty) {
        final userId = e['userId'] as String? ?? '';
        if (!userId.toLowerCase().contains(_filterUser.toLowerCase())) return false;
      }
      // Datum-Filter
      try {
        final ts = DateTime.parse(e['ts']);
        if (_filterFrom != null && ts.isBefore(_filterFrom!)) return false;
        if (_filterTo != null && ts.isAfter(_filterTo!.add(const Duration(days: 1)))) return false;
      } catch (_) {}
      return true;
    }).toList();
    setState(() {});
  }

  Future<void> _rotateLog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Audit-Log rotieren'),
        content: const Text(
          'Eintraege aelter als 3 Jahre werden geloescht. '
          'Diese Aktion kann nicht rueckgaengig gemacht werden.\n\n'
          'Fortfahren?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rotieren')),
        ],
      ),
    );
    if (confirm == true) {
      await AuditLogger.instance.rotate();
      await _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit-Log rotiert')),
        );
      }
    }
  }

  void _exportToClipboard() {
    final lines = _filtered.map((e) => jsonEncode(e)).join('\n');
    Clipboard.setData(ClipboardData(text: lines));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_filtered.length} Eintraege in Zwischenablage kopiert')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit-Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
            onPressed: _loadEntries,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Gefilterte exportieren',
            onPressed: _filtered.isNotEmpty ? _exportToClipboard : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Alte Eintraege loeschen (>3 Jahre)',
            onPressed: _rotateLog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter-Bereich
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterAction,
                        decoration: const InputDecoration(
                          labelText: 'Aktion',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'alle', child: Text('Alle Aktionen')),
                          DropdownMenuItem(value: 'auth', child: Text('Authentifizierung')),
                          DropdownMenuItem(value: 'client', child: Text('Klienten')),
                          DropdownMenuItem(value: 'team', child: Text('Teams')),
                          DropdownMenuItem(value: 'user', child: Text('Benutzer')),
                          DropdownMenuItem(value: 'role', child: Text('Rollen')),
                          DropdownMenuItem(value: 'data', child: Text('Datenexport/-loeschung')),
                          DropdownMenuItem(value: 'recovery', child: Text('Recovery')),
                          DropdownMenuItem(value: 'gdpr', child: Text('DSGVO-Operationen')),
                        ],
                        onChanged: (v) {
                          setState(() => _filterAction = v ?? 'alle');
                          _applyFilter();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Benutzer',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          setState(() => _filterUser = v);
                          _applyFilter();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _filterFrom ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _filterFrom = picked);
                            _applyFilter();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(_filterFrom == null
                            ? 'Von'
                            : '${_filterFrom!.day}.${_filterFrom!.month}.${_filterFrom!.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _filterTo ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _filterTo = picked);
                            _applyFilter();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(_filterTo == null
                            ? 'Bis'
                            : '${_filterTo!.day}.${_filterTo!.month}.${_filterTo!.year}'),
                      ),
                    ),
                    if (_filterFrom != null || _filterTo != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _filterFrom = null;
                            _filterTo = null;
                          });
                          _applyFilter();
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${_filtered.length} von ${_entries.length} Eintraegen',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text('Keine Eintraege gefunden',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final entry = _filtered[index];
                          return _buildEntryTile(theme, entry);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(ThemeData theme, Map<String, dynamic> entry) {
    final action = entry['action'] as String? ?? '?';
    final userId = entry['userId'] as String? ?? '?';
    final ts = entry['ts'] as String? ?? '';
    final ctx = entry['ctx'] as Map<String, dynamic>?;

    DateTime? dt;
    try { dt = DateTime.parse(ts); } catch (_) {}
    final timeStr = dt != null
        ? '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}'
        : ts;

    final color = _colorForAction(action);
    final icon = _iconForAction(action);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(action, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Benutzer: $userId', style: theme.textTheme.bodySmall),
            Text(timeStr, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (ctx != null && ctx.isNotEmpty)
              Text(jsonEncode(ctx),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, fontFamily: 'monospace')),
          ],
        ),
        dense: true,
      ),
    );
  }

  Color _colorForAction(String action) {
    if (action.startsWith('auth.login_failed')) return Colors.red;
    if (action.startsWith('auth')) return Colors.blue;
    if (action.startsWith('client.delete') || action.startsWith('gdpr')) return Colors.red;
    if (action.startsWith('client')) return Colors.green;
    if (action.startsWith('team')) return Colors.purple;
    if (action.startsWith('role')) return Colors.orange;
    if (action.startsWith('data.delete')) return Colors.red;
    if (action.startsWith('data')) return Colors.teal;
    if (action.startsWith('recovery')) return Colors.amber;
    return Colors.grey;
  }

  IconData _iconForAction(String action) {
    if (action.startsWith('auth.login_failed')) return Icons.error;
    if (action.startsWith('auth.login')) return Icons.login;
    if (action.startsWith('auth.logout')) return Icons.logout;
    if (action.startsWith('client.create')) return Icons.person_add;
    if (action.startsWith('client.delete') || action.startsWith('gdpr')) return Icons.delete_forever;
    if (action.startsWith('client.update')) return Icons.edit;
    if (action.startsWith('client.access')) return Icons.visibility;
    if (action.startsWith('team')) return Icons.groups;
    if (action.startsWith('user.invite')) return Icons.mail;
    if (action.startsWith('role')) return Icons.security;
    if (action.startsWith('data.export')) return Icons.download;
    if (action.startsWith('data.delete')) return Icons.delete_sweep;
    if (action.startsWith('recovery')) return Icons.lock_reset;
    return Icons.info;
  }
}
