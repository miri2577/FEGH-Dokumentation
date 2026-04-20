# Erste Schritte

## Funktionsweise im Detail

### Zwei verschiedene Einstiege — warum?

FEGH-Dokumentation bedient zwei Rollen, die **unterschiedliche
Einstiegspunkte** brauchen:

1. **Admin / Einrichtungsleitung** baut die Organisation neu auf —
   wird einmalig gemacht, dauert typisch 15 Minuten.
2. **Mitarbeiter** bekommen einen **Einladungscode** und sind in 60
   Sekunden einsatzfaehig — ohne jemals Cloud-Zugangsdaten zu sehen.

Ohne diese Trennung wuerden 50 Mitarbeiter 50 Mal Cloud-Logins
eintippen, 50 Mal "Organisations-ID" setzen, 50 Mal Fehler machen.
Mit dem Einladungscode laden sie ihre **komplette Konfiguration**
aus einem verschluesselten QR-Code.

### Konkretes Szenario: Team-Setup einer neuen Einrichtung

**Montag 09:00 — Einrichtungsleitung Dora startet mit einem leeren
Tablet.**

1. App installieren, oeffnen.
2. **"Organisation einrichten"** waehlen.
3. Ihr Profil: Dora Schmitt, Sozialarbeiterin, 40 h/Woche.
4. Speichermodus: **Cloud-Sync** (fuer Team-Betrieb noetig). Sie
   entscheidet sich fuer HiDrive als Provider — moeglich waeren auch
   Nextcloud, ownCloud oder ein selbst betriebener WebDAV-Server.
5. Cloud-Credentials aus dem Provider-Kundenportal eingeben
   (bei HiDrive das dedizierte App-Passwort, bei Nextcloud/ownCloud
   ein Application Token).
6. Organisations-ID vergeben: `assistenz-ggmbh`.
7. Admin-Modus aktiviert.
8. "Verbindung testen" → gruener Haken → App startet mit Dashboard +
   zusaetzlichem Verwaltung-Tab.

**Was im Hintergrund passiert:**
- Die App erzeugt im Cloud-Speicher die komplette Ordnerstruktur
  (`/eingliederungshilfe/organizations/assistenz-ggmbh/...`).
- Ein **Master Encryption Key** (MEK) wird generiert und
  verschluesselt in die Cloud geschrieben.
- Doras Geraet erhaelt einen **Data Encryption Key** (DEK), der
  aus ihrem Login abgeleitet ist.
- **Recovery-Codes** werden erzeugt — Dora wird aufgefordert, sie
  auszudrucken.

**Montag 10:30 — Dora laedt 5 Mitarbeiter ein.**

1. `Verwaltung → Mitarbeiter einladen`
2. Fuer jeden Mitarbeiter: Name eingeben, Rolle waehlen, Team
   zuweisen.
3. System erzeugt pro Mitarbeiter einen **Provisioning-Token**:
   ein kurzer Base64-String mit allen noetigen Konfig-Daten
   (Cloud-App-Passwort, Org-ID, Team-ID, Team-Key, Rolle).
4. Token wird **mit einer 6-stelligen PIN verschluesselt** (PBKDF2
   aus der PIN), als **QR-Code** angezeigt.
5. Dora gibt jedem Mitarbeiter:
   - den QR-Code (am Bildschirm, ausgedruckt oder per beA)
   - die PIN (muendlich oder separat — getrennt vom QR transportiert)

**Montag 14:00 — Mitarbeiter Sven installiert die App auf seinem
Tablet.**

1. App starten, **"Einladungscode verwenden"**.
2. QR-Code mit Kamera scannen — Token landet in der App (noch
   verschluesselt).
3. PIN eingeben: Token wird lokal entschluesselt, Konfig extrahiert.
4. Cloud-Zugang, Organisation, Team, Rolle sind **automatisch**
   gesetzt.
5. Sven bestaetigt sein Profil (Vorname, Nachname).
6. App startet → er sieht Dashboard mit den Klienten seines Teams.

**Kritisch**: Sven hat Cloud-Credentials nie gesehen oder getippt.
Wenn er morgen ausscheidet, kann Dora im Cloud-Kundenportal einfach
das App-Passwort rotieren — alle Tokens werden wertlos, und Sven hat
keinen Zugang mehr, ohne dass er die Daten explizit loeschen muss.

### Die Entscheidung: Nur lokal vs. Cloud-Sync

Der Setup-Wizard bietet zwei Speichermodi:

| Modus | Geeignet fuer | Was funktioniert nicht |
|-------|---------------|-------------------------|
| **Nur lokal** | Einzelplatz, kein Team, offline-only | Kein Team-Chat, keine Multi-Geraete-Akten, keine Verwaltungs-App-Anbindung |
| **Cloud-Sync** (HiDrive, Nextcloud, ownCloud, generisches WebDAV) | Team, mehrere Geraete, Kombination Doku+Verwaltung | Abo / eigene Server-Infrastruktur noetig |

Der Wechsel von "Nur lokal" nach Cloud-Sync ist **nachtraeglich moeglich**
(Einstellungen → Cloud), der Wechsel zurueck erfordert einen Export
und Neu-Setup.

### Was gepruefte Ersteinrichtung ausmacht

Das Team ist voll einsatzfaehig, wenn:

- **Dashboard** zeigt mindestens einen Test-Klient
- **Termine** laesst sich anlegen und speichern
- **Berichte → Empfaenger** hat mindestens einen Kostentraeger
  (Fallnummer-Basis)
- **Einstellungen → Bundesland** ist gesetzt (sonst funktionieren
  Zielkategorien nicht)
- **Einstellungen → FLS-Kalkulation** hat einen plausiblen
  Stundensatz
- **Cloud-Sync** hat einen erfolgreichen Testlauf gemacht

Erst dann lohnt sich der **Import bestehender Klienten** oder das
produktive Eintippen von Daten.

### Rechtlicher Hintergrund

- **Art. 32 DSGVO** — Sicherheit der Verarbeitung. Ersteinrichtung
  muss dokumentiert nachweisen koennen, dass Schluesselmaterial
  sicher generiert und gespeichert wurde.
- **Art. 30 DSGVO** — Verzeichnis der Verarbeitungstaetigkeiten.
  Vor produktivem Einsatz sollte die Einrichtung dokumentieren,
  welche Datenarten in welchen Modulen verarbeitet werden.
- **Art. 35 DSGVO** — Datenschutz-Folgenabschaetzung. Bei
  Verarbeitung von Gesundheitsdaten (Art. 9) zwingend — das
  Wiki-Kapitel [DSFA](../sicherheit/dsfa.md) in der Verwaltungs-
  App bietet eine Vorlage.

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
    - *Cloud-Sync*: Verschluesselt mit einem WebDAV-Provider
      (HiDrive, Nextcloud, ownCloud oder generisch) synchronisiert.
      Fuer Teams und mehrere Geraete.
4. **Cloud konfigurieren** (bei Cloud-Sync):
    - Provider-Typ waehlen und Benutzername + App-Passwort eingeben
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
4. Token wird entschluesselt -- Cloud, Organisation, Team und Rolle werden automatisch konfiguriert
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
