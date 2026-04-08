import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/team.dart';
import '../../models/app_settings.dart';
import '../../providers/app_provider.dart';
import '../../services/admin_service.dart';
import '../../services/hidrive_webdav_client.dart';

class EmployeeInvitationScreen extends StatefulWidget {
  const EmployeeInvitationScreen({super.key});

  @override
  State<EmployeeInvitationScreen> createState() =>
      _EmployeeInvitationScreenState();
}

class _EmployeeInvitationScreenState extends State<EmployeeInvitationScreen> {
  final _emailController = TextEditingController();
  UserRole _selectedRole = UserRole.teamMember;
  final List<String> _selectedTeamIds = [];
  List<Team> _teams = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  String? _generatedToken;
  String? _generatedPin;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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

  String _generatePin() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.orgAdmin: return 'org_admin';
      case UserRole.pvAdmin: return 'pv_admin';
      case UserRole.teamLead: return 'team_lead';
      case UserRole.teamMember: return 'team_member';
      case UserRole.orgAuditor: return 'org_auditor';
    }
  }

  String _roleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.orgAdmin: return 'Org-Admin';
      case UserRole.pvAdmin: return 'PV-Admin';
      case UserRole.teamLead: return 'Teamleitung';
      case UserRole.teamMember: return 'Mitarbeiter';
      case UserRole.orgAuditor: return 'Pruefer';
    }
  }

  Future<void> _generateToken() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte E-Mail eingeben')),
      );
      return;
    }
    if (_selectedTeamIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens ein Team auswaehlen')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final pin = _generatePin();
      final service = _createAdminService();
      final token = await service.generateProvisioningToken(
        employeeEmail: _emailController.text.trim(),
        role: _roleToString(_selectedRole),
        teamIds: _selectedTeamIds,
        pin: pin,
      );
      if (mounted) {
        setState(() {
          _generatedToken = token;
          _generatedPin = pin;
          _isGenerating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Generieren des Tokens'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mitarbeiter einladen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formular
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Einladung erstellen',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail-Adresse *',
                        hintText: 'mitarbeiter@example.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Rolle',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      items: [
                        UserRole.teamMember,
                        UserRole.teamLead,
                        UserRole.orgAuditor,
                      ]
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(_roleDisplayName(role)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedRole = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Teams zuweisen',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_teams.isEmpty)
                      const Text(
                        'Keine Teams vorhanden. Erstelle zuerst ein Team.',
                        style: TextStyle(color: Colors.orange),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _teams.map((team) {
                          final selected =
                              _selectedTeamIds.contains(team.id);
                          return FilterChip(
                            label: Text(team.name),
                            selected: selected,
                            onSelected: (sel) {
                              setState(() {
                                if (sel) {
                                  _selectedTeamIds.add(team.id);
                                } else {
                                  _selectedTeamIds.remove(team.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isGenerating ? null : _generateToken,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.qr_code),
                        label: Text(_isGenerating
                            ? 'Generiere...'
                            : 'Einladung generieren'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Generiertes Token
            if (_generatedToken != null && _generatedPin != null) ...[
              Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Einladung erstellt!',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _generatedToken!,
                          version: QrVersions.auto,
                          size: 200,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PIN anzeigen
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.key,
                                color: theme.colorScheme.onErrorContainer),
                            const SizedBox(width: 8),
                            Text(
                              'PIN: $_generatedPin',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onErrorContainer,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Den PIN separat an den Mitarbeiter weitergeben (muendlich, SMS, etc.)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Token kopieren
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _generatedToken!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Token in Zwischenablage kopiert')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Token kopieren'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
