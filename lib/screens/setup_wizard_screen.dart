import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_settings.dart';
import '../models/bundesland.dart';
import '../models/mitarbeiter.dart';
import '../services/admin_service.dart';
import '../services/hidrive_webdav_client.dart';
import 'home_screen.dart';

enum StorageMode { local, hidrive }
enum SetupPath { none, admin, invitation }

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  SetupPath _setupPath = SetupPath.none;

  // Einladungs-Pfad
  final _tokenController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isApplyingToken = false;
  String? _tokenError;
  Map<String, dynamic>? _decodedToken;

  // Seite 2: Profil
  final _vornameController = TextEditingController();
  final _nachnameController = TextEditingController();
  String? _selectedBerufsgruppe;
  final _arbeitszeitController = TextEditingController(text: '40');
  Bundesland _selectedBundesland = Bundesland.berlin;
  final _profilFormKey = GlobalKey<FormState>();

  // Seite 3: Speichermodus
  StorageMode? _storageMode;

  // Seite 4: HiDrive
  final _hidriveUsernameController = TextEditingController();
  final _hidrivePasswordController = TextEditingController();
  final _orgIdController = TextEditingController(text: 'default');
  final _teamIdController = TextEditingController();
  bool _isAdmin = false;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void dispose() {
    _pageController.dispose();
    _vornameController.dispose();
    _nachnameController.dispose();
    _arbeitszeitController.dispose();
    _hidriveUsernameController.dispose();
    _hidrivePasswordController.dispose();
    _orgIdController.dispose();
    _teamIdController.dispose();
    _tokenController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  int get _maxPage => _setupPath == SetupPath.invitation ? 3 : 4;

  void _nextPage() {
    if (_currentPage < _maxPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _setupPath != SetupPath.none;
      case 1:
        if (_setupPath == SetupPath.invitation) {
          return _decodedToken != null; // Token erfolgreich entschlüsselt
        }
        return _vornameController.text.trim().isNotEmpty &&
            _nachnameController.text.trim().isNotEmpty;
      case 2:
        if (_setupPath == SetupPath.invitation) {
          return _vornameController.text.trim().isNotEmpty &&
              _nachnameController.text.trim().isNotEmpty;
        }
        return _storageMode != null;
      case 3:
        if (_setupPath == SetupPath.invitation) return true; // Fertig-Seite
        if (_storageMode == StorageMode.local) return true;
        return _hidriveUsernameController.text.trim().isNotEmpty &&
            _hidrivePasswordController.text.trim().isNotEmpty;
      case 4:
        return true;
      default:
        return false;
    }
  }

  Future<void> _saveProfile() async {
    final appProvider = context.read<AppProvider>();
    final user = Mitarbeiter.create(
      name: _nachnameController.text.trim(),
      vorname: _vornameController.text.trim(),
      email: '',
      telefon: '',
      teamNummer: 1,
      bereich: MitarbeiterBereich.eingliederungshilfe,
      wochenarbeitszeit: double.tryParse(_arbeitszeitController.text) ?? 40.0,
    );
    await appProvider.createCurrentUser(user);

    final wochenstunden = double.tryParse(_arbeitszeitController.text) ?? 40.0;
    await appProvider.updateSettings(appProvider.settings.copyWith(
      wochenarbeitszeit: wochenstunden,
      bundesland: _selectedBundesland,
    ));
  }

  Future<void> _saveStorageSettings() async {
    final appProvider = context.read<AppProvider>();
    if (_storageMode == StorageMode.hidrive) {
      await appProvider.updateSettings(appProvider.settings.copyWith(
        hidriveUsername: _hidriveUsernameController.text.trim(),
        hidrivePassword: _hidrivePasswordController.text.trim(),
        organizationId: _orgIdController.text.trim(),
        teamId: _teamIdController.text.trim(),
        userRole: _isAdmin ? UserRole.orgAdmin : UserRole.teamMember,
      ));
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final username = _hidriveUsernameController.text.trim();
      final password = _hidrivePasswordController.text.trim();
      final client = HiDriveWebDAVClient(
        baseUrl: HiDriveConfig.buildWebDAVUrl(username),
        username: username,
        password: password,
        certificatePins: HiDriveConfig.certificatePins,
      );
      final result = await client.testConnection();
      setState(() {
        _testSuccess = result.isSuccess;
        _testResult = result.isSuccess
            ? 'Verbindung erfolgreich!'
            : result.error ?? 'Verbindung fehlgeschlagen';
      });
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Fehler: $e';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _applyInvitationToken() async {
    if (_decodedToken == null) return;
    final appProvider = context.read<AppProvider>();
    final token = _decodedToken!;

    // HiDrive-Credentials aus Token
    final hidrive = token['hidrive'] as Map<String, dynamic>?;
    final teams = List<String>.from(token['teams'] ?? []);
    final teamKeys = token['teamKeys'] as Map<String, dynamic>?;
    final role = token['role'] as String? ?? 'team_member';

    UserRole userRole;
    switch (role) {
      case 'org_admin': userRole = UserRole.orgAdmin; break;
      case 'pv_admin': userRole = UserRole.pvAdmin; break;
      case 'team_lead': userRole = UserRole.teamLead; break;
      case 'org_auditor': userRole = UserRole.orgAuditor; break;
      default: userRole = UserRole.teamMember;
    }

    await appProvider.updateSettings(appProvider.settings.copyWith(
      hidriveUsername: hidrive?['username'] ?? '',
      hidrivePassword: hidrive?['appPassword'] ?? '',
      organizationId: token['org'] ?? '',
      teamId: teams.isNotEmpty ? teams.first : '',
      userRole: userRole,
      totpSecret: token['totp'] ?? '',
    ));

    // Team-Key anwenden (erster Team-Key)
    if (teamKeys != null && teamKeys.isNotEmpty) {
      final firstKey = teamKeys.values.first as String;
      final keyBytes = base64Decode(firstKey);
      if (keyBytes.length == 32) {
        appProvider.secureStorageService.cryptoStorage.setExternalMEK(keyBytes);
      }
    }
  }

  Future<void> _decryptToken() async {
    final tokenText = _tokenController.text.trim();
    final pin = _pinController.text.trim();
    if (tokenText.isEmpty || pin.isEmpty) {
      setState(() => _tokenError = 'Bitte Token und PIN eingeben');
      return;
    }

    setState(() { _isApplyingToken = true; _tokenError = null; });
    try {
      final decoded = await AdminService.decryptProvisioningToken(tokenText, pin);
      if (decoded == null) {
        setState(() { _tokenError = 'Ungültiger Token oder falscher PIN'; _isApplyingToken = false; });
        return;
      }
      if (decoded['type'] != 'egh-provisioning-v1') {
        setState(() { _tokenError = 'Ungültiges Token-Format'; _isApplyingToken = false; });
        return;
      }
      setState(() { _decodedToken = decoded; _isApplyingToken = false; });
    } catch (e) {
      setState(() { _tokenError = 'Fehler: $e'; _isApplyingToken = false; });
    }
  }

  Future<void> _completeSetup() async {
    final appProvider = context.read<AppProvider>();

    if (_setupPath == SetupPath.invitation) {
      await _applyInvitationToken();
    } else {
      await _saveStorageSettings();
    }

    await appProvider.completeSetup();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fortschritts-Dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    _setupPath == SetupPath.invitation ? 4 : 5, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage >= index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Seiten
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: _setupPath == SetupPath.invitation
                    ? [
                        _buildWelcomePage(theme),
                        _buildTokenPage(theme),
                        _buildProfilePage(theme),
                        _buildCompletionPage(theme),
                      ]
                    : [
                        _buildWelcomePage(theme),
                        _buildProfilePage(theme),
                        _buildStoragePage(theme),
                        _buildConfigPage(theme),
                        _buildCompletionPage(theme),
                      ],
              ),
            ),
            // Navigation
            if (_currentPage < _maxPage)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      TextButton.icon(
                        onPressed: _previousPage,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Zurueck'),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _canProceed()
                          ? () async {
                              // Profil-Seite: Admin-Pfad = Seite 1, Einladung = Seite 2
                              final isProfilePage = (_setupPath == SetupPath.invitation && _currentPage == 2) ||
                                  (_setupPath != SetupPath.invitation && _currentPage == 1);
                              if (isProfilePage) {
                                if (_profilFormKey.currentState?.validate() !=
                                    true) return;
                                await _saveProfile();
                              }
                              _nextPage();
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Weiter'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Seite 1: Willkommen (mit Pfad-Auswahl) ---
  Widget _buildWelcomePage(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.accessibility_new,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'FEGH-Dokumentation',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Wie moechten Sie beginnen?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Admin-Pfad
            _buildSetupPathCard(
              theme: theme,
              icon: Icons.admin_panel_settings,
              title: 'Organisation einrichten',
              description:
                  'Sie sind Admin und richten die Organisation, Teams und Mitarbeiter ein.',
              selected: _setupPath == SetupPath.admin,
              onTap: () => setState(() {
                _setupPath = SetupPath.admin;
                _storageMode = StorageMode.hidrive;
              }),
            ),
            const SizedBox(height: 16),

            // Einladungs-Pfad
            _buildSetupPathCard(
              theme: theme,
              icon: Icons.qr_code_scanner,
              title: 'Einladungscode verwenden',
              description:
                  'Sie haben einen QR-Code oder Token von Ihrem Admin erhalten.',
              selected: _setupPath == SetupPath.invitation,
              onTap: () => setState(() {
                _setupPath = SetupPath.invitation;
                _storageMode = StorageMode.hidrive;
              }),
            ),
            const SizedBox(height: 16),

            // Lokal-Pfad (Einzelnutzer)
            TextButton(
              onPressed: () => setState(() {
                _setupPath = SetupPath.admin;
                _storageMode = StorageMode.local;
              }),
              child: Text(
                'Oder nur lokal ohne Cloud nutzen',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupPathCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: selected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 32,
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  // --- Token-Seite (Einladungs-Pfad) ---
  Widget _buildTokenPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Einladungscode', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Scannen Sie den QR-Code oder fuegen Sie den Token-Text ein.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Token (Text)',
              hintText: 'Token hier einfuegen...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            decoration: const InputDecoration(
              labelText: 'PIN (6-stellig)',
              hintText: '000000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pin),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: (_tokenController.text.trim().isNotEmpty &&
                          _pinController.text.trim().length == 6 &&
                          !_isApplyingToken)
                      ? _decryptToken
                      : null,
                  icon: _isApplyingToken
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.lock_open),
                  label: const Text('Token entschluesseln'),
                ),
              ),
            ],
          ),
          if (_tokenError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_tokenError!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ],
          if (_decodedToken != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('Token gueltig!',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Organisation: ${_decodedToken!['org'] ?? '-'}'),
                  Text('Rolle: ${_decodedToken!['role'] ?? '-'}'),
                  Text('Teams: ${(_decodedToken!['teams'] as List?)?.join(', ') ?? '-'}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Seite 2: Profil ---
  Widget _buildProfilePage(ThemeData theme) {
    final appProvider = context.watch<AppProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _profilFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ihr Profil', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Geben Sie Ihre grundlegenden Daten ein.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _vornameController,
              decoration: const InputDecoration(
                labelText: 'Vorname *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nachnameController,
              decoration: const InputDecoration(
                labelText: 'Nachname *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedBerufsgruppe,
              decoration: const InputDecoration(
                labelText: 'Berufsgruppe',
                prefixIcon: Icon(Icons.work_outline),
              ),
              items: appProvider.settings.berufsgruppen
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBerufsgruppe = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _arbeitszeitController,
              decoration: const InputDecoration(
                labelText: 'Wochenarbeitszeit (Stunden)',
                prefixIcon: Icon(Icons.schedule),
                suffixText: 'h/Woche',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            _buildBundeslandAuswahl(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBundeslandAuswahl(ThemeData theme) {
    final profil = BundeslandProfile.forLand(_selectedBundesland);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bundesland der Organisation',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'Legt fest, welches Bedarfserhebungsinstrument, welche Formulare und '
          'welches Wirksamkeitsverfahren genutzt werden.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Bundesland>(
          initialValue: _selectedBundesland,
          decoration: const InputDecoration(
            labelText: 'Bundesland',
            prefixIcon: Icon(Icons.map_outlined),
          ),
          items: BundeslandProfile.alle()
              .map((p) => DropdownMenuItem(
                    value: p.bundesland,
                    child: Row(
                      children: [
                        Text(p.anzeigeName),
                        if (!p.implementiert) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('experimentell',
                                style: TextStyle(fontSize: 10, color: Colors.amber)),
                          ),
                        ],
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) => v != null ? setState(() => _selectedBundesland = v) : null,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: profil.implementiert
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                : Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    profil.implementiert ? Icons.check_circle : Icons.warning_amber,
                    size: 20,
                    color: profil.implementiert ? Colors.green : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profil.instrumentName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(profil.rahmenvertragName, style: theme.textTheme.bodySmall),
              if (profil.besonderheiten.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...profil.besonderheiten.map((b) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(b, style: theme.textTheme.bodySmall)),
                    ],
                  ),
                )),
              ],
              if (!profil.implementiert) ...[
                const SizedBox(height: 8),
                const Text(
                  'Dieses Bundesland ist experimentell. Landesspezifische Formulare und '
                  'Bedarfserhebungsinstrumente werden in einem kommenden Update ergaenzt. '
                  'Aktuell koennen die generischen Wirkungsmessungs-Funktionen (GAS, POS) genutzt werden.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- Seite 3: Datenspeicherung ---
  Widget _buildStoragePage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datenspeicherung', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Wie moechten Sie Ihre Daten speichern?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _buildStorageCard(
            theme: theme,
            icon: Icons.shield_outlined,
            title: 'Nur lokal (verschluesselt)',
            description:
                'Alle Daten bleiben auf diesem Geraet. AES-256 Verschluesselung. Kein Internet noetig.',
            badge: 'Empfohlen fuer Einzelnutzer',
            selected: _storageMode == StorageMode.local,
            onTap: () => setState(() => _storageMode = StorageMode.local),
          ),
          const SizedBox(height: 16),
          _buildStorageCard(
            theme: theme,
            icon: Icons.cloud_outlined,
            title: 'HiDrive Cloud-Sync',
            description:
                'Verschluesselt mit STRATO HiDrive synchronisiert. Ideal fuer Teams und mehrere Geraete.',
            badge: 'Erfordert HiDrive Business Zugangsdaten',
            selected: _storageMode == StorageMode.hidrive,
            onTap: () => setState(() => _storageMode = StorageMode.hidrive),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
    required String badge,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: selected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(badge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          )),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  // --- Seite 4: Konfiguration ---
  Widget _buildConfigPage(ThemeData theme) {
    if (_storageMode == StorageMode.hidrive) {
      return _buildHiDriveConfig(theme);
    }
    return _buildLocalConfig(theme);
  }

  Widget _buildLocalConfig(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lokale Verschluesselung', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.lock_outline,
                      size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Ihre Daten werden mit AES-256-GCM verschluesselt auf diesem Geraet gespeichert.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(theme, Icons.fingerprint,
                      'Biometrische Entsperrung aktiv'),
                  const SizedBox(height: 8),
                  _buildInfoRow(theme, Icons.backup_outlined,
                      'Backup-Export jederzeit in den Einstellungen verfuegbar'),
                  const SizedBox(height: 8),
                  _buildInfoRow(theme, Icons.wifi_off,
                      'Keine Internetverbindung erforderlich'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }

  Widget _buildHiDriveConfig(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HiDrive Konfiguration', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Geben Sie Ihre STRATO HiDrive Zugangsdaten ein.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _hidriveUsernameController,
            decoration: const InputDecoration(
              labelText: 'HiDrive Benutzername',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hidrivePasswordController,
            decoration: const InputDecoration(
              labelText: 'HiDrive Passwort',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _orgIdController,
            decoration: const InputDecoration(
              labelText: 'Organisations-ID',
              prefixIcon: Icon(Icons.business),
              hintText: 'default',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _teamIdController,
            decoration: const InputDecoration(
              labelText: 'Team-ID (optional)',
              prefixIcon: Icon(Icons.group_outlined),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Admin-Modus'),
            subtitle:
                const Text('Zugriff auf Personalverwaltungsfunktionen'),
            value: _isAdmin,
            onChanged: (v) => setState(() => _isAdmin = v),
          ),
          if (_setupPath == SetupPath.admin && _isAdmin) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Als Admin koennen Sie Teams erstellen, Mitarbeiter einladen und Klienten zuweisen.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_hidriveUsernameController.text.trim().isNotEmpty &&
                      _hidrivePasswordController.text.trim().isNotEmpty &&
                      !_isTesting)
                  ? _testConnection
                  : null,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: Text(_isTesting
                  ? 'Teste Verbindung...'
                  : 'Verbindung testen'),
            ),
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testSuccess
                    ? Colors.green.withValues(alpha:0.1)
                    : Colors.red.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _testSuccess ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess ? Icons.check_circle : Icons.error,
                    color: _testSuccess ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Seite 5: Fertig ---
  Widget _buildCompletionPage(ThemeData theme) {
    final vorname = _vornameController.text.trim();
    final nachname = _nachnameController.text.trim();
    final modus = _storageMode == StorageMode.hidrive
        ? 'HiDrive Cloud-Sync'
        : 'Lokal (verschluesselt)';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 64,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ihre App ist eingerichtet!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow(
                        theme, 'Name', '$vorname $nachname'),
                    const Divider(),
                    _buildSummaryRow(theme, 'Speichermodus', modus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _completeSetup,
                icon: const Icon(Icons.rocket_launch),
                label: const Text('App starten'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
