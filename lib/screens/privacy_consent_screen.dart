import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Datenschutzerklaerung die beim Erststart angezeigt wird.
/// Muss bestaetigt werden bevor die App Daten verarbeiten darf (Art. 13/14 DSGVO).
class PrivacyConsentScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const PrivacyConsentScreen({super.key, required this.onAccepted});

  static const String _consentKey = 'privacy_consent_accepted';
  static const String _consentDateKey = 'privacy_consent_date';

  static Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _scrolledToEnd = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge && _scrollController.position.pixels > 0) {
        setState(() => _scrolledToEnd = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrivacyConsentScreen._consentKey, true);
    await prefs.setString(PrivacyConsentScreen._consentDateKey, DateTime.now().toIso8601String());
    widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.privacy_tip, color: theme.colorScheme.primary, size: 32),
                  const SizedBox(width: 12),
                  Text('Datenschutzerklaerung',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Bitte lesen Sie die folgende Datenschutzerklaerung vollstaendig durch.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heading(theme, '1. Verantwortlicher'),
                        _body(theme, 'Der Verantwortliche fuer die Datenverarbeitung ist der Betreiber '
                          'dieser App-Instanz (Ihr Arbeitgeber / Ihre Organisation). '
                          'Kontaktdaten entnehmen Sie Ihrem Arbeitsvertrag.'),

                        _heading(theme, '2. Welche Daten werden verarbeitet?'),
                        _body(theme, 'Die App verarbeitet folgende personenbezogene Daten:\n\n'
                          'Klientendaten (Art. 9 DSGVO -- besondere Kategorien):\n'
                          '- Name, Geburtsdatum, Adresse, Kontaktdaten\n'
                          '- Gesundheitsdaten: ICF-Klassifikation, Teilhabeziele, Betreuungsbedarf\n'
                          '- Sozialdaten: Rechtsgrundlage, Kostenuebernahme, Hilfe-Typ\n'
                          '- Betreuungsdokumentation: Termine, Berichte, Zielerreichung\n\n'
                          'Mitarbeiterdaten:\n'
                          '- Name, E-Mail, Arbeitszeiten, Urlaubstage\n'
                          '- Authentifizierungsdaten (Passwort-Hash, TOTP-Secret)'),

                        _heading(theme, '3. Rechtsgrundlage'),
                        _body(theme, '- Art. 6 Abs. 1b DSGVO: Vertragserfuellung (Arbeitsvertrag, Betreuungsvertrag)\n'
                          '- Art. 6 Abs. 1c DSGVO: Rechtliche Verpflichtung (Dokumentationspflicht SGB IX)\n'
                          '- Art. 9 Abs. 2b DSGVO: Verarbeitung im Bereich Sozialrecht\n'
                          '- Art. 6 Abs. 1f DSGVO: Berechtigtes Interesse (IT-Sicherheit, Chat)'),

                        _heading(theme, '4. Speicherung und Verschluesselung'),
                        _body(theme, 'Alle Daten werden mit AES-256-GCM verschluesselt gespeichert.\n\n'
                          '- Lokal: Auf dem Geraet im OS-Keychain/Secure Storage\n'
                          '- Cloud (optional): STRATO HiDrive oder eigener Server, ausschliesslich in Deutschland\n'
                          '- Chat: Ende-zu-Ende verschluesselt (Megolm), eigener Server in Deutschland\n\n'
                          'Ohne Entschluesselungsschluessel sind die Daten nicht lesbar -- '
                          'auch nicht fuer den Cloud-Anbieter oder Server-Administrator.'),

                        _heading(theme, '5. Aufbewahrungsfristen'),
                        _body(theme, '- Betreuungsdokumentation: 10 Jahre nach Ende der Massnahme (SGB IX, AO §147)\n'
                          '- Abrechnungsunterlagen: 10 Jahre (AO §147)\n'
                          '- Arbeitszeiten: 2 Jahre (ArbZG §16)\n'
                          '- Personalakten: 3 Jahre nach Austritt (BGB §195)\n\n'
                          'Nach Ablauf der Fristen werden die Daten geloescht.'),

                        _heading(theme, '6. Ihre Rechte'),
                        _body(theme, 'Sie haben folgende Rechte:\n\n'
                          '- Art. 15: Auskunft ueber Ihre gespeicherten Daten\n'
                          '- Art. 16: Berichtigung unrichtiger Daten\n'
                          '- Art. 17: Loeschung Ihrer Daten ("Recht auf Vergessenwerden")\n'
                          '- Art. 18: Einschraenkung der Verarbeitung\n'
                          '- Art. 20: Datenportabilitaet (Export in maschinenlesbarem Format)\n'
                          '- Art. 21: Widerspruch gegen die Verarbeitung\n\n'
                          'Wenden Sie sich an Ihren Datenschutzbeauftragten oder Administrator.'),

                        _heading(theme, '7. Empfaenger der Daten'),
                        _body(theme, '- STRATO AG (HiDrive, nur verschluesselte Dateien) -- AVV vorhanden\n'
                          '- Keine weiteren Empfaenger\n'
                          '- Keine Uebermittlung in Drittlaender'),

                        _heading(theme, '8. Datensicherheit'),
                        _body(theme, '- AES-256-GCM Verschluesselung (Envelope Encryption)\n'
                          '- PBKDF2 Passwort-Hashing (100.000 Iterationen)\n'
                          '- Zwei-Faktor-Authentifizierung (TOTP, RFC 6238)\n'
                          '- Biometrische Authentifizierung (Face ID, Fingerabdruck)\n'
                          '- Session-Timeout nach 30 Minuten\n'
                          '- Sichere Loeschung (Ueberschreiben vor Loeschen)\n'
                          '- Audit-Logging aller Zugriffe'),

                        _heading(theme, '9. Kontakt'),
                        _body(theme, 'Bei Fragen zum Datenschutz wenden Sie sich an den '
                          'Datenschutzbeauftragten Ihrer Organisation.\n\n'
                          'Aufsichtsbehoerde: Berliner Beauftragte fuer Datenschutz und Informationsfreiheit'),

                        const SizedBox(height: 24),
                        Text('Stand: April 2026 | Version 0.2.0-beta.1',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_scrolledToEnd)
                Text('Bitte scrollen Sie bis zum Ende der Erklaerung',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _scrolledToEnd ? _accept : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Ich habe die Datenschutzerklaerung gelesen und akzeptiere sie'),
                ),
              ),
              const SizedBox(height: 8),
              Text('Sie koennen die App nur nach Zustimmung nutzen.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _body(ThemeData theme, String text) {
    return Text(text, style: theme.textTheme.bodyMedium);
  }
}
