import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team.dart';
import '../../providers/app_provider.dart';
import '../../services/admin_service.dart';
import '../../services/hidrive_webdav_client.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  List<Team> _teams = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadTeams();
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

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final service = _createAdminService();
      final teams = await service.listTeams();
      if (mounted) setState(() { _teams = teams; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateTeamDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neues Team erstellen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Team-Name *',
                  hintText: 'z.B. Team Nord',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Standort',
                  hintText: 'z.B. Berlin-Mitte',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );

    if (result != true || nameController.text.trim().isEmpty) return;

    setState(() => _isCreating = true);
    try {
      final team = Team.create(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        location: locationController.text.trim().isNotEmpty
            ? locationController.text.trim()
            : null,
      );
      final service = _createAdminService();
      final success = await service.createTeam(team);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Team "${team.name}" erstellt'
              : 'Fehler beim Erstellen - pruefe HiDrive-Verbindung + Logs'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      if (success) _loadTeams();
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team-Verwaltung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeams,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _showCreateTeamDialog,
        icon: _isCreating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add),
        label: Text(_isCreating ? 'Erstelle...' : 'Neues Team'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Teams',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Erstelle ein Team, um Mitarbeiter und Klienten zuzuordnen.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTeams,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      final team = _teams[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: team.isActive
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.groups,
                                color: team.isActive
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant),
                          ),
                          title: Text(
                            team.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${team.memberCount} Mitarbeiter · ${team.clientCount} Klienten',
                          ),
                          trailing: Chip(
                            label: Text(team.statusDisplayName),
                            backgroundColor: team.isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (team.description.isNotEmpty) ...[
                                    Text(team.description),
                                    const SizedBox(height: 8),
                                  ],
                                  if (team.location != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 16),
                                        const SizedBox(width: 4),
                                        Text(team.location!),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ID: ${team.id}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    'Erstellt: ${team.createdAt.day}.${team.createdAt.month}.${team.createdAt.year}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
