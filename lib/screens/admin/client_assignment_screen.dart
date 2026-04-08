import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team.dart';
import '../../models/client.dart';
import '../../providers/app_provider.dart';
import '../../services/admin_service.dart';
import '../../services/hidrive_webdav_client.dart';

class ClientAssignmentScreen extends StatefulWidget {
  const ClientAssignmentScreen({super.key});

  @override
  State<ClientAssignmentScreen> createState() => _ClientAssignmentScreenState();
}

class _ClientAssignmentScreenState extends State<ClientAssignmentScreen> {
  List<Team> _teams = [];
  bool _isLoading = true;
  String? _selectedTeamId;
  final Set<String> _selectedClientIds = {};
  bool _isAssigning = false;

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

  Future<void> _assignClients() async {
    if (_selectedTeamId == null || _selectedClientIds.isEmpty) return;

    setState(() => _isAssigning = true);
    try {
      final app = Provider.of<AppProvider>(context, listen: false);
      final service = _createAdminService();
      int success = 0;
      int failed = 0;

      for (final clientId in _selectedClientIds) {
        final client = app.clients.firstWhere(
          (c) => c.id == clientId,
          orElse: () => throw Exception('Klient nicht gefunden'),
        );
        // Klient-Daten verschlüsseln
        final clientJson = jsonEncode(client.toJson());
        final encrypted = await app.secureStorageService.cryptoStorage
            .encryptRecord(
          plaintext: utf8.encode(clientJson),
          aad: {'type': 'client', 'clientId': clientId},
        );
        final encBytes =
            Uint8List.fromList(utf8.encode(jsonEncode(encrypted)));

        final ok = await service.assignClientToTeam(
          clientId: clientId,
          teamId: _selectedTeamId!,
          encryptedClientData: encBytes,
        );
        if (ok) {
          success++;
        } else {
          failed++;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$success Klient(en) zugewiesen'
              '${failed > 0 ? ', $failed fehlgeschlagen' : ''}'),
          backgroundColor: failed == 0 ? Colors.green : Colors.orange,
        ),
      );
      setState(() {
        _selectedClientIds.clear();
        _isAssigning = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = Provider.of<AppProvider>(context);
    final clients = app.clients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klienten zuweisen'),
        actions: [
          if (_selectedClientIds.isNotEmpty && _selectedTeamId != null)
            TextButton.icon(
              onPressed: _isAssigning ? null : _assignClients,
              icon: _isAssigning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text('${_selectedClientIds.length} zuweisen'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Team-Auswahl
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedTeamId,
                    decoration: const InputDecoration(
                      labelText: 'Ziel-Team',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.groups),
                    ),
                    hint: const Text('Team auswaehlen'),
                    items: _teams
                        .map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                  '${t.name} (${t.memberCount} Mitarbeiter)'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTeamId = v),
                  ),
                ),
                if (_selectedTeamId == null)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Waehle zuerst ein Team aus',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else if (clients.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          const Text('Keine Klienten vorhanden'),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        final selected =
                            _selectedClientIds.contains(client.id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: CheckboxListTile(
                            value: selected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedClientIds.add(client.id);
                                } else {
                                  _selectedClientIds.remove(client.id);
                                }
                              });
                            },
                            title: Text(client.name),
                            subtitle: Text(
                                'ID: ${client.klientenId ?? client.id}'),
                            secondary: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                              child: Text(
                                client.name.isNotEmpty
                                    ? client.name[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
