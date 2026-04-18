import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/responsive_utils.dart';

class HilfeScreen extends StatelessWidget {
  const HilfeScreen({super.key});

  static const String _wikiUrl = 'https://miri2577.github.io/FEGH-Dokumentation/';

  Future<void> _openWiki(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(_wikiUrl);
    bool ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      await Clipboard.setData(const ClipboardData(text: _wikiUrl));
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Browser konnte nicht geoeffnet werden - URL wurde in die Zwischenablage kopiert'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hilfe & Dokumentation'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ResponsiveUtils.adaptiveScaffoldBody(
        context: context,
        body: SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildWikiCta(context),
              const SizedBox(height: 16),
              _buildWelcomeSection(context),
              const SizedBox(height: 24),
              _buildQuickStartSection(context),
              const SizedBox(height: 24),
              _buildNavigationSection(context),
              const SizedBox(height: 24),
              _buildClientSection(context),
              const SizedBox(height: 24),
              _buildTerminSection(context),
              const SizedBox(height: 24),
              _buildWirkungsmessungSection(context),
              const SizedBox(height: 24),
              _buildFlsAbrechnungSection(context),
              const SizedBox(height: 24),
              _buildBundeslaenderSection(context),
              const SizedBox(height: 24),
              _buildTimeTrackingSection(context),
              const SizedBox(height: 24),
              _buildChatSection(context),
              const SizedBox(height: 24),
              _buildAdminSection(context),
              const SizedBox(height: 24),
              _buildSecuritySection(context),
              const SizedBox(height: 24),
              _buildExportSection(context),
              const SizedBox(height: 24),
              _buildTroubleshootingSection(context),
              const SizedBox(height: 24),
              _buildVersionSection(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWikiCta(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openWiki(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book,
                    color: theme.colorScheme.onPrimary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vollstaendiges Online-Wiki',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Umfassende Anleitungen, technische Dokumentation, DSGVO, '
                      'Sicherheitskonzept und mehr -- im Browser oeffnen.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _wikiUrl.replaceFirst('https://', ''),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _openWiki(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Oeffnen'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'URL in Zwischenablage kopieren',
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: _wikiUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wiki-URL in die Zwischenablage kopiert')),
                  );
                },
                icon: Icon(Icons.copy, color: theme.colorScheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility_new, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Willkommen zur FEGH-Dokumentation',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'FEGH-Dokumentation ist Ihre App fuer die digitale Eingliederungshilfe. '
              'Verwalten Sie Klienten, Termine, Arbeitszeiten und Berichte -- verschluesselt und DSGVO-konform. '
              'Kommunizieren Sie sicher ueber den integrierten Ende-zu-Ende verschluesselten Chat.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            _buildInfoBox(context, Icons.security, Colors.green,
              'Alle Daten sind mit AES-256-GCM verschluesselt. Chat-Nachrichten sind Ende-zu-Ende verschluesselt (Megolm).'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartSection(BuildContext context) {
    return _buildSection(context, 'Schnellstart', [
      _buildStepItem(context, '1', 'Ersteinrichtung',
        'Beim ersten Start: "Organisation einrichten" (Admin) oder "Einladungscode verwenden" (Mitarbeiter).'),
      _buildStepItem(context, '2', 'Klienten anlegen',
        'Im Klienten-Tab: Stammdaten, Kostenuebernahme, Fachleistungsstunden und TIB-Ziele erfassen.'),
      _buildStepItem(context, '3', 'Termine dokumentieren',
        'Ueber den "+"-Button: Klient, Datum, Uhrzeit, Terminart und Dokumentation erfassen.'),
      _buildStepItem(context, '4', 'Chat einrichten',
        'Im Nachrichten-Tab: Mit Matrix-Zugangsdaten anmelden fuer verschluesselten Team-Chat.'),
      _buildStepItem(context, '5', 'TOTP aktivieren (empfohlen)',
        'Einstellungen > Zugriffsstatus > "Einrichten" fuer Zwei-Faktor-Authentifizierung.'),
    ]);
  }

  Widget _buildNavigationSection(BuildContext context) {
    return _buildSection(context, 'Navigation', [
      _buildFeatureItem(context, Icons.dashboard, 'Dashboard',
        'Uebersicht mit Statistiken, Ampel-System fuer Fachleistungsstunden und Schnellaktionen'),
      _buildFeatureItem(context, Icons.people, 'Klienten',
        'Verwaltung aller Klienten mit Suche, FLS-Tracking und Stammdaten'),
      _buildFeatureItem(context, Icons.article, 'Dokumentation',
        'Chronologische Uebersicht aller Termin-Dokumentationen mit Volltextsuche'),
      _buildFeatureItem(context, Icons.access_time, 'Arbeitszeit',
        'Taetigkeitsbasierte Zeiterfassung mit Statistiken und Soll/Ist-Vergleich'),
      _buildFeatureItem(context, Icons.calendar_view_month, 'Kalender',
        'Wochen-/Monatsansicht mit farbkodierten Klienten (24 Farben)'),
      _buildFeatureItem(context, Icons.chat, 'Nachrichten',
        'Ende-zu-Ende verschluesselter Matrix-Chat mit Datei-Versand'),
      _buildFeatureItem(context, Icons.assessment, 'Berichte',
        'Informationsberichte (Berliner Formular 101) und Auswertungen'),
      _buildFeatureItem(context, Icons.file_download, 'Export',
        'Datenexport als PDF, CSV oder JSON'),
      _buildFeatureItem(context, Icons.settings, 'Einstellungen',
        'Profil, Cloud-Sync, Sicherheit, FLS-Kalkulation, DSGVO'),
      _buildFeatureItem(context, Icons.admin_panel_settings, 'Verwaltung (Admin)',
        'Teams, Mitarbeiter, Einladungen, Rollen -- nur fuer Admins sichtbar'),
    ]);
  }

  Widget _buildClientSection(BuildContext context) {
    return _buildSection(context, 'Klienten-Verwaltung', [
      _buildFeatureItem(context, Icons.person_add, 'Klient anlegen',
        'Stammdaten, Kostenuebernahme, Fachleistungsstunden, ICF-Bereiche. Teilhabeziele werden nach dem Speichern separat verwaltet'),
      _buildFeatureItem(context, Icons.calculate, 'FLS-Kalkulation',
        'Automatische Berechnung: Bewilligte vs. verbrauchte Stunden, Kalkulationsfaktor (1,33), Stundensatz (40 EUR)'),
      _buildFeatureItem(context, Icons.color_lens, 'Farbkodierung',
        'Jeder Klient kann eine eigene Farbe fuer den Kalender erhalten (24 Farben)'),
      _buildInfoBox(context, Icons.shield, Colors.orange,
        'Berechtigungen: Klienten anlegen koennen nur Teamleitungen und Admins. '
        'Mitarbeiter koennen Dokumentation bearbeiten, aber keine Stammdaten aendern.'),
    ]);
  }

  Widget _buildTerminSection(BuildContext context) {
    return _buildSection(context, 'Termine & Dokumentation', [
      _buildFeatureItem(context, Icons.event, 'Terminarten',
        '8 Typen: Kliententermin, Buero, Dokumentation, Supervision, Teamsitzung, Fortbildung, Fahrtzeit, Sonstige'),
      _buildFeatureItem(context, Icons.track_changes, 'Teilhabeziel-Verknuepfung',
        'Termine mit aktiven Teilhabezielen des Klienten verknuepfen und Zeitverteilung pro Ziel dokumentieren'),
      _buildFeatureItem(context, Icons.directions_car, 'Fahrwege',
        'Hin- und Rueckfahrt mit Start/Ziel und Kilometern. Distanz-Cache und optionale Online-Berechnung'),
      _buildFeatureItem(context, Icons.picture_as_pdf, 'Informationsbericht',
        'Berliner Formular 101 (137 Felder) mit 3 PDF-Export-Varianten. Entwuerfe speicherbar'),
    ]);
  }

  Widget _buildWirkungsmessungSection(BuildContext context) {
    return _buildSection(context, 'Wirkungsmessung (§128 SGB IX)', [
      _buildFeatureItem(context, Icons.flag, 'Teilhabeziele (SMART)',
        'Ziele nach SMART-Kriterien anlegen: Spezifisch, Messbar, Attraktiv, Realistisch, Terminiert. Mit ICF-Verknuepfung, Kategorie (Leit-/Teil-/Handlungsziel) und Prioritaet'),
      _buildFeatureItem(context, Icons.sentiment_satisfied, 'GAS-Messungen',
        'Goal Attainment Scaling: 5-Punkte-Skala von -2 (deutlich schlechter) bis +2 (deutlich besser). Baseline, Zwischenmessungen, Endmessung'),
      _buildFeatureItem(context, Icons.assessment, 'POS-Fragebogen',
        'Personal Outcomes Scale: 8 Lebensqualitaets-Domaenen (Selbstbestimmung, Teilhabe, Beziehungen, Rechte, Wohlbefinden...), 48 Items, max 144 Punkte'),
      _buildFeatureItem(context, Icons.insights, 'Wirkungs-Dashboard',
        'KPIs, GAS-Verlaufsdiagramm pro Ziel, POS-Netzdiagramm mit Baseline-vs-Aktuell-Vergleich'),
      _buildFeatureItem(context, Icons.picture_as_pdf, 'Wirksamkeitsbericht-PDF',
        'Automatischer Bericht mit allen Zielen, Messungen und POS-Entwicklung. Geeignet als Anlage fuer Kostentraeger und Hilfeplan-Konferenzen'),
      _buildFeatureItem(context, Icons.cloud_sync, 'Cloud-Sync (verschluesselt)',
        'Upload/Download aller Wirkungsdaten als verschluesselte Blobs. Funktioniert mit HiDrive, Nextcloud und anderen Providern'),
      _buildInfoBox(context, Icons.upgrade, Colors.amber,
        'Migration: Alte TIB-Ziele aus dem Klienten-Profil werden beim Oeffnen von "Teilhabeziele" zur Uebernahme angeboten. '
        'Einmal uebernommen, werden sie strukturiert nach SMART-Kriterien weitergepflegt.'),
      _buildInfoBox(context, Icons.gavel, Colors.blue,
        '§128 SGB IX (BTHG): Die Wirksamkeit der Eingliederungshilfe muss belegt werden. '
        'In Berlin ab 01.01.2027 durch den neuen Rahmenvertrag verbindlich geregelt.'),
    ]);
  }

  Widget _buildFlsAbrechnungSection(BuildContext context) {
    return _buildSection(context, 'Fachleistungsstunden und Abrechnung', [
      _buildFeatureItem(context, Icons.schedule, 'FLS aus Terminen',
        'Dauer in Minuten wird automatisch zu Fachleistungsstunden umgerechnet. Direkt + indirekte Termine (mit Klient-Verteilung) werden getrennt aggregiert'),
      _buildFeatureItem(context, Icons.event_repeat, 'Intervall-Budget',
        'FLS-Verbrauch pro Zeitraum (Woche/Monat/Jahr) - kein kumulativer Ueberlauf. Budget wird bei jedem Terminspeichern geprueft'),
      _buildFeatureItem(context, Icons.warning_amber, 'Budget-Warnung',
        'Warnung ab 90 % Kontingent, rote Warnung ab 100 %. Verhindert Ueberabrechnung und Regressrisiko'),
      _buildFeatureItem(context, Icons.receipt_long, 'XRechnung-Export',
        'UBL 2.1 / XRechnung 3.0 Format mit Leitweg-ID. Fuer OZG-RE oder PEPPOL. Steuerbefreiung §4 Nr. 16 h / 25 / 18 UStG waehlbar'),
      _buildFeatureItem(context, Icons.task_alt, 'Plausi-Check',
        'Vor Rechnungserstellung: Leitweg-ID, Aktenzeichen, Leistungstyp, Bewilligungsbescheid, Budget werden geprueft'),
      _buildFeatureItem(context, Icons.undo, 'Storno-Rechnung',
        'Stornorechnung mit negativen Betraegen, Verweis auf Original, automatischer Status-Wechsel'),
      _buildInfoBox(context, Icons.error_outline, Colors.orange,
        'Kalkulationsfaktor (z.B. 1,33) ist NUR INFORMATIV fuer die Personalplanung. '
        'Er wird NICHT auf Rechnungen angewendet - der Faktor ist bereits im Stundensatz '
        'aus der §125-Verguetungsvereinbarung eingepreist (Doppelberechnungs-Verbot).'),
      _buildInfoBox(context, Icons.gavel, Colors.blue,
        'E-Rechnungspflicht seit 01.01.2025 in Deutschland. B2G-Empfang zwingend '
        'als XRechnung. In Berlin Einreichung ueber OZG-RE (xrechnung.bund.de).'),
    ]);
  }

  Widget _buildBundeslaenderSection(BuildContext context) {
    return _buildSection(context, 'Bundeslaender und Bedarfsinstrumente', [
      _buildFeatureItem(context, Icons.map_outlined, 'Alle 16 Bundeslaender',
        'TIB (Berlin), BEI_NRW, BEI_BW, ITP (6 Laender), HMBV (HH+HB), B.E.Ni (NI), generisches ICF fuer BY/RLP/SL/SH'),
      _buildFeatureItem(context, Icons.category, 'Automatische Instrument-Auswahl',
        'Beim Anlegen von Teilhabezielen erscheinen die Lebensbereiche des richtigen Bundeslandes als Dropdown - mit ICF-Code (d1-d9) und Kurzbeschreibung'),
      _buildFeatureItem(context, Icons.swap_horiz, 'Bundesland aenderbar',
        'Einstellungen > Zugriffsstatus > Bundesland. Aenderung wirkt ab sofort, bereits erfasste Ziele bleiben erhalten'),
      _buildFeatureItem(context, Icons.description, 'Formular 101 (Berlin)',
        'Ausfuellen im offiziellen PDF mit 406 Feldern. Nur in Berlin verfuegbar - andere Laender haben keine ausfuellbaren Vordrucke'),
      _buildFeatureItem(context, Icons.folder_special, 'Amtliche Formulare-Uebersicht',
        'Unter Berichte > Amtliche Formulare: Blanko-PDFs (BEI_NRW, PiT Hessen) und Links zu Traegerportalen (PerSEH, ANLEI, LS-EH...)'),
      _buildInfoBox(context, Icons.gavel, Colors.blue,
        'Die laenderspezifischen Instrumente sind im Landesrahmenvertrag nach §131 SGB IX verbindlich. '
        'Die Wirksamkeitsmessung nach §128 SGB IX (GAS + POS) ist bundesweit gleich.'),
    ]);
  }

  Widget _buildTimeTrackingSection(BuildContext context) {
    return _buildSection(context, 'Arbeitszeit', [
      _buildFeatureItem(context, Icons.schedule, 'Zeiterfassung',
        'Start-/Endzeit mit automatischer Stundenberechnung nach 8 Taetigkeitstypen'),
      _buildFeatureItem(context, Icons.analytics, 'Statistiken',
        'Stunden heute/Woche/Monat, Verteilung nach Typ, Soll/Ist-Vergleich'),
      _buildFeatureItem(context, Icons.event_available, 'Urlaub & Freizeit',
        'Antraege fuer Urlaub, Freizeitausgleich, Sonderurlaub, Fortbildung, Krankmeldung'),
    ]);
  }

  Widget _buildChatSection(BuildContext context) {
    return _buildSection(context, 'Verschluesselter Chat', [
      _buildFeatureItem(context, Icons.lock, 'Ende-zu-Ende Verschluesselung',
        'Megolm-Protokoll (wie Signal/Threema). Der Server sieht nur verschluesselte Nachrichten'),
      _buildFeatureItem(context, Icons.group, 'Team-Raeume',
        'Grupenchats fuer Teams. Alle Raeume automatisch E2E-verschluesselt'),
      _buildFeatureItem(context, Icons.attach_file, 'Dateien senden',
        'Bilder und Dokumente verschluesselt im Chat teilen'),
      _buildFeatureItem(context, Icons.videocam, 'Video-/Audio-Anrufe',
        'Aktuell ueber Element Web, native Integration geplant'),
      _buildInfoBox(context, Icons.dns, Colors.blue,
        'Der Chat laeuft ueber einen eigenen Server in Deutschland. '
        'Keine Drittanbieter, keine Daten bei Google/Meta/Microsoft.'),
    ]);
  }

  Widget _buildAdminSection(BuildContext context) {
    return _buildSection(context, 'Administration', [
      _buildFeatureItem(context, Icons.business, 'Organisation einrichten',
        'HiDrive-Ordnerstruktur automatisch erstellen. Recovery-Key sicher aufbewahren!'),
      _buildFeatureItem(context, Icons.groups, 'Teams verwalten',
        'Teams erstellen mit automatischer HiDrive-Ordner- und Team-Key-Generierung'),
      _buildFeatureItem(context, Icons.qr_code, 'Mitarbeiter einladen',
        'QR-Code + 6-stelliger PIN. Token enthaelt alles fuer automatische Konfiguration'),
      _buildFeatureItem(context, Icons.assignment_ind, 'Klienten zuweisen',
        'Klienten verschluesselt in Team-Verzeichnisse auf HiDrive zuordnen'),
      _buildFeatureItem(context, Icons.chat, 'Chat-User anlegen',
        'Matrix-Chat-Accounts fuer Mitarbeiter erstellen'),
      _buildFeatureItem(context, Icons.lock_reset, 'Passwort-Recovery',
        'Recovery-Token fuer Mitarbeiter generieren (24h gueltig, PIN-verschluesselt)'),
      _buildInfoBox(context, Icons.shield, Colors.purple,
        'Rollen: Organisations-Admin, PV-Admin, Teamleitung, Mitarbeiter, Pruefer. '
        'Jede Rolle hat definierte Berechtigungen (siehe Einstellungen > Meine Berechtigungen).'),
    ]);
  }

  Widget _buildSecuritySection(BuildContext context) {
    return _buildSection(context, 'Sicherheit & Datenschutz', [
      _buildFeatureItem(context, Icons.enhanced_encryption, 'AES-256-GCM',
        'Envelope Encryption: Jeder Datensatz hat eigenen Schluessel (DEK), geschuetzt durch Master Key (MEK)'),
      _buildFeatureItem(context, Icons.security, 'TOTP 2FA',
        'Zeitbasierte Einmalpasswoerter (RFC 6238). Kompatibel mit Google/Microsoft Authenticator'),
      _buildFeatureItem(context, Icons.fingerprint, 'Biometrie',
        'Face ID, Touch ID, Windows Hello -- je nach Plattform'),
      _buildFeatureItem(context, Icons.timer, 'Session-Timeout',
        'Automatische Abmeldung nach 30 Minuten Inaktivitaet'),
      _buildFeatureItem(context, Icons.delete_forever, 'Sichere Loeschung',
        'Crypto-Erasure: Dateien werden mit Zufallsdaten ueberschrieben vor dem Loeschen'),
      _buildFeatureItem(context, Icons.history, 'Audit-Log',
        'Alle sicherheitsrelevanten Aktionen werden protokolliert (Login, Klient-Zugriff, Aenderungen)'),
      _buildInfoBox(context, Icons.gavel, Colors.red,
        'DSGVO-konform: Daten in Deutschland (eigener Server + HiDrive), '
        'Datenschutzfolgenabschaetzung (DSFA) vorhanden, Loeschkonzept implementiert.'),
    ]);
  }

  Widget _buildExportSection(BuildContext context) {
    return _buildSection(context, 'Export & Berichte', [
      _buildFeatureItem(context, Icons.picture_as_pdf, 'Informationsbericht (PDF)',
        '3 Varianten: Original-Formular (Syncfusion), Neuaufbau (PDF-Paket), App-Layout'),
      _buildFeatureItem(context, Icons.table_chart, 'Arbeitszeit-Export',
        'Monatsuebersicht als CSV oder JSON'),
      _buildFeatureItem(context, Icons.calculate, 'FLS-Bericht',
        'Fachleistungsstunden pro Klient mit Ampel-System'),
      _buildFeatureItem(context, Icons.privacy_tip, 'DSGVO-Export',
        'Vollstaendiger Datenexport nach Art. 20 DSGVO, optional passwortgeschuetzt'),
    ]);
  }

  Widget _buildTroubleshootingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Problembehandlung',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTroubleshootItem(context,
              'Kein Verwaltung-Tab sichtbar',
              'Der Tab erscheint nur fuer Admins. Pruefen Sie unter Einstellungen > Zugriffsstatus Ihre Rolle.'),
            _buildTroubleshootItem(context,
              'Chat-Anmeldung fehlgeschlagen',
              'Pruefen Sie Benutzername und Passwort. Der Admin muss Ihren Chat-Account zuerst anlegen.'),
            _buildTroubleshootItem(context,
              'HiDrive-Sync funktioniert nicht',
              'Pruefen Sie Ihre Internetverbindung und HiDrive-Zugangsdaten unter Einstellungen > Cloud-Sync.'),
            _buildTroubleshootItem(context,
              'TOTP-Code wird abgelehnt',
              'Pruefen Sie ob die Uhrzeit auf Ihrem Geraet korrekt ist. TOTP ist zeitbasiert (+-30 Sekunden Toleranz).'),
            _buildTroubleshootItem(context,
              'Passwort vergessen',
              'Wenden Sie sich an Ihre Teamleitung oder den Admin. Diese koennen einen Recovery-Token generieren.'),
            _buildTroubleshootItem(context,
              'Daten fehlen nach Geraetewechsel',
              'Stellen Sie sicher dass die gleiche Sync-Passphrase verwendet wird und HiDrive-Sync aktiv ist.'),
            const SizedBox(height: 12),
            _buildInfoBox(context, Icons.open_in_new, Colors.blue,
              'Ausfuehrliche Dokumentation im Online-Wiki: miri2577.github.io/FEGH-Dokumentation'),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('FEGH-Dokumentation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Version 0.2.0-beta.1',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Digitale Eingliederungshilfe-Dokumentation',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, String step, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(step,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc, style: Theme.of(context).textTheme.bodyMedium),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: Theme.of(context).textTheme.bodyMedium),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(BuildContext context, String problem, String solution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.help_outline, color: Theme.of(context).colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(problem,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(solution, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
