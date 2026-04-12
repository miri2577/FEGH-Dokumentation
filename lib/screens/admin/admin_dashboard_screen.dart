import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/admin_service.dart';
import '../../services/hidrive_webdav_client.dart';
import '../../services/recovery_service.dart';
import '../../services/matrix_chat_service.dart';
import '../../models/team.dart';
import 'team_management_screen.dart';
import 'recovery_screen.dart';
import 'audit_log_screen.dart';
import 'approval_screen.dart';
import 'performance_test_screen.dart';
import 'employee_invitation_screen.dart';
import 'client_assignment_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, bool>? _healthResults;
  bool _isCheckingHealth = false;
  List<Team> _teams = [];
  bool _isLoadingTeams = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadData() async {
    setState(() => _isLoadingTeams = true);
    try {
      final service = _createAdminService();
      final teams = await service.listTeams();
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoadingTeams = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTeams = false);
    }
  }

  Future<void> _runHealthChecks() async {
    setState(() => _isCheckingHealth = true);
    try {
      final service = _createAdminService();
      final results = await service.runHealthChecks();
      if (mounted) {
        setState(() {
          _healthResults = results;
          _isCheckingHealth = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingHealth = false);
    }
  }

  Future<void> _initializeOrg() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Organisation initialisieren'),
        content: const Text(
          'Die Ordnerstruktur auf HiDrive wird erstellt. '
          'Dies ist nur beim ersten Mal nötig.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Initialisieren'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final service = _createAdminService();
    final success = await service.initializeOrganizationStructure();
    if (!mounted) return;

    if (success) {
      // Recovery-Key generieren
      final recoveryKey = RecoveryService.generateRecoveryKey();

      // Aktuellen MEK abrufen und mit Recovery-Key verschluesseln
      final app = Provider.of<AppProvider>(context, listen: false);
      final mek = await app.secureStorageService.cryptoStorage.getCurrentMek();
      if (mek != null) {
        final encryptedMek = await RecoveryService.encryptMekWithRecoveryKey(
          Uint8List.fromList(mek),
          recoveryKey,
        );
        await app.secureStorageService.cryptoStorage.storeMekBackup(encryptedMek);
      }

      await _showRecoveryKeyDialog(recoveryKey);
      _runHealthChecks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler bei der Initialisierung'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRecoveryKeyDialog(String recoveryKey) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.key, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Recovery-Key'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'WICHTIG: Notieren Sie diesen Key und bewahren Sie ihn sicher auf (ausdrucken, Safe). '
                  'Ohne diesen Key koennen Sie bei Passwortverlust NICHT auf Ihre Daten zugreifen!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: SelectableText(
                  recoveryKey,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                    height: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: recoveryKey));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Recovery-Key kopiert')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Kopieren'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '12 Woerter · Gross-/Kleinschreibung egal · Sicher aufbewahren',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ich habe den Key gesichert'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final settings = app.settings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verwaltung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Daten aktualisieren',
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Org-Info Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.business,
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organisation',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              settings.organizationId.isNotEmpty
                                  ? settings.organizationId
                                  : 'Nicht konfiguriert',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(settings.userRole.name),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Statistiken
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.groups,
                      label: 'Teams',
                      value: _isLoadingTeams ? '...' : '${_teams.length}',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people,
                      label: 'Mitarbeiter',
                      value: '${app.mitarbeiter.length}',
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.person,
                      label: 'Klienten',
                      value: '${app.totalClients}',
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Aktionen',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(
                    icon: Icons.group_add,
                    label: 'Team erstellen',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeamManagementScreen(),
                        ),
                      );
                      _loadData();
                    },
                  ),
                  _ActionChip(
                    icon: Icons.person_add,
                    label: 'Mitarbeiter einladen',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmployeeInvitationScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionChip(
                    icon: Icons.assignment_ind,
                    label: 'Klient zuweisen',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientAssignmentScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionChip(
                    icon: Icons.create_new_folder,
                    label: 'Org initialisieren',
                    onTap: _initializeOrg,
                  ),
                  _ActionChip(
                    icon: Icons.chat,
                    label: 'Chat-User anlegen',
                    onTap: _createMatrixUser,
                  ),
                  _ActionChip(
                    icon: Icons.lock_reset,
                    label: 'Passwort-Recovery',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecoveryScreen()),
                      );
                    },
                  ),
                  _ActionChip(
                    icon: Icons.approval,
                    label: 'Genehmigungen',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ApprovalScreen()),
                      );
                    },
                  ),
                  _ActionChip(
                    icon: Icons.history,
                    label: 'Audit-Log',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuditLogScreen()),
                      );
                    },
                  ),
                  if (kDebugMode)
                    _ActionChip(
                      icon: Icons.speed,
                      label: 'Performance-Test',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PerformanceTestScreen()),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Health Checks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'System-Status',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _isCheckingHealth ? null : _runHealthChecks,
                    icon: _isCheckingHealth
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.health_and_safety, size: 18),
                    label: const Text('Pruefen'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_healthResults != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: _healthResults!.entries.map((e) {
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            e.value ? Icons.check_circle : Icons.error,
                            color: e.value ? Colors.green : Colors.red,
                          ),
                          title: Text(_healthCheckLabel(e.key)),
                        );
                      }).toList(),
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Health Check noch nicht ausgefuehrt',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Teams-Liste
              Text(
                'Teams',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isLoadingTeams)
                const Center(child: CircularProgressIndicator())
              else if (_teams.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.groups_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          const Text('Noch keine Teams angelegt'),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TeamManagementScreen(),
                                ),
                              );
                              _loadData();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Erstes Team erstellen'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...(_teams.map((team) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: team.isActive
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.groups,
                              color: team.isActive
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant),
                        ),
                        title: Text(team.name),
                        subtitle: Text(
                          '${team.memberCount} Mitarbeiter · ${team.clientCount} Klienten · ${team.statusDisplayName}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TeamManagementScreen(),
                            ),
                          );
                          _loadData();
                        },
                      ),
                    ))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createMatrixUser() async {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chat-User anlegen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Erstellt einen neuen User auf dem Matrix-Server.'),
            const SizedBox(height: 16),
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Benutzername',
                hintText: 'z.B. max.mustermann',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(
                labelText: 'Passwort',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Anlegen')),
        ],
      ),
    );
    if (result != true || usernameCtrl.text.trim().isEmpty || passwordCtrl.text.isEmpty) return;
    if (!mounted) return;

    final data = await MatrixChatService.createUserOnServer(
      username: usernameCtrl.text.trim(),
      password: passwordCtrl.text,
    );
    if (!mounted) return;
    if (data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat-User @${usernameCtrl.text.trim()} erstellt'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler: User konnte nicht erstellt werden (evtl. existiert er bereits)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _healthCheckLabel(String key) {
    switch (key) {
      case 'connection':
        return 'HiDrive-Verbindung';
      case 'adminFolder':
        return 'Administration-Ordner';
      case 'teamsFolder':
        return 'Teams-Ordner';
      case 'rolesPolicy':
        return 'Rollen-Konfiguration';
      case 'writeAccess':
        return 'Schreibzugriff';
      default:
        return key;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
