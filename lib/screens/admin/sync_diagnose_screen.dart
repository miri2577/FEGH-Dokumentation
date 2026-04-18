import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/team.dart';
import '../../providers/app_provider.dart';
import '../../services/admin_service.dart';
import '../../services/hidrive_webdav_client.dart';

/// Diagnose-Screen fuer den Cross-App-Sync-Status.
///
/// Zeigt:
///   - HiDrive-Config und Verbindungs-Test
///   - MEK-Quelle (Keychain / Passphrase / Team-Key)
///   - Teams: lokal vs. HiDrive, mit Hinweis wo jedes Team existiert
///   - Re-Sync-Button pro Team
class SyncDiagnoseScreen extends StatefulWidget {
  const SyncDiagnoseScreen({super.key});

  @override
  State<SyncDiagnoseScreen> createState() => _SyncDiagnoseScreenState();
}

class _SyncDiagnoseScreenState extends State<SyncDiagnoseScreen> {
  bool _isLoading = false;
  String? _hidriveStatus;
  bool _hidriveOk = false;
  List<Team> _localTeams = [];
  List<Team>? _cloudTeams; // null = HiDrive nicht konfiguriert/erreichbar

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDiagnose());
  }

  AdminService _createAdminService() {
    final app = Provider.of<AppProvider>(context, listen: false);
    final settings = app.settings;
    final adminSync = HiDriveBusinessSync.forAdmin(
      username: settings.hidriveUsername,
      password: settings.hidrivePassword,
      organizationId: settings.organizationId,
      rootSubdirectory: settings.rootSubdirectory.isNotEmpty
          ? settings.rootSubdirectory
          : null,
    );
    return AdminService(
      crypto: app.secureStorageService.cryptoStorage,
      adminSync: adminSync,
      settings: settings,
    );
  }

  Future<void> _runDiagnose() async {
    setState(() => _isLoading = true);
    final app = Provider.of<AppProvider>(context, listen: false);
    final settings = app.settings;

    // 1. HiDrive-Test
    if (settings.hidriveUsername.isEmpty) {
      _hidriveStatus = 'HiDrive nicht konfiguriert (reiner Lokal-Modus)';
      _hidriveOk = false;
    } else {
      try {
        final client = HiDriveWebDAVClient(
          baseUrl: HiDriveConfig.buildWebDAVUrl(settings.hidriveUsername),
          username: settings.hidriveUsername,
          password: settings.hidrivePassword,
          certificatePins: HiDriveConfig.certificatePins,
        );
        final test = await client.testConnection();
        _hidriveOk = test.isSuccess;
        _hidriveStatus = test.isSuccess
            ? 'HiDrive verbunden (${settings.hidriveUsername})'
            : 'HiDrive Fehler: ${test.error}';
      } catch (e) {
        _hidriveOk = false;
        _hidriveStatus = 'HiDrive-Ausnahme: $e';
      }
    }

    // 2. Teams lokal + cloud
    final svc = _createAdminService();
    _localTeams = await svc.listTeamsLocal();
    _cloudTeams = _hidriveOk ? (await svc.listTeamsCloud() ?? []) : null;

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final s = app.settings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync-Diagnose'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Neu pruefen',
            onPressed: _isLoading ? null : _runDiagnose,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfigCard(theme, s),
                  const SizedBox(height: 16),
                  _buildHidriveCard(theme),
                  const SizedBox(height: 16),
                  _buildTeamsDiffCard(theme),
                  const SizedBox(height: 16),
                  _buildTipsCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildConfigCard(ThemeData theme, dynamic settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konfiguration dieser Instanz',
                style: theme.textTheme.titleMedium),
            const Divider(),
            _kv('Organisation', settings.organizationId),
            _kv('Team-ID (aktiv)', settings.teamId),
            _kv('User-Name', settings.userName),
            _kv('Rolle', settings.userRole?.toString() ?? 'unbekannt'),
            _kv('HiDrive-User', settings.hidriveUsername.isEmpty
                ? '(leer → Lokal-Modus)'
                : settings.hidriveUsername),
            _kv('Root-Unterordner', settings.rootSubdirectory.isEmpty
                ? '(leer)'
                : settings.rootSubdirectory),
            _kv('Sync-Passphrase', settings.syncPassphrase.isEmpty
                ? '(leer - MEK pro Geraet zufaellig!)'
                : '(${settings.syncPassphrase.length} Zeichen gesetzt)'),
          ],
        ),
      ),
    );
  }

  Widget _buildHidriveCard(ThemeData theme) {
    final color = _hidriveOk ? Colors.green : Colors.orange;
    final icon = _hidriveOk ? Icons.cloud_done : Icons.cloud_off;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HiDrive-Verbindung', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(_hidriveStatus ?? '-',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsDiffCard(ThemeData theme) {
    final localIds = _localTeams.map((t) => t.id).toSet();
    final cloudIds = _cloudTeams?.map((t) => t.id).toSet() ?? const <String>{};
    final onlyLocal = _localTeams.where((t) => !cloudIds.contains(t.id)).toList();
    final onlyCloud =
        _cloudTeams?.where((t) => !localIds.contains(t.id)).toList() ?? const [];
    final both = _localTeams.where((t) => cloudIds.contains(t.id)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Teams: ${_localTeams.length} lokal / '
                    '${_cloudTeams == null ? "keine Cloud" : "${_cloudTeams!.length} in Cloud"}',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (both.isNotEmpty) ...[
              Text('Synchron (lokal + Cloud):',
                  style: theme.textTheme.titleSmall),
              ...both.map((t) => _teamRow(t, Icons.check_circle, Colors.green,
                  'Beide Seiten')),
              const SizedBox(height: 12),
            ],
            if (onlyLocal.isNotEmpty) ...[
              Text('Nur lokal vorhanden:',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.orange)),
              ...onlyLocal.map((t) => _teamRow(t, Icons.cloud_upload,
                  Colors.orange, 'Noch nicht hochgeladen', canUpload: true)),
              const SizedBox(height: 12),
            ],
            if (onlyCloud.isNotEmpty) ...[
              Text('Nur in Cloud (nicht lokal):',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.blue)),
              ...onlyCloud.map((t) => _teamRow(t, Icons.cloud_download,
                  Colors.blue, 'Noch nicht lokal geladen')),
              const SizedBox(height: 12),
            ],
            if (_localTeams.isEmpty &&
                (_cloudTeams == null || _cloudTeams!.isEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Keine Teams vorhanden.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _teamRow(Team team, IconData icon, Color color, String status,
      {bool canUpload = false}) {
    final df = DateFormat('dd.MM.yyyy HH:mm');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  'ID: ${team.id} · updatedAt: ${df.format(team.updatedAt)} · $status',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (canUpload)
            TextButton.icon(
              onPressed: () => _uploadTeam(team),
              icon: const Icon(Icons.upload, size: 16),
              label: const Text('Upload'),
            ),
        ],
      ),
    );
  }

  Future<void> _uploadTeam(Team team) async {
    final svc = _createAdminService();
    final ok = await svc.updateTeam(team);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Team "${team.name}" hochgeladen'
            : 'Upload fehlgeschlagen'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    await _runDiagnose();
  }

  Widget _buildTipsCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text('Tipps fuer Cross-App-Sync',
                    style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Damit die Verwaltungs-App dieselben Teams sieht:\n\n'
              '1. Beide Apps mit gleichem HiDrive-Account + Org-ID konfigurieren\n'
              '2. In beiden Apps die gleiche Sync-Passphrase setzen '
              '(Einstellungen > Cloud-Sync > Sync-Passphrase)\n'
              '3. Ohne Sync-Passphrase nutzt jede Installation einen eigenen '
              'zufaelligen MEK -> Cloud-Daten nicht lesbar',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, dynamic v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 140,
                child: Text('$k:',
                    style: const TextStyle(fontWeight: FontWeight.w500))),
            Expanded(
              child: SelectableText(v?.toString() ?? '',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
      );
}
