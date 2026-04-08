import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class HilfeScreen extends StatelessWidget {
  const HilfeScreen({super.key});

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
              _buildWelcomeSection(context),
              const SizedBox(height: 24),
              _buildQuickStartSection(context),
              const SizedBox(height: 24),
              _buildNavigationSection(context),
              const SizedBox(height: 24),
              _buildTerminSection(context),
              const SizedBox(height: 24),
              _buildClientManagementSection(context),
              const SizedBox(height: 24),
              _buildTimeTrackingSection(context),
              const SizedBox(height: 24),
              _buildFahrwegeSection(context),
              const SizedBox(height: 24),
              _buildExportSection(context),
              const SizedBox(height: 24),
              _buildSettingsSection(context),
              const SizedBox(height: 24),
              _buildSecuritySection(context),
              const SizedBox(height: 24),
              _buildTroubleshootingSection(context),
              const SizedBox(height: 100),
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
                Icon(
                  Icons.waving_hand,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Willkommen zur FEGH-Dokumentation',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'FEGH-Dokumentation ist Ihre zentrale App zur Verwaltung von Klienten, Terminen, Arbeitszeiten, Fahrwegen und Berichten in der Eingliederungshilfe. Alle Daten werden lokal verschlüsselt gespeichert und optional mit HiDrive synchronisiert.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alle Daten sind mit AES-256-GCM verschlüsselt. Ohne Cloud-Anbindung bleiben alle Daten ausschließlich auf Ihrem Gerät.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schnellstart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStepItem(
              context,
              '1',
              'Ersteinrichtung abschließen',
              'Beim ersten Start führt Sie der Einrichtungs-Assistent durch die Grundkonfiguration: Name, Speichermodus und optionale Cloud-Anbindung.',
            ),
            _buildStepItem(
              context,
              '2',
              'Klienten anlegen',
              'Legen Sie Ihre Klienten mit Stammdaten an: Name, Adresse, Rechtsgrundlage, Kostenträger und Betreuungszeitraum.',
            ),
            _buildStepItem(
              context,
              '3',
              'Termine dokumentieren',
              'Erstellen Sie Termine für Ihre Klienten mit Datum, Uhrzeit, Leistungsart und optionaler Fahrweg-Dokumentation.',
            ),
            _buildStepItem(
              context,
              '4',
              'Arbeitszeiten erfassen',
              'Dokumentieren Sie Ihre täglichen Arbeitszeiten nach Typ (Klientenarbeit, Fahrt, Büro, etc.) im Arbeitszeit-Tab.',
            ),
            _buildStepItem(
              context,
              '5',
              'Standorte einrichten (optional)',
              'Für die km-Erfassung: Legen Sie unter Einstellungen > Standorte Ihr Büro und häufige Ziele an.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Navigation & Bedienung',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.dashboard,
              'Dashboard (Startseite)',
              'Übersicht mit Kalender, Statistiken, Quick-Actions und heutigen Terminen',
            ),
            _buildFeatureItem(
              context,
              Icons.people,
              'Klienten-Tab',
              'Verwaltung aller Klienten mit Suche, Filter und Stammblatt-Zugang',
            ),
            _buildFeatureItem(
              context,
              Icons.access_time,
              'Arbeitszeit-Tab',
              'Zeiterfassung, Fahrwege-Statistik und Freizeit-/Urlaubsanträge',
            ),
            _buildFeatureItem(
              context,
              Icons.help,
              'Hilfe-Tab',
              'Diese Dokumentation mit Anleitungen und Problemlösungen',
            ),
            _buildFeatureItem(
              context,
              Icons.settings,
              'Einstellungen',
              'Über das Zahnrad-Symbol erreichbar: Profil, Standorte, Cloud-Sync, Export und mehr',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termin-Dokumentation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.event,
              'Termin erstellen',
              'Über Quick-Action oder Klienten-Detail: Datum, Uhrzeit, Dauer und Leistungsart erfassen',
            ),
            _buildFeatureItem(
              context,
              Icons.description,
              'Dokumentation',
              'Freitext-Dokumentation zu jedem Termin mit optionaler ICF-Bereich-Zuordnung',
            ),
            _buildFeatureItem(
              context,
              Icons.directions_car,
              'Fahrweg dokumentieren',
              'Optional: Start- und Zielstandort mit km-Angabe beim Termin erfassen',
            ),
            _buildFeatureItem(
              context,
              Icons.calendar_month,
              'Kalender-Integration',
              'Alle Termine erscheinen im Dashboard-Kalender mit farblicher Markierung',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tipp: Beim Erstellen eines Termins können Sie die Fahrweg-Section aufklappen, um Hin- und Rückfahrt direkt mitzudokumentieren.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientManagementSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Klienten-Verwaltung',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.person_add,
              'Klient anlegen',
              'Stammdaten erfassen: Name, Adresse, Geburtsdatum, Kontaktdaten',
            ),
            _buildFeatureItem(
              context,
              Icons.gavel,
              'Rechtsgrundlage & Kostenträger',
              'SGB-Paragraphen und Berliner Kostenträger (Jugendamt, Sozialamt, Krankenkasse etc.) zuweisen',
            ),
            _buildFeatureItem(
              context,
              Icons.date_range,
              'Betreuungszeitraum',
              'Von-Bis-Datum und Kostenübernahme-Zeitraum dokumentieren',
            ),
            _buildFeatureItem(
              context,
              Icons.article,
              'Informationsbericht',
              'Strukturierten Bericht erstellen und als PDF exportieren (Berliner Amtsformular)',
            ),
            const SizedBox(height: 12),
            Text(
              'Klienten-Stammblatt:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Name, Adresse, Telefon, E-Mail\n'
              '• Geburtsdatum mit automatischer Altersberechnung\n'
              '• Rechtsgrundlage (SGB-Paragraphen gruppiert)\n'
              '• Kostenträger (Berliner Bezirke, Krankenkassen etc.)\n'
              '• Betreuungszeitraum und Kostenübernahme\n'
              '• Freitext-Notizen',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTrackingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arbeitszeit-Erfassung',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.schedule,
              'Tägliche Zeiterfassung',
              'Start- und Endzeit mit automatischer Stundenberechnung',
            ),
            _buildFeatureItem(
              context,
              Icons.category,
              'Arbeitszeit-Typen',
              'Klientenarbeit, Fahrt, Büro, Fortbildung, Supervision und weitere',
            ),
            _buildFeatureItem(
              context,
              Icons.analytics,
              'Statistiken',
              'Übersicht: Stunden heute/Woche/Monat, Überstunden, gefahrene km',
            ),
            _buildFeatureItem(
              context,
              Icons.event_available,
              'Freizeit beantragen',
              'Urlaub, Freizeitausgleich, Sonderurlaub, Fortbildung oder Krankmeldung',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bei Arbeitszeit-Typ "Fahrt" können Sie direkt einen Fahrweg mit Start/Ziel und km-Angabe dokumentieren.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFahrwegeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fahrwege & Standorte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.location_on,
              'Standorte verwalten',
              'Einstellungen > Standorte & Fahrwege: Büro, Klienten-Standorte und Ämter anlegen',
            ),
            _buildFeatureItem(
              context,
              Icons.directions_car,
              'Fahrten erfassen',
              'Start- und Zielstandort auswählen, km werden automatisch aus dem Cache geladen',
            ),
            _buildFeatureItem(
              context,
              Icons.cached,
              'Strecken-Cache',
              'Einmal berechnete oder eingegebene Distanzen werden gespeichert und beim nächsten Mal automatisch vorgeschlagen',
            ),
            _buildFeatureItem(
              context,
              Icons.swap_horiz,
              'Rückfahrt',
              'Mit einem Klick "Rückfahrt gleich" aktivieren, um die Gegenrichtung mitzuerfassen',
            ),
            const SizedBox(height: 16),
            Text(
              'Distanz berechnen (optional):',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Die km-Distanz zwischen zwei Standorten kann auf drei Arten ermittelt werden:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            _buildStepItem(
              context,
              '1',
              'Manuell eingeben',
              'Geben Sie die km-Zahl direkt ins Distanz-Feld ein. Kein API-Key erforderlich.',
            ),
            _buildStepItem(
              context,
              '2',
              'Aus dem Cache laden',
              'Wenn die Strecke schon einmal erfasst wurde, wird die Distanz automatisch vorgeschlagen.',
            ),
            _buildStepItem(
              context,
              '3',
              'Online berechnen lassen',
              'Mit einem OpenRouteService API-Key können Sie Distanzen automatisch per Routing berechnen lassen.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.key, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'API-Key einrichten (optional)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Besuchen Sie openrouteservice.org und erstellen Sie ein kostenloses Konto\n'
                    '2. Nach der Anmeldung finden Sie unter "Tokens" Ihren API-Key\n'
                    '3. Kopieren Sie den Key und fügen Sie ihn unter Einstellungen > Standorte & Fahrwege > API-Key ein\n'
                    '4. Das kostenlose Kontingent umfasst 2.000 Anfragen pro Tag',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DSGVO-konform: Adressen werden nur einmalig für die Berechnung verwendet und nicht gespeichert. Es wird ausschließlich die km-Zahl im Cache abgelegt.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export & Berichte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.picture_as_pdf,
              'Informationsbericht (PDF)',
              'Strukturierter Bericht im Berliner Amtsformular-Format mit allen Klientendaten',
            ),
            _buildFeatureItem(
              context,
              Icons.table_chart,
              'Arbeitszeit-Export',
              'Monatsübersicht der Arbeitszeiten als teilbares Dokument',
            ),
            _buildFeatureItem(
              context,
              Icons.directions_car,
              'Fahrwege-Export',
              'Km-Aufstellung für Fahrtkostenerstattung mit Datum, Start, Ziel und km pro Klient',
            ),
            _buildFeatureItem(
              context,
              Icons.people,
              'Klienten-Export',
              'Übersicht aller Klienten mit Stammdaten',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tipp: Der Fahrwege-Export eignet sich ideal zur Vorlage beim Arbeitgeber für die monatliche Fahrtkostenerstattung.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Einstellungen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.person,
              'Benutzerprofil',
              'Name, Wochenarbeitszeit und Urlaubstage konfigurieren',
            ),
            _buildFeatureItem(
              context,
              Icons.location_on,
              'Standorte & Fahrwege',
              'Büro-Standort festlegen, Standorte verwalten, API-Key konfigurieren',
            ),
            _buildFeatureItem(
              context,
              Icons.cloud_sync,
              'Cloud-Synchronisation',
              'HiDrive-Zugangsdaten und Sync-Einstellungen für geräteübergreifende Nutzung',
            ),
            _buildFeatureItem(
              context,
              Icons.palette,
              'Darstellung',
              'UI-Anpassungen: Informationsdichte, Farbschema und Dark Mode',
            ),
            _buildFeatureItem(
              context,
              Icons.calculate,
              'Kalkulation',
              'Kalkulationsfaktor (KLE-Faktor) und Stundensatz für Abrechnungen',
            ),
            _buildFeatureItem(
              context,
              Icons.download,
              'Export',
              'Daten als PDF, CSV oder Markdown exportieren und teilen',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sicherheit & Datenschutz',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              context,
              Icons.lock,
              'AES-256-GCM Verschlüsselung',
              'Alle Daten werden lokal mit höchsten Sicherheitsstandards verschlüsselt',
            ),
            _buildFeatureItem(
              context,
              Icons.storage,
              'Lokale Speicherung',
              'Ohne Cloud-Anbindung verbleiben alle Daten ausschließlich auf Ihrem Gerät',
            ),
            _buildFeatureItem(
              context,
              Icons.cloud_sync,
              'Optionale Cloud-Sync',
              'Verschlüsselte Synchronisation über HiDrive WebDAV (nur mit Passphrase)',
            ),
            _buildFeatureItem(
              context,
              Icons.privacy_tip,
              'DSGVO-konform',
              'Datensparsamkeit, keine GPS-Ortung, keine Adressen-Speicherung bei Fahrwegen',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wichtig: Bewahren Sie Ihre Sync-Passphrase sicher auf. Ohne sie kann nicht auf die Cloud-Daten zugegriffen werden.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Problembehandlung',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTroubleshootingItem(
              context,
              'Distanzberechnung funktioniert nicht',
              'Prüfen Sie unter Einstellungen > Standorte & Fahrwege, ob ein gültiger API-Key hinterlegt ist. Alternativ können Sie km immer manuell eingeben.',
            ),
            _buildTroubleshootingItem(
              context,
              'Strecke wird nicht aus dem Cache geladen',
              'Der Cache speichert Strecken bidirektional. Stellen Sie sicher, dass Start und Ziel korrekt ausgewählt sind.',
            ),
            _buildTroubleshootingItem(
              context,
              'Synchronisation funktioniert nicht',
              'Prüfen Sie Ihre Internetverbindung und die HiDrive-Zugangsdaten unter Einstellungen > Cloud-Synchronisation.',
            ),
            _buildTroubleshootingItem(
              context,
              'Daten fehlen nach Geräte-Wechsel',
              'Stellen Sie sicher, dass auf beiden Geräten die gleiche Sync-Passphrase verwendet wird.',
            ),
            _buildTroubleshootingItem(
              context,
              'Export enthält keine Fahrwege',
              'Fahrwege müssen zuerst über Termine oder den Arbeitszeit-Tab erfasst werden, bevor sie im Export erscheinen.',
            ),
            _buildTroubleshootingItem(
              context,
              'Fehler beim Speichern',
              'Überprüfen Sie alle Pflichtfelder (rot markiert) und versuchen Sie es erneut.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.support_agent,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bei weiteren Problemen wenden Sie sich an Ihren IT-Administrator.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingItem(BuildContext context, String problem, String solution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  problem,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              solution,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
