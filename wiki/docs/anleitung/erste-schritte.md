# Erste Schritte

## Installation

Die App ist als Flutter-Anwendung verfuegbar und kann auf allen unterstuetzten Plattformen installiert werden.

## Ersteinrichtung

Beim ersten Start erscheint der **Einrichtungsassistent**. Es gibt zwei Pfade:

### Pfad A: Organisation einrichten (Admin)

Waehlen Sie diesen Pfad, wenn Sie die Organisation fuer Ihr Team aufsetzen.

1. **"Organisation einrichten"** waehlen
2. **Profil eingeben**: Vorname, Nachname, Berufsgruppe, Wochenarbeitszeit
3. **Speichermodus waehlen**:
    - *Nur lokal (verschluesselt)*: Alle Daten bleiben auf dem Geraet. AES-256 Verschluesselung. Kein Internet noetig.
    - *HiDrive Cloud-Sync*: Verschluesselt mit STRATO HiDrive synchronisiert. Fuer Teams und mehrere Geraete.
4. **HiDrive konfigurieren** (bei Cloud-Sync):
    - HiDrive Benutzername und Passwort eingeben
    - Organisations-ID vergeben (z.B. `meine-firma`)
    - Admin-Modus aktivieren
    - Verbindung testen
5. **App starten**

Nach dem Setup landen Sie im Dashboard. Als Admin erscheint zusaetzlich der **Verwaltung-Tab**.

### Pfad B: Einladungscode verwenden (Mitarbeiter)

Waehlen Sie diesen Pfad, wenn Sie einen QR-Code oder Token von Ihrem Admin erhalten haben.

1. **"Einladungscode verwenden"** waehlen
2. **Token einfuegen** (QR-Code scannen oder Text einfuegen)
3. **6-stelligen PIN eingeben** (erhalten Sie separat von Ihrem Admin)
4. Token wird entschluesselt -- HiDrive, Organisation, Team und Rolle werden automatisch konfiguriert
5. **Profil bestaetigen**: Vorname und Nachname eingeben
6. **App starten**

Sie haben sofort Zugriff auf die Daten Ihres Teams, ohne etwas manuell konfigurieren zu muessen.

### Pfad C: Nur lokal ohne Cloud

Auf der Willkommensseite koennen Sie auch "Nur lokal ohne Cloud nutzen" waehlen. In diesem Fall werden alle Daten ausschliesslich auf dem Geraet gespeichert.

## Anmeldung

Nach der Ersteinrichtung muessen Sie sich bei jedem App-Start authentifizieren:

- **Desktop/Mobil**: Biometrische Authentifizierung (Fingerabdruck, Face ID) oder Geraete-PIN
- **Web**: Benutzername und Passwort
- **Mit TOTP**: Wenn Zwei-Faktor-Authentifizierung aktiviert ist, wird zusaetzlich ein 6-stelliger Code aus der Authenticator-App abgefragt

## Navigation

Die App passt ihre Navigation an die Bildschirmgroesse an:

- **Desktop**: Navigationsleiste links (Rail) mit 10-11 Tabs
- **Tablet**: Navigationsdrawer (aufklappbar)
- **Mobil**: Untere Navigationsleiste mit 4 Haupttabs + "Mehr"-Menu

### Verfuegbare Bereiche

| Tab | Funktion |
|-----|----------|
| Dashboard | Uebersicht mit Statistiken und Schnellaktionen |
| Klienten | Klientenverwaltung und Stammdaten |
| Dokumentation | Dokumentationsuebersicht aller Termine |
| Arbeitszeit | Arbeitszeiterfassung nach Taetigkeiten |
| Kalender | Wochen- und Monatsansicht mit farbkodierten Klienten |
| Nachrichten | Internes Nachrichtensystem |
| Berichte | Informationsberichte und Auswertungen |
| Export | Datenexport (CSV, JSON, PDF) |
| Hilfe | In-App Hilfe und Dokumentation |
| Einstellungen | App-Konfiguration, Sicherheit, DSGVO |
| Verwaltung | Administration (nur fuer Admins sichtbar) |
