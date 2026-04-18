import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../models/bundesland.dart';
import '../models/client.dart';
import '../models/appointment.dart';
import '../models/arbeitszeit.dart';
import '../providers/app_provider.dart';
import '../services/gdpr_service.dart';
import '../services/secure_storage_service.dart';
import '../services/app_lifecycle_service.dart';
import '../services/app_logger.dart';

import '../utils/platform_utils.dart';
import '../services/hidrive_webdav_client.dart';
import 'backup_screen.dart';
import '../services/totp_service.dart';
import '../services/permission_service.dart';
import '../models/ui_customization.dart';
import '../services/document_storage_service.dart';
import 'team_key_qr_scan_screen.dart';
import 'standorte_screen.dart';
import '../models/standort.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Removed BackupService - using DSGVO import/export instead
  late final GDPRService _gdprService;
  final DocumentStorageService _docStorage = DocumentStorageService();
  bool _isLoading = false;
  List<StoredDocument> _storedDocs = [];
  bool _docsLoaded = false;

  @override
  void initState() {
    super.initState();
    _gdprService = GDPRService(SecureStorageService().cryptoStorage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    _buildAccessStatusSection(appProvider),
                    const SizedBox(height: 32),

                    // UI-Anpassungen
                    _buildUICustomizationSection(appProvider),
                    const SizedBox(height: 32),

                    // Datenverwaltung
                    _buildDataSection(appProvider),

                    const SizedBox(height: 32),

                    // Fachleistungsstunden (Kalkulation)
                    _buildFLSSection(appProvider),
                    _buildRechnungsstellerSection(appProvider),

                    const SizedBox(height: 32),

                    // Standorte & Fahrwege
                    _buildStandorteSection(appProvider),

                    const SizedBox(height: 32),

                    // DSGVO & Datenschutz
                    _buildGDPRSection(appProvider),

                    const SizedBox(height: 32),

                    // Dokumentenablage
                    _buildDocumentStorageSection(),

                    const SizedBox(height: 32),

                    // Cloud-Sync (HiDrive Business)
                    _buildCloudSyncSection(appProvider),

                    if (PlatformUtils.isWeb) ...[
                      const SizedBox(height: 32),
                      _buildSecuritySection(appProvider),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // App-Info
                    _buildAppInfoSection(),
                    
                    const SizedBox(height: 100),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildUICustomizationSection(AppProvider appProvider) {
    final ui = appProvider.settings.uiCustomization;

    return _buildSection(
      title: 'UI-Anpassungen',
      icon: Icons.palette,
      children: [
        // Dark Mode Toggle
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode),
          title: const Text('Dark Mode'),
          value: appProvider.settings.darkModeEnabled,
          onChanged: (value) {
            appProvider.updateSettings(
              appProvider.settings.copyWith(darkModeEnabled: value),
            );
          },
        ),
        const Divider(height: 1),

        // Preset-Auswahl
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UI-Dichte',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<UIDensityPreset>(
                segments: const [
                  ButtonSegment(
                    value: UIDensityPreset.compact,
                    label: Text('Kompakt'),
                    icon: Icon(Icons.density_small),
                  ),
                  ButtonSegment(
                    value: UIDensityPreset.standard,
                    label: Text('Standard'),
                    icon: Icon(Icons.density_medium),
                  ),
                  ButtonSegment(
                    value: UIDensityPreset.comfortable,
                    label: Text('Komfortabel'),
                    icon: Icon(Icons.density_large),
                  ),
                ],
                selected: {ui.densityPreset},
                onSelectionChanged: (selected) {
                  final preset = selected.first;
                  final newUi = UICustomization.fromPreset(preset).copyWith(
                    tabDisplayMode: ui.tabDisplayMode,
                    cardStyle: ui.cardStyle,
                  );
                  appProvider.updateSettings(
                    appProvider.settings.copyWith(uiCustomization: newUi),
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Feineinstellungen (aufklappbar)
        ExpansionTile(
          leading: const Icon(Icons.tune),
          title: const Text('Feineinstellungen'),
          children: [
            // Schriftgroesse
            _buildSliderTile(
              label: 'Schriftgroesse',
              value: ui.fontScale,
              min: 0.8,
              max: 1.4,
              divisions: 12,
              displayValue: '${(ui.fontScale * 100).round()}%',
              defaultValue: _getPresetDefault(ui.densityPreset).fontScale,
              onChanged: (value) {
                appProvider.updateSettings(
                  appProvider.settings.copyWith(
                    uiCustomization: ui.copyWith(fontScale: value),
                  ),
                );
              },
              onReset: () {
                final preset = _getPresetDefault(ui.densityPreset);
                appProvider.updateSettings(
                  appProvider.settings.copyWith(
                    uiCustomization: ui.copyWith(fontScale: preset.fontScale),
                  ),
                );
              },
            ),

            // Zeilenabstand
            _buildSliderTile(
              label: 'Zeilenabstand',
              value: ui.lineHeightScale,
              min: 1.0,
              max: 1.6,
              divisions: 6,
              displayValue: ui.lineHeightScale.toStringAsFixed(1),
              defaultValue: _getPresetDefault(ui.densityPreset).lineHeightScale,
              onChanged: (value) {
                appProvider.updateSettings(
                  appProvider.settings.copyWith(
                    uiCustomization: ui.copyWith(lineHeightScale: value),
                  ),
                );
              },
              onReset: () {
                final preset = _getPresetDefault(ui.densityPreset);
                appProvider.updateSettings(
                  appProvider.settings.copyWith(
                    uiCustomization: ui.copyWith(lineHeightScale: preset.lineHeightScale),
                  ),
                );
              },
            ),

            // Abstaende/Padding
            _buildSliderTile(
              label: 'Abstaende/Padding',
              value: ui.spacingScale,
              min: 0.7,
              max: 1.5,
              divisions: 16,
              displayValue: '${(ui.spacingScale * 100).round()}%',
              defaultValue: _getPresetDefault(ui.densityPreset).spacingScale,
              onChanged: (value) {
                appProvider.updateSettings(
                  appProvider.settings.copyWith(
                    uiCustomization: ui.copyWith(spacingScale: value),
                  ),
                );
              },
              onReset: () {
                final preset = _getPresetDefault(ui.densityPreset);
                appProvider.updateSettings(
                  appProvider.settings.copyWith(
                    uiCustomization: ui.copyWith(spacingScale: preset.spacingScale),
                  ),
                );
              },
            ),

            // Tabellenzeilen-Hoehe
            _buildSliderTile(
              label: 'Tabellenzeilen-Hoehe',
              value: ui.tableRowHeight,
              min: 36,
              max: 64,
              divisions: 7,
              displayValue: '${ui.tableRowHeight.round()} px',
              defaultValue: _getPresetDefault(ui.densityPreset).tableRowHeight,
              onChanged: (value) {
                appProvider.updateSettings(
                  appProvider.settings.copyWith(
                    uiCustomization: ui.copyWith(tableRowHeight: value),
                  ),
                );
              },
              onReset: () {
                final preset = _getPresetDefault(ui.densityPreset);
                appProvider.updateSettings(
                  appProvider.settings.copyWith(
                    uiCustomization: ui.copyWith(tableRowHeight: preset.tableRowHeight),
                  ),
                );
              },
            ),
          ],
        ),
        const Divider(height: 1),

        // Layout-Praeferenzen
        ExpansionTile(
          leading: const Icon(Icons.view_quilt),
          title: const Text('Layout-Praeferenzen'),
          children: [
            // Tab-Darstellung
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tab-Darstellung'),
                  const SizedBox(height: 8),
                  SegmentedButton<TabDisplayMode>(
                    segments: const [
                      ButtonSegment(
                        value: TabDisplayMode.iconAndText,
                        label: Text('Icon+Text'),
                      ),
                      ButtonSegment(
                        value: TabDisplayMode.iconOnly,
                        label: Text('Nur Icon'),
                      ),
                      ButtonSegment(
                        value: TabDisplayMode.textOnly,
                        label: Text('Nur Text'),
                      ),
                    ],
                    selected: {ui.tabDisplayMode},
                    onSelectionChanged: (selected) {
                      appProvider.updateSettings(
                        appProvider.settings.copyWith(
                          uiCustomization: ui.copyWith(tabDisplayMode: selected.first),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Karten-Stil
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Karten-Stil'),
                  const SizedBox(height: 8),
                  SegmentedButton<CardStyle>(
                    segments: const [
                      ButtonSegment(
                        value: CardStyle.outlined,
                        label: Text('Rahmen'),
                      ),
                      ButtonSegment(
                        value: CardStyle.elevated,
                        label: Text('Erhoeht'),
                      ),
                      ButtonSegment(
                        value: CardStyle.flat,
                        label: Text('Flach'),
                      ),
                    ],
                    selected: {ui.cardStyle},
                    onSelectionChanged: (selected) {
                      appProvider.updateSettings(
                        appProvider.settings.copyWith(
                          uiCustomization: ui.copyWith(cardStyle: selected.first),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tabellen-Dichte
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tabellen-Dichte'),
                  const SizedBox(height: 8),
                  SegmentedButton<TableDensity>(
                    segments: const [
                      ButtonSegment(
                        value: TableDensity.compact,
                        label: Text('Kompakt'),
                      ),
                      ButtonSegment(
                        value: TableDensity.standard,
                        label: Text('Standard'),
                      ),
                      ButtonSegment(
                        value: TableDensity.comfortable,
                        label: Text('Grosszuegig'),
                      ),
                    ],
                    selected: {ui.tableDensity},
                    onSelectionChanged: (selected) {
                      final rowHeight = switch (selected.first) {
                        TableDensity.compact => 36.0,
                        TableDensity.standard => 48.0,
                        TableDensity.comfortable => 56.0,
                      };
                      appProvider.updateSettings(
                        appProvider.settings.copyWith(
                          uiCustomization: ui.copyWith(
                            tableDensity: selected.first,
                            tableRowHeight: rowHeight,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 1),

        // Vorschau-Card
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vorschau',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dies ist ein Beispieltext in der aktuellen Schriftgroesse.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kleinerer Text als Referenz.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Zuruecksetzen-Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: OutlinedButton.icon(
            onPressed: () {
              appProvider.updateSettings(
                appProvider.settings.copyWith(
                  uiCustomization: const UICustomization(),
                ),
              );
            },
            icon: const Icon(Icons.restore),
            label: const Text('Auf Standard zuruecksetzen'),
          ),
        ),
      ],
    );
  }

  UICustomization _getPresetDefault(UIDensityPreset preset) {
    return UICustomization.fromPreset(preset);
  }

  Widget _buildSliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required double defaultValue,
    required ValueChanged<double> onChanged,
    required VoidCallback onReset,
  }) {
    final isDefault = (value - defaultValue).abs() < 0.01;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                displayValue,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (!isDefault)
                IconButton(
                  icon: const Icon(Icons.restore, size: 18),
                  onPressed: onReset,
                  tooltip: 'Zuruecksetzen',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBundeslandTile(AppProvider appProvider) {
    final profil = BundeslandProfile.forLand(appProvider.settings.bundesland);
    return ListTile(
      leading: Icon(
        Icons.map_outlined,
        color: profil.implementiert ? null : Colors.amber,
      ),
      title: const Text('Bundesland'),
      subtitle: Text(
        '${profil.anzeigeName}${profil.implementiert ? "" : " (experimentell)"}\n${profil.instrumentName}',
      ),
      isThreeLine: true,
      trailing: TextButton(
        onPressed: () => _bundeslandAendern(appProvider),
        child: const Text('Aendern'),
      ),
    );
  }

  Future<void> _bundeslandAendern(AppProvider appProvider) async {
    Bundesland selected = appProvider.settings.bundesland;
    final saved = await showDialog<Bundesland>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bundesland aendern'),
        content: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final profil = BundeslandProfile.forLand(selected);
            return SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Bundesland>(
                    initialValue: selected,
                    decoration: const InputDecoration(
                      labelText: 'Bundesland der Organisation',
                      border: OutlineInputBorder(),
                    ),
                    items: BundeslandProfile.alle()
                        .map((p) => DropdownMenuItem(
                              value: p.bundesland,
                              child: Text(p.anzeigeName +
                                  (p.implementiert ? '' : ' (experimentell)')),
                            ))
                        .toList(),
                    onChanged: (v) => v != null
                        ? setStateDialog(() => selected = v)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(profil.instrumentName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(profil.rahmenvertragName,
                      style: Theme.of(context).textTheme.bodySmall),
                  if (!profil.implementiert) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Dieses Bundesland ist experimentell. Landesspezifische '
                        'Formulare und Bedarfserhebungsinstrumente folgen.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, selected),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (saved != null && saved != appProvider.settings.bundesland) {
      await appProvider.updateSettings(
        appProvider.settings.copyWith(bundesland: saved),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bundesland auf ${BundeslandProfile.forLand(saved).anzeigeName} geaendert'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildAccessStatusSection(AppProvider appProvider) {
    final s = appProvider.settings;
    final perms = PermissionService(s.userRole);
    return _buildSection(
      title: 'Zugriffsstatus',
      icon: Icons.verified_user,
      initiallyExpanded: true,
      children: [
        ListTile(
          leading: const Icon(Icons.business),
          title: const Text('Organisation'),
          subtitle: Text(s.organizationId.isNotEmpty ? s.organizationId : 'nicht gesetzt'),
        ),
        ListTile(
          leading: const Icon(Icons.group),
          title: const Text('Team'),
          subtitle: Text(s.teamId.isNotEmpty ? s.teamId : 'Admin‑Modus (kein Team)'),
        ),
        _buildBundeslandTile(appProvider),
        ListTile(
          leading: Icon(s.isAdmin ? Icons.verified_user : Icons.person),
          title: const Text('Rolle'),
          subtitle: Text(perms.roleDisplayName),
          trailing: s.isAdmin
              ? null
              : TextButton.icon(
                  icon: const Icon(Icons.admin_panel_settings, size: 16),
                  label: const Text('Admin werden'),
                  onPressed: () => _makeAdmin(appProvider),
                ),
        ),
        // TOTP 2FA Status
        ListTile(
          leading: Icon(
            s.totpSecret.isNotEmpty ? Icons.security : Icons.security_outlined,
            color: s.totpSecret.isNotEmpty ? Colors.green : Colors.orange,
          ),
          title: const Text('Zwei-Faktor-Authentifizierung'),
          subtitle: Text(s.totpSecret.isNotEmpty ? 'Aktiviert' : 'Nicht eingerichtet'),
          trailing: s.totpSecret.isEmpty
              ? TextButton(
                  onPressed: () => _setupTotp(appProvider),
                  child: const Text('Einrichten'),
                )
              : TextButton(
                  onPressed: () => _showTotpInfo(appProvider),
                  child: const Text('Details'),
                ),
        ),
        // Berechtigungen
        ExpansionTile(
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Meine Berechtigungen'),
          children: perms.permissionSummary
              .map((p) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.check, size: 16, color: Colors.green),
                    title: Text(p, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Future<void> _makeAdmin(AppProvider appProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.indigo),
        title: const Text('Admin-Modus aktivieren?'),
        content: const Text(
          'Setzt deine Rolle auf Org-Admin. Du bekommst dann Zugriff auf den '
          'Verwaltung-Tab und kannst Teams, Mitarbeiter und Rollen verwalten.\n\n'
          'Diese Funktion ist fuer Solo-Admins kleiner Traeger gedacht. In '
          'groesseren Organisationen sollte die Rolle ueber einen Provisioning-'
          'QR von der Verwaltungs-App gesetzt werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Admin werden'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await appProvider.forceAdminRole();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Admin-Modus aktiv. Verwaltung-Tab ist jetzt sichtbar.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _setupTotp(AppProvider appProvider) async {
    final secret = TotpService.generateSecret();
    final secretB32 = TotpService.secretToBase32(secret);
    final uri = TotpService.generateOtpAuthUri(
      secret: secretB32,
      accountName: appProvider.settings.userName.isNotEmpty
          ? appProvider.settings.userName
          : 'Mitarbeiter',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('TOTP einrichten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scannen Sie diesen Code mit einer Authenticator-App '
                '(z.B. Google Authenticator, Microsoft Authenticator):',
              ),
              const SizedBox(height: 16),
              // QR-Code wuerde hier angezeigt (qr_flutter)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('Manueller Code:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(
                      secretB32,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'otpauth URI:\n$uri',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
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
            child: const Text('TOTP aktivieren'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await appProvider.updateSettings(
        appProvider.settings.copyWith(totpSecret: secretB32),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TOTP aktiviert. Ab der naechsten Anmeldung wird ein Code abgefragt.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showTotpInfo(AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('TOTP aktiv'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Zwei-Faktor-Authentifizierung ist aktiv'),
            ),
            const SizedBox(height: 8),
            const Text('Bei jeder Anmeldung wird ein 6-stelliger Code aus Ihrer Authenticator-App abgefragt.'),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (!mounted) return;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('TOTP deaktivieren?'),
                  content: const Text('Die Zwei-Faktor-Authentifizierung wird deaktiviert. Dies verringert die Sicherheit.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
                    FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Deaktivieren'),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await appProvider.updateSettings(
                  appProvider.settings.copyWith(totpSecret: ''),
                );
              }
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('TOTP deaktivieren'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }



  Widget _buildDataSection(AppProvider appProvider) {
    return _buildSection(
      title: 'Datenverwaltung',
      icon: Icons.storage,
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Datenstatistik'),
          subtitle: Text(
            '${appProvider.totalClients} Klienten • ${appProvider.totalAppointments} Termine',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Backup & Wiederherstellung'),
          subtitle: const Text('Verschluesseltes Backup erstellen oder wiederherstellen'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            );
          },
        ),
        ListTile(
          leading: Icon(
            Icons.delete_forever,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            'Alle Daten löschen',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text('Unwiderruflich alle Daten entfernen'),
          onTap: () => _showDeleteAllDataDialog(appProvider),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(AppProvider appProvider) {
    return _buildSection(
      title: 'Sicherheit',
      icon: Icons.security,
      children: [
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Passwort ändern'),
          subtitle: const Text('Anmeldepasswort aktualisieren'),
          onTap: () => _showChangePasswordDialog(appProvider),
        ),
        ListTile(
          leading: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            'Abmelden',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text('Sitzung beenden'),
          onTap: () => _showLogoutDialog(appProvider),
        ),
      ],
    );
  }

  Widget _buildAppInfoSection() {
    return _buildSection(
      title: 'App-Informationen',
      icon: Icons.info,
      children: [
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('FEGH-Dokumentation'),
          subtitle: Text('Version 0.1.0-alpha.1'),
        ),
        const ListTile(
          leading: Icon(Icons.person),
          title: Text('Entwickler'),
          subtitle: Text('Mirko Richter'),
        ),
        const ListTile(
          leading: Icon(Icons.copyright),
          title: Text('Copyright'),
          subtitle: Text('\u00a9 2025\u20132026 Mirko Richter. Alle Rechte vorbehalten.'),
        ),
        const ListTile(
          leading: Icon(Icons.developer_mode),
          title: Text('Entwickelt mit'),
          subtitle: Text('Flutter \u2022 Material Design 3'),
        ),
      ],
    );
  }

  Widget _buildGDPRSection(AppProvider appProvider) {
    return _buildSection(
      title: 'DSGVO & Datenschutz',
      icon: Icons.shield,
      children: [
        ListTile(
          leading: const Icon(Icons.download, color: Colors.blue),
          title: const Text('Meine Daten exportieren'),
          subtitle: const Text('Alle Daten verschlüsselt exportieren (Art. 20 DSGVO)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showGDPRExportDialog(),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.upload, color: Colors.green),
          title: const Text('Meine Daten wiederherstellen'),
          subtitle: const Text('Vollständige Datenwiederherstellung aus DSGVO-Export'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selectGDPRImportFile(appProvider),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Konto löschen'),
          subtitle: const Text('Alle Daten unwiderruflich löschen (Art. 17 DSGVO)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showGDPRDeletionDialog(),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.security, color: Colors.green),
          title: const Text('Verschlüsselungsstatus'),
          subtitle: const Text('AES-256-GCM + Envelope Encryption aktiv'),
          trailing: const Icon(Icons.verified_user, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildCloudSyncSection(AppProvider appProvider) {
    final settings = appProvider.settings;
    final isConfigured = settings.hidriveUsername.isNotEmpty && settings.hidrivePassword.isNotEmpty;

    return _buildSection(
      title: 'Cloud-Synchronisation (HiDrive Business)',
      icon: Icons.cloud_sync,
      children: [
        ListTile(
          leading: Icon(
            Icons.cloud,
            color: isConfigured ? Colors.green : Colors.orange,
          ),
          title: const Text('Cloud-Sync konfigurieren'),
          subtitle: Text(
            isConfigured
                ? 'Konfiguriert fuer: ${settings.hidriveUsername}'
                : 'WebDAV-Cloud (HiDrive, Nextcloud u.a.) mit E2E-Verschluesselung'
          ),
          trailing: Icon(
            isConfigured ? Icons.check_circle : Icons.chevron_right,
            color: isConfigured ? Colors.green : null,
          ),
          onTap: () => _showHiDriveConfigDialog(),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.vpn_key, color: Colors.blue),
          title: const Text('Sync-Passphrase setzen'),
          subtitle: const Text('Gemeinsamer Schlüssel für Geräte-Sync (E2E)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: isConfigured ? () => _showSyncPassphraseDialog(appProvider) : null,
          enabled: isConfigured,
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
          title: const Text('Team‑Key per QR scannen'),
          subtitle: const Text('Provisionierung aus der Personalverwaltung'),
          trailing: const Icon(Icons.chevron_right),
          onTap: isConfigured ? () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeamKeyQrScanScreen()),
            );
          } : null,
          enabled: isConfigured,
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.key, color: Colors.teal),
          title: const Text('Team‑Key importieren (Base64)'),
          subtitle: const Text('Team‑Schlüssel einfügen und anwenden'),
          trailing: const Icon(Icons.chevron_right),
          onTap: isConfigured ? () => _showTeamKeyImportDialog() : null,
          enabled: isConfigured,
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(
            Icons.sync,
            color: isConfigured ? Colors.blue : Colors.grey,
          ),
          title: const Text('Jetzt synchronisieren'),
          subtitle: Text(
            isConfigured
                ? 'Daten mit Cloud abgleichen'
                : 'Zuerst HiDrive konfigurieren'
          ),
          trailing: const Icon(Icons.cloud_upload),
          enabled: isConfigured,
          onTap: isConfigured ? () => _triggerCloudSync() : null,
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(
            Icons.verified,
            color: isConfigured ? Colors.green : Colors.grey,
          ),
          title: const Text('Verbindung testen'),
          subtitle: Text(
            isConfigured
                ? 'Cloud-Konnektivitaet pruefen'
                : 'Zuerst Cloud-Sync konfigurieren'
          ),
          trailing: const Icon(Icons.network_check),
          enabled: isConfigured,
          onTap: isConfigured ? () => _testHiDriveConnection() : null,
        ),
      ],
    );
  }

  void _showTeamKeyImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.key, color: Colors.teal, size: 40),
        title: const Text('Team‑Key importieren'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Team‑Key (Base64)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () async {
              final b64 = controller.text.trim();
              if (b64.isEmpty) return;
              Navigator.pop(context);
              try {
                final key = base64Decode(b64);
                if (key.length != 32) {
                  throw Exception('Ungültiger Key (erwartet 32 Byte)');
                }
                final svc = Provider.of<AppProvider>(context, listen: false).secureStorageService;
                svc.cryptoStorage.setExternalMEK(key);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Team‑Key angewendet. Jetzt synchronisieren.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Anwenden'),
          ),
        ],
      ),
    );
  }

  void _showSyncPassphraseDialog(AppProvider appProvider) {
    final controller = TextEditingController();
    final confirm = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          String strength = _passphraseStrength(controller.text.trim());
          final valid = _passphraseValid(controller.text.trim());
          return AlertDialog(
            icon: const Icon(Icons.vpn_key, color: Colors.blue, size: 40),
            title: const Text('Sync-Passphrase setzen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Gleiche Passphrase auf allen Geräten verwenden.'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  obscureText: true,
                  onChanged: (_) => setStateSB(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Passphrase',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Stärke: $strength',
                    style: TextStyle(
                      color: valid ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Passphrase wiederholen',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Mindestanforderung: ≥ 12 Zeichen, mind. 3 Zeichenklassen (Groß-/Kleinbuchstaben, Zahlen, Sonderzeichen).'),
                const SizedBox(height: 8),
                const Text('Hinweis: Nach dem Setzen werden lokale Daten neu verschlüsselt und in die Cloud neu hochgeladen.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () async {
                  final p1 = controller.text.trim();
                  final p2 = confirm.text.trim();
                  if (p1.isEmpty || p1 != p2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passphrases stimmen nicht überein'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  if (!_passphraseValid(p1)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passphrase erfüllt die Mindestanforderungen nicht'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  try {
                    await appProvider.secureStorageService.setSyncPassphrase(p1);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Sync-Passphrase gesetzt und Daten neu synchronisiert'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Setzen'),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _passphraseValid(String s) {
    if (s.length < 12) return false;
    final hasLower = RegExp(r'[a-z]').hasMatch(s);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(s);
    final hasDigit = RegExp(r'[0-9]').hasMatch(s);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(s);
    final classes = [hasLower, hasUpper, hasDigit, hasSpecial].where((v) => v).length;
    return classes >= 3;
  }

  String _passphraseStrength(String s) {
    int score = 0;
    if (s.length >= 12) score++;
    if (s.length >= 16) score++;
    if (s.length >= 20) score++;
    final hasLower = RegExp(r'[a-z]').hasMatch(s);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(s);
    final hasDigit = RegExp(r'[0-9]').hasMatch(s);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(s);
    score += [hasLower, hasUpper, hasDigit, hasSpecial].where((v) => v).length - 1; // 0..3
    if (score <= 1) return 'sehr schwach';
    if (score == 2) return 'schwach';
    if (score == 3) return 'mittel';
    if (score == 4) return 'stark';
    return 'sehr stark';
  }

  Widget _buildRechnungsstellerSection(AppProvider appProvider) {
    final s = appProvider.settings;
    final vollstaendig = s.organisationsName.isNotEmpty &&
        s.organisationsStrasse.isNotEmpty &&
        s.organisationsPlz.isNotEmpty &&
        s.organisationsOrt.isNotEmpty &&
        (s.organisationsUstId.isNotEmpty || s.organisationsSteuernr.isNotEmpty);
    return _buildSection(
      title: 'Rechnungssteller (fuer XRechnung)',
      icon: Icons.business_center,
      children: [
        ListTile(
          leading: Icon(
            vollstaendig ? Icons.check_circle : Icons.warning_amber,
            color: vollstaendig ? Colors.green : Colors.orange,
          ),
          title: Text(vollstaendig ? 'Stammdaten vollstaendig' : 'Stammdaten unvollstaendig'),
          subtitle: Text(
            vollstaendig
                ? '${s.organisationsName}, ${s.organisationsOrt}'
                : 'Bitte Pflichtfelder ergaenzen',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _bearbeiteRechnungssteller(appProvider),
        ),
      ],
    );
  }

  Future<void> _bearbeiteRechnungssteller(AppProvider app) async {
    final s = app.settings;
    final name = TextEditingController(text: s.organisationsName);
    final strasse = TextEditingController(text: s.organisationsStrasse);
    final plz = TextEditingController(text: s.organisationsPlz);
    final ort = TextEditingController(text: s.organisationsOrt);
    final ustId = TextEditingController(text: s.organisationsUstId);
    final steuernr = TextEditingController(text: s.organisationsSteuernr);
    final ik = TextEditingController(text: s.organisationsEinrichtungsIk);
    final iban = TextEditingController(text: s.organisationsIban);
    final bic = TextEditingController(text: s.organisationsBic);
    final kontoinh = TextEditingController(text: s.organisationsKontoinhaber);
    final email = TextEditingController(text: s.organisationsEmail);
    final tel = TextEditingController(text: s.organisationsTelefon);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechnungssteller-Daten'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _rsField(name, 'Firma / Traegername *', Icons.business),
                _rsField(strasse, 'Strasse und Hausnummer *', Icons.location_on),
                Row(children: [
                  Expanded(flex: 1, child: _rsField(plz, 'PLZ *', Icons.markunread_mailbox)),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: _rsField(ort, 'Ort *', Icons.location_city)),
                ]),
                const Divider(height: 24),
                _rsField(ustId, 'USt-ID (z.B. DE123456789)', Icons.tag),
                _rsField(steuernr, 'Steuernummer (falls keine USt-ID)', Icons.tag),
                _rsField(ik, 'Einrichtungs-IK (nur stationaer)', Icons.qr_code),
                const Divider(height: 24),
                _rsField(iban, 'IBAN', Icons.account_balance),
                _rsField(bic, 'BIC', Icons.account_balance),
                _rsField(kontoinh, 'Kontoinhaber', Icons.person),
                const Divider(height: 24),
                _rsField(email, 'E-Mail', Icons.email),
                _rsField(tel, 'Telefon', Icons.phone),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
        ],
      ),
    );
    if (saved != true) return;
    await app.updateSettings(s.copyWith(
      organisationsName: name.text.trim(),
      organisationsStrasse: strasse.text.trim(),
      organisationsPlz: plz.text.trim(),
      organisationsOrt: ort.text.trim(),
      organisationsUstId: ustId.text.trim(),
      organisationsSteuernr: steuernr.text.trim(),
      organisationsEinrichtungsIk: ik.text.trim(),
      organisationsIban: iban.text.trim(),
      organisationsBic: bic.text.trim(),
      organisationsKontoinhaber: kontoinh.text.trim(),
      organisationsEmail: email.text.trim(),
      organisationsTelefon: tel.text.trim(),
    ));
  }

  Widget _rsField(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildFLSSection(AppProvider appProvider) {
    final settings = appProvider.settings;

    return _buildSection(
      title: 'Fachleistungsstunden (Kalkulation)',
      icon: Icons.calculate,
      children: [
        ListTile(
          leading: const Icon(Icons.calculate, color: Colors.blue),
          title: const Text('Kalkulationsfaktor (nur informativ)'),
          subtitle: Text(
            'Aktuell: ${settings.kalkulationsfaktor.toStringAsFixed(2)}\n'
            'Fuer interne Personalplanung (Gesamt-/Kontaktzeit). '
            'KEIN Rechnungsfaktor - im Stundensatz bereits eingepreist.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showFLSEditDialog(
            appProvider,
            title: 'Kalkulationsfaktor',
            currentValue: settings.kalkulationsfaktor,
            hint: 'Berlin-typisch: 1,25–1,33 (NICHT in Rechnung!)',
            onSave: (value) => appProvider.updateSettings(
              settings.copyWith(kalkulationsfaktor: value),
            ),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.euro, color: Colors.green),
          title: const Text('Stundensatz (EUR)'),
          subtitle: Text(
            'Aktuell: ${settings.stundensatz.toStringAsFixed(2)} EUR\n'
            'Vergütung pro Fachleistungsstunde',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showFLSEditDialog(
            appProvider,
            title: 'Stundensatz (EUR)',
            currentValue: settings.stundensatz,
            hint: 'Berlin: 30–44 EUR je nach Qualifikation',
            onSave: (value) => appProvider.updateSettings(
              settings.copyWith(stundensatz: value),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Diese Werte gelten global. Pro Klient können sie im Stammblatt überschrieben werden.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFLSEditDialog(
    AppProvider appProvider, {
    required String title,
    required double currentValue,
    required String hint,
    required Future<bool> Function(double) onSave,
  }) {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: title,
                hintText: hint,
                border: const OutlineInputBorder(),
                helperText: hint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim().replaceAll(',', '.');
              final value = double.tryParse(text);
              if (value == null || value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bitte einen gültigen positiven Wert eingeben'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              final success = await onSave(value);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Gespeichert' : 'Fehler beim Speichern'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStorageSection() {
    return _buildSection(
      title: 'Lokale Dokumentenablage (DSGVO)',
      icon: Icons.folder_special,
      children: [
        // DSGVO-Hinweis
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Exportierte PDFs enthalten ggf. Gesundheitsdaten (Art. 9 DSGVO). Bitte nur auf verschlüsselten Geräten speichern und nach Bedarf löschen.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.folder_open, color: Colors.blue),
          title: const Text('Gespeicherte Dokumente'),
          subtitle: Text(_docsLoaded ? '${_storedDocs.length} Dokument(e) vorhanden' : 'Tippen zum Laden'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showDocumentListDialog(),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.auto_delete, color: Colors.red),
          title: const Text('Alte Dokumente löschen'),
          subtitle: const Text('Alle PDFs älter als 30 Tage entfernen'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAutoDeleteDialog(),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.folder, color: Colors.grey),
          title: const Text('Speicherort anzeigen'),
          subtitle: const Text('Pfad des Dokumentenordners'),
          trailing: const Icon(Icons.info_outline),
          onTap: () => _showStoragePathDialog(),
        ),
      ],
    );
  }

  Future<void> _showDocumentListDialog() async {
    final docs = await _docStorage.listDocuments();
    if (!mounted) return;
    setState(() {
      _storedDocs = docs;
      _docsLoaded = true;
    });
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          title: const Text('Gespeicherte Dokumente'),
          content: SizedBox(
            width: double.maxFinite,
            child: docs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Keine Dokumente vorhanden.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(doc.filename, style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          '${doc.sizeFormatted} · ${doc.createdAt.day}.${doc.createdAt.month}.${doc.createdAt.year}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            await _docStorage.deleteDocument(doc.fullPath);
                            final updated = await _docStorage.listDocuments();
                            setStateSB(() => docs
                              ..clear()
                              ..addAll(updated));
                            if (mounted) setState(() => _storedDocs = updated);
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAutoDeleteDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alte Dokumente löschen'),
        content: const Text(
          'Alle lokal gespeicherten PDF-Dokumente, die älter als 30 Tage sind, werden unwiderruflich gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final count = await _docStorage.deleteOlderThan(30);
              final updated = await _docStorage.listDocuments();
              if (mounted) {
                setState(() {
                  _storedDocs = updated;
                  _docsLoaded = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$count Dokument(e) gelöscht'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStoragePathDialog() async {
    try {
      final path = await _docStorage.getDocumentDirectoryPath();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Speicherort'),
          content: SelectableText(path, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStandorteSection(AppProvider appProvider) {
    final standorte = appProvider.standorte;
    final bueroStandort = appProvider.bueroStandort;
    final hasApiKey = appProvider.settings.openRouteServiceApiKey.isNotEmpty;

    return _buildSection(
      title: 'Standorte & Fahrwege',
      icon: Icons.directions_car,
      children: [
        // Erklärung
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('So funktioniert die Fahrweg-Erfassung',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Standorte anlegen (Büro, Klienten, Ämter)\n'
                  '2. Beim Termin oder Arbeitszeit "Fahrweg" auswählen\n'
                  '3. Distanz manuell eingeben oder per API berechnen\n'
                  '4. Berechnete km werden gecacht (nur einmal nötig)\n\n'
                  'Für die automatische Berechnung benötigen Sie einen kostenlosen API-Key von OpenRouteService.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // API-Key
        ListTile(
          leading: Icon(
            Icons.vpn_key,
            color: hasApiKey ? Colors.green : Colors.orange,
          ),
          title: const Text('OpenRouteService API-Key'),
          subtitle: Text(
            hasApiKey
                ? 'Konfiguriert - Online-Berechnung aktiv'
                : 'Nicht konfiguriert - nur manuelle km-Eingabe',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showApiKeyDialog(appProvider),
        ),
        const Divider(height: 1),
        // Standard-Büro
        ListTile(
          leading: const Icon(Icons.business),
          title: const Text('Standard-Büro'),
          subtitle: Text(bueroStandort?.name ?? 'Nicht festgelegt'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (standorte.where((s) => s.typ == StandortTyp.buero).isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bitte zuerst einen Büro-Standort anlegen')),
              );
              return;
            }
            _showBueroStandortDialog(appProvider);
          },
        ),
        const Divider(height: 1),
        // Standorte verwalten
        ListTile(
          leading: const Icon(Icons.place),
          title: Text('${standorte.length} Standorte verwalten'),
          subtitle: const Text('Büro, Klienten, Ämter'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const StandorteScreen(),
              ),
            );
          },
        ),
        const Divider(height: 1),
        // Strecken-Info
        ListTile(
          leading: const Icon(Icons.route),
          title: Text('${appProvider.streckenCache.length} Strecken im Cache'),
          subtitle: Text('${appProvider.totalKmDriven.toStringAsFixed(1)} km gefahren insgesamt'),
        ),
      ],
    );
  }

  void _showApiKeyDialog(AppProvider appProvider) {
    final controller = TextEditingController(text: appProvider.settings.openRouteServiceApiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OpenRouteService API-Key'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'So erhalten Sie einen kostenlosen API-Key:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Öffnen Sie openrouteservice.org\n'
                      '2. Erstellen Sie ein kostenloses Konto\n'
                      '3. Unter "Dashboard" → "Request a token"\n'
                      '4. Kopieren Sie den Key hierher\n\n'
                      'Kostenlos: 2.000 Berechnungen pro Tag',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API-Key',
                  hintText: 'z.B. 5b3ce3597851110001cf6248...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DSGVO: Es werden nur Adressen zur Berechnung übermittelt. '
                        'Gespeichert wird ausschließlich die km-Zahl.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          if (appProvider.settings.openRouteServiceApiKey.isNotEmpty)
            TextButton(
              onPressed: () {
                appProvider.updateSettings(
                  appProvider.settings.copyWith(openRouteServiceApiKey: ''),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API-Key entfernt')),
                );
              },
              child: const Text('Entfernen', style: TextStyle(color: Colors.red)),
            ),
          FilledButton(
            onPressed: () {
              final key = controller.text.trim();
              appProvider.updateSettings(
                appProvider.settings.copyWith(openRouteServiceApiKey: key),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(key.isNotEmpty
                    ? 'API-Key gespeichert - Online-Berechnung aktiv'
                    : 'API-Key entfernt')),
              );
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showBueroStandortDialog(AppProvider appProvider) {
    final bueroStandorte = appProvider.standorte.where((s) => s.typ == StandortTyp.buero).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Standard-Büro wählen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: bueroStandorte.map((s) => RadioListTile<String>(
            title: Text(s.name),
            value: s.id,
            groupValue: appProvider.settings.bueroStandortId,
            onChanged: (value) {
              appProvider.updateSettings(
                appProvider.settings.copyWith(bueroStandortId: value),
              );
              Navigator.pop(context);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, IconData? icon, bool initiallyExpanded = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: icon != null ? Icon(icon, color: Theme.of(context).colorScheme.primary) : null,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: EdgeInsets.zero,
        children: children,
      ),
    );
  }

  // Dialog-Funktionen

  void _showDeleteAllDataDialog(AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Daten löschen'),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden. Alle Klienten und Termine werden permanent gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteAllData(appProvider);
            },
            child: const Text('Alle Daten löschen'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(AppProvider appProvider) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Passwort ändern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              decoration: const InputDecoration(
                labelText: 'Aktuelles Passwort',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newController,
              decoration: const InputDecoration(
                labelText: 'Neues Passwort',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _changePassword(appProvider, currentController.text, newController.text);
            },
            child: const Text('Ändern'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden'),
        content: const Text('Möchten Sie sich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              appProvider.logout();
            },
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
  }

  void _showPasswordInputDialog(Function(String) onPassword) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup-Passwort'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Passwort eingeben',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                onPassword(controller.text.trim());
              }
            },
            child: const Text('Wiederherstellen'),
          ),
        ],
      ),
    );
  }

  void _showGDPRExportDialog() {
    showDialog(
      context: context,
      builder: (context) => _gdprService.buildExportDialog(context),
    );
  }

  void _showGDPRDeletionDialog() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _gdprService.buildDeletionDialog(
        context,
        onDeletionComplete: () async {
          await appProvider.clearAllData();
        },
      ),
    );
  }

  void _showHiDriveConfigDialog() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final settings = provider.settings;

    final usernameController = TextEditingController(text: settings.hidriveUsername);
    final passwordController = TextEditingController(text: settings.hidrivePassword);
    final organizationController = TextEditingController(text: settings.organizationId.isNotEmpty ? settings.organizationId : 'default');
    final rootSubController = TextEditingController(text: settings.rootSubdirectory);
    final teamController = TextEditingController(text: settings.teamId);
    bool adminMode = settings.teamId.isEmpty || settings.isAdmin;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
        icon: const Icon(Icons.cloud_queue, size: 48, color: Colors.orange),
        title: const Text('Cloud-Sync Multi-Team Konfiguration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Benutzername',
                  hintText: 'z.B. ihr-username@strato.de oder Nextcloud-User',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  hintText: 'Passwort des Cloud-Anbieters (HiDrive/Nextcloud)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: organizationController,
                decoration: const InputDecoration(
                  labelText: 'Organisation/Träger ID',
                  hintText: 'z.B. egh-mustertraeger',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                  helperText: 'Eindeutige ID für Ihren Träger/Organisation',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rootSubController,
                decoration: const InputDecoration(
                  labelText: 'Root‑Unterordner (optional)',
                  hintText: 'z. B. Gemeinsam/Eingliederungshilfe',
                  prefixIcon: Icon(Icons.folder),
                  border: OutlineInputBorder(),
                  helperText: 'Nur nutzen, wenn der Organisations‑Ordner als Freigabe unter einem Unterpfad gemountet ist.'
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Admin-Modus (ohne Team)'),
                subtitle: const Text('Organisation verwalten, Team-Feld bleibt leer'),
                value: adminMode,
                onChanged: (v) => setStateSB(() { adminMode = v; }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: teamController,
                enabled: !adminMode,
                decoration: const InputDecoration(
                  labelText: 'Team ID',
                  hintText: 'z.B. team-wohnen-nord',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                  helperText: 'Eindeutige ID für Ihr Team (leer im Admin-Modus)',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.groups, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Multi-Team Konfiguration',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Organisation: Eindeutige ID für Ihren Träger\n'
                      '• Team: Spezifische Team-ID (leer = Admin-Zugriff)\n'
                      '• Ordnerstruktur: /eingliederungshilfe/organizations/[org]/teams/[team]/\n'
                      '• Granulare Zugriffsrechte und DSGVO-konforme Datentrennung',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sicherheit & Compliance',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• WebDAV URL: https://webdav.hidrive.strato.com/users\n'
                      '• AES-256-GCM E2E-Verschlüsselung mit Certificate Pinning\n'
                      '• Deutsche Rechenzentren (DSGVO-konform)\n'
                      '• Zugangsdaten werden verschlüsselt gespeichert',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              final username = usernameController.text.trim();
              final password = passwordController.text.trim();
              final organizationId = organizationController.text.trim();
              final rootSub = rootSubController.text.trim();
              final teamId = adminMode ? '' : teamController.text.trim();

              if (username.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bitte Benutzername und Passwort eingeben'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (organizationId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bitte eine Organisation/Träger ID eingeben'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Zeige Loading-Indikator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Speichere Multi-Team Konfiguration...'),
                    ],
                  ),
                ),
              );

              try {
                // Settings mit neuen HiDrive-Zugangsdaten und Team-Konfiguration aktualisieren
                final updatedSettings = settings.copyWith(
                  hidriveUsername: username,
                  hidrivePassword: password,
                  organizationId: organizationId,
                  teamId: teamId,
                  isAdmin: adminMode,
                  rootSubdirectory: rootSub,
                );

                AppLogger.info('Settings', 'Versuche Multi-Team Settings zu speichern...');
                AppLogger.info('Settings', 'Username: $username, Password length: ${password.length}');
                AppLogger.info('Settings', 'Organization ID: $organizationId, Team ID: ${teamId.isEmpty ? 'Admin-Zugriff' : teamId}');

                final success = await provider.updateSettings(updatedSettings);

                AppLogger.info('Settings', 'Settings gespeichert: $success');
                AppLogger.info('Settings', 'Aktuelle Settings: organizationId="${provider.settings.organizationId}", teamId="${provider.settings.teamId}"');

                if (!context.mounted) return;
                // Schließe beide Dialoge
                Navigator.of(context).pop(); // Loading-Dialog
                Navigator.of(context).pop(); // HiDrive-Dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                      ? teamId.isEmpty
                        ? '✅ HiDrive Admin-Konfiguration gespeichert für Organisation: $organizationId'
                        : '✅ HiDrive Team-Konfiguration gespeichert für Team: $teamId'
                      : '❌ Fehler beim Speichern der Konfiguration'),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );

                // Nach erfolgreichem Speichern UI aktualisieren
                if (success && mounted) {
                  setState(() {});
                }

              } catch (e) {
                if (!context.mounted) return;
                // Schließe Loading-Dialog
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Fehler: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
                AppLogger.error('Settings', 'Exception beim Speichern', e);
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _triggerCloudSync() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 16),
            Text('Synchronisiere mit HiDrive...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      // Initialisiere Cloud-Sync mit aktuellen Einstellungen (Multi-Team)
      await provider.secureStorageService.initializeMultiTeamCloudSync(
        provider.settings,
      );

      // Zweirichtungs-Synchronisation: erst Pull, dann Push
      await provider.secureStorageService.syncFromCloud();
      final result = await provider.secureStorageService.syncToCloud();

      if (!mounted) return;
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Synchronisation erfolgreich abgeschlossen'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Synchronisation fehlgeschlagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Synchronisations-Fehler: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testHiDriveConnection() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final settings = provider.settings;

    // Prüfe, ob Zugangsdaten vorhanden sind
    if (settings.hidriveUsername.isEmpty || settings.hidrivePassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Bitte zuerst HiDrive-Zugangsdaten eingeben'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 16),
            Text('Teste HiDrive-Verbindung...'),
          ],
        ),
      ),
    );

    try {
      final client = HiDriveWebDAVClient(
        baseUrl: HiDriveConfig.buildWebDAVUrl(settings.hidriveUsername),
        username: settings.hidriveUsername,
        password: settings.hidrivePassword,
        certificatePins: HiDriveConfig.certificatePins,
      );
      final result = await client.testConnection();

      if (!mounted) return;
      if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cloud-Verbindung erfolgreich!'),
              backgroundColor: Colors.green,
            ),
          );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cloud-Verbindung fehlgeschlagen: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Verbindungsfehler: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAllData(AppProvider appProvider) async {
    await appProvider.clearAllData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alle Daten wurden gelöscht')),
      );
    }
  }

  Future<void> _changePassword(AppProvider appProvider, String currentPassword, String newPassword) async {
    // TODO: Implement password change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passwort-Änderung implementiert')),
    );
  }


  Future<void> _selectGDPRImportFile(AppProvider appProvider) async {
    // Pausiere Lifecycle-Monitoring während File-Picker Operation
    AppLifecycleService().pauseForFileOperation();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    // Wieder aktivieren nach File-Picker
    AppLifecycleService().resumeAfterFileOperation();

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final fileName = file.name;

      AppLogger.info('GDPR', 'Import: Ausgewählte Datei: $fileName');

      // Bestätigungsdialog anzeigen
      final shouldRestore = await _showGDPRImportConfirmationDialog(fileName);
      if (!shouldRestore || !mounted) return;

      // Verschlüsselung wird jetzt im GDPRService intelligent erkannt (Inhalt-basiert)
      // Hier nur noch eine einfache Heuristik als Fallback
      final nameBasedEncrypted = fileName.contains('.encrypted.json') || fileName.endsWith('.gdpr');

      // Für Dateien ohne Endung (wie "Datenexport gemäß Art. 20 DSGVO") nehmen wir an dass sie verschlüsselt sind
      final isEncrypted = nameBasedEncrypted || !fileName.contains('.');
      AppLogger.info('GDPR', 'Import: Vermutlich verschlüsselt: $isEncrypted (Dateiname-basiert)');

      // For mobile platforms, use file path if bytes are not available
      if (file.bytes != null) {
        // Web or file has bytes directly available
        final fileBytes = file.bytes!;
        if (isEncrypted) {
          _showPasswordInputDialog((password) {
            _restoreGDPRDataFromBytes(appProvider, fileBytes, fileName, password);
          });
        } else {
          _restoreGDPRDataFromBytes(appProvider, fileBytes, fileName, null);
        }
      } else if (file.path != null) {
        // Mobile platform with file path
        final filePath = file.path!;
        if (isEncrypted) {
          _showPasswordInputDialog((password) {
            _restoreGDPRDataFromFile(appProvider, filePath, password);
          });
        } else {
          _restoreGDPRDataFromFile(appProvider, filePath, null);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler: Datei konnte nicht gelesen werden'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showGDPRImportConfirmationDialog(String fileName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DSGVO-Daten wiederherstellen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Möchten Sie die DSGVO-Exportdatei "$fileName" wiederherstellen?'),
            const SizedBox(height: 16),
            const Text(
              'ACHTUNG: Alle aktuellen Daten werden vollständig überschrieben!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dies umfasst alle Klienten, Termine, Arbeitszeiten und Einstellungen.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vollständig wiederherstellen'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _restoreGDPRDataFromBytes(AppProvider appProvider, Uint8List fileBytes, String fileName, String? password) async {
    setState(() => _isLoading = true);

    try {
      // Use the new GDPRService import function
      final importResult = await _gdprService.importGDPRData(
        fileBytes: fileBytes,
        fileName: fileName,
        password: password,
      );

      if (importResult.isSuccess) {
        // Clear existing data first
        await appProvider.clearAllData();

        // Import clients
        for (final clientData in importResult.clients ?? []) {
          final client = Client.fromJson(clientData['data']);
          await appProvider.addClient(client);
        }

        // Import appointments
        for (final appointmentData in importResult.appointments ?? []) {
          final appointment = Appointment.fromJson(appointmentData['data']);
          await appProvider.addAppointment(appointment);
        }

        // Import arbeitszeiten
        for (final arbeitszeitData in importResult.arbeitszeiten ?? []) {
          final arbeitszeit = Arbeitszeit.fromJson(arbeitszeitData['data']);
          await appProvider.addArbeitszeit(arbeitszeit);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('DSGVO-Daten erfolgreich wiederhergestellt (${importResult.totalRecords} Datensätze)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import fehlgeschlagen: ${importResult.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreGDPRDataFromFile(AppProvider appProvider, String filePath, String? password) async {
    setState(() => _isLoading = true);

    try {
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      await _restoreGDPRDataFromBytes(appProvider, fileBytes, filePath.split('/').last, password);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Lesen der Datei: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

}
