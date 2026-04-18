import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../providers/app_provider.dart';
import '../../services/backup_service.dart';

/// Performance-Test mit 3 Szenarien (50, 250, 500 Klienten).
/// Misst alle wichtigen Operationen und erstellt eine Vergleichstabelle.
class PerformanceTestScreen extends StatefulWidget {
  const PerformanceTestScreen({super.key});

  @override
  State<PerformanceTestScreen> createState() => _PerformanceTestScreenState();
}

class _PerformanceTestScreenState extends State<PerformanceTestScreen> {
  final List<int> _scenarios = [50, 250, 500];
  final Map<int, Map<String, int>> _results = {}; // {clientCount: {operation: ms}}
  bool _isRunning = false;
  String _currentStep = '';
  int _currentScenario = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance-Test'),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Als Markdown kopieren',
              onPressed: _copyAsMarkdown,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WARNUNG: Dieser Test loescht alle bestehenden Daten und erstellt Test-Daten. '
                      'Nur in Test-Umgebung ausfuehren!',
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Szenarien: ${_scenarios.join(", ")} Klienten',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Gemessen werden: Erstellen, Verschluesseln, Entschluesseln, Speichern, Laden, '
              'Suchen, Backup-Erstellen, Backup-Restore, Statistiken berechnen, Loeschen.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isRunning ? null : _runAllScenarios,
                icon: _isRunning
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow),
                label: Text(_isRunning ? 'Laeuft...' : 'Test starten'),
              ),
            ),
            if (_isRunning) ...[
              const SizedBox(height: 16),
              Text('Szenario $_currentScenario/${_scenarios.length}',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(_currentStep, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 24),
            if (_results.isNotEmpty) Expanded(child: _buildResultsTable(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsTable(ThemeData theme) {
    // Alle Operationen aus allen Szenarien sammeln (Reihenfolge beibehalten)
    final operations = <String>[];
    for (final scenarioResults in _results.values) {
      for (final op in scenarioResults.keys) {
        if (!operations.contains(op)) operations.add(op);
      }
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ergebnisse',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Operation')),
                ..._scenarios.map((s) => DataColumn(label: Text('$s Klienten'))),
              ],
              rows: operations.map((op) {
                return DataRow(cells: [
                  DataCell(Text(op, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ..._scenarios.map((s) {
                    final ms = _results[s]?[op] ?? 0;
                    return DataCell(Text('$ms ms'));
                  }),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runAllScenarios() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('Alle Daten loeschen?'),
        content: const Text(
          'Der Test loescht alle bestehenden Klienten und erstellt Test-Daten. '
          'Erstellen Sie vorher ein Backup wenn Sie produktive Daten haben!\n\n'
          'Fortfahren?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Starten'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isRunning = true;
      _results.clear();
      _currentScenario = 0;
    });

    try {
      for (final count in _scenarios) {
        setState(() => _currentScenario++);
        final results = await _runScenario(count);
        setState(() => _results[count] = results);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performance-Test abgeschlossen'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  Future<Map<String, int>> _runScenario(int clientCount) async {
    final results = <String, int>{};
    final app = Provider.of<AppProvider>(context, listen: false);
    final crypto = app.secureStorageService.cryptoStorage;
    final stopwatch = Stopwatch();

    setState(() => _currentStep = 'Bereinige vorherige Daten...');
    final existing = List<Client>.from(app.clients);
    for (final c in existing) {
      await app.deleteClient(c.id);
    }

    // Test-Daten generieren (in-memory)
    final clients = _generateClients(clientCount);

    // 1. Verschluesselung Single (Mikro-Benchmark, mehrfach gemessen)
    setState(() => _currentStep = 'Verschluesselung-Benchmark...');
    final testData = utf8.encode(jsonEncode(clients[0].toJson()));
    stopwatch.reset();
    stopwatch.start();
    Map<String, dynamic>? encrypted;
    for (int i = 0; i < 100; i++) {
      encrypted = await crypto.encryptRecord(plaintext: testData);
    }
    stopwatch.stop();
    results['Verschluesseln (100x 1 Datensatz)'] = stopwatch.elapsedMilliseconds;

    // 2. Entschluesselung Single
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 100; i++) {
      await crypto.decryptRecord(encrypted!);
    }
    stopwatch.stop();
    results['Entschluesseln (100x 1 Datensatz)'] = stopwatch.elapsedMilliseconds;

    // 3. Verschluesselung Bulk (alle Klienten)
    setState(() => _currentStep = 'Bulk-Verschluesselung...');
    stopwatch.reset();
    stopwatch.start();
    for (final c in clients) {
      await crypto.encryptRecord(plaintext: utf8.encode(jsonEncode(c.toJson())));
    }
    stopwatch.stop();
    results['Bulk-Verschluesseln (alle Klienten)'] = stopwatch.elapsedMilliseconds;

    // 4. Klienten erstellen (mit Cloud-Sync)
    setState(() => _currentStep = 'Erstelle $clientCount Klienten...');
    stopwatch.reset();
    stopwatch.start();
    for (final c in clients) {
      await app.addClient(c);
    }
    stopwatch.stop();
    results['Erstellen (alle Klienten + Cloud-Sync)'] = stopwatch.elapsedMilliseconds;

    // 5. Klienten laden
    setState(() => _currentStep = 'Lade Klienten...');
    stopwatch.reset();
    stopwatch.start();
    await app.refreshData();
    stopwatch.stop();
    results['Laden (alle Klienten)'] = stopwatch.elapsedMilliseconds;

    // 6. Suche
    setState(() => _currentStep = 'Suche-Benchmark...');
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 1000; i++) {
      app.clients.where((c) => c.name.contains('Mueller')).toList();
    }
    stopwatch.stop();
    results['Suche (1000x)'] = stopwatch.elapsedMilliseconds;

    // 7. Statistiken berechnen
    setState(() => _currentStep = 'Statistiken-Benchmark...');
    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 1000; i++) {
      app.clientsInRedZone;
      app.clientsInYellowZone;
      app.clientsInGreenZone;
    }
    stopwatch.stop();
    results['Statistiken (1000x)'] = stopwatch.elapsedMilliseconds;

    // 8. Backup erstellen
    setState(() => _currentStep = 'Erstelle Backup...');
    stopwatch.reset();
    stopwatch.start();
    final backupService = BackupService();
    await backupService.createBackup(
      clients: app.clients,
      appointments: app.appointments,
      emailTargets: app.emailTargets,
      settings: app.settings,
      password: 'test',
    );
    stopwatch.stop();
    results['Backup (verschluesselt)'] = stopwatch.elapsedMilliseconds;

    // 9. Update aller Klienten
    setState(() => _currentStep = 'Aktualisiere alle Klienten...');
    stopwatch.reset();
    stopwatch.start();
    for (final c in app.clients) {
      final updated = c.copyWith(verbrauchteStunden: 5.0);
      await app.updateClient(updated);
    }
    stopwatch.stop();
    results['Update (alle Klienten + Cloud-Sync)'] = stopwatch.elapsedMilliseconds;

    // 10. Klienten loeschen
    setState(() => _currentStep = 'Loesche Klienten...');
    stopwatch.reset();
    stopwatch.start();
    final toDelete = List<Client>.from(app.clients);
    for (final c in toDelete) {
      await app.deleteClient(c.id);
    }
    stopwatch.stop();
    results['Loeschen (alle + Cloud-Sync)'] = stopwatch.elapsedMilliseconds;

    return results;
  }

  List<Client> _generateClients(int count) {
    final random = Random(42); // Fester Seed fuer Reproduzierbarkeit
    final clients = <Client>[];
    final firstNames = ['Max', 'Anna', 'Thomas', 'Sarah', 'Michael', 'Julia', 'Stefan', 'Lisa'];
    final lastNames = ['Mueller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner', 'Becker'];

    for (int i = 0; i < count; i++) {
      final first = firstNames[random.nextInt(firstNames.length)];
      final last = lastNames[random.nextInt(lastNames.length)];
      clients.add(Client.create(
        name: '$first $last $i',
        vorname: first,
        nachname: '$last $i',
        klientenId: 'TEST-${1000 + i}',
        geburtsdatum: DateTime(1980 + random.nextInt(40), random.nextInt(12) + 1, random.nextInt(28) + 1),
        betreuungSeit: DateTime(2020 + random.nextInt(5), random.nextInt(12) + 1, random.nextInt(28) + 1),
        fachleistungsstunden: 50 + random.nextInt(150),
        fachleistungsIntervall: FachleistungsIntervall.monatlich,
        verbrauchteStunden: random.nextDouble() * 100,
      ));
    }
    return clients;
  }

  void _copyAsMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Performance-Test Ergebnisse');
    buffer.writeln();
    buffer.writeln('Datum: ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln();
    buffer.writeln('| Operation | ${_scenarios.map((s) => "$s Klienten").join(" | ")} |');
    buffer.writeln('|-----------|${_scenarios.map((_) => "---").join("|")}|');

    final operations = <String>[];
    for (final scenarioResults in _results.values) {
      for (final op in scenarioResults.keys) {
        if (!operations.contains(op)) operations.add(op);
      }
    }
    for (final op in operations) {
      buffer.write('| $op |');
      for (final s in _scenarios) {
        buffer.write(' ${_results[s]?[op] ?? 0} ms |');
      }
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Markdown-Tabelle in Zwischenablage kopiert')),
    );
  }
}
