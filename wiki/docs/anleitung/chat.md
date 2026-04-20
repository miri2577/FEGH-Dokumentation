# Chat (Team-Kommunikation)

## Ueberblick

Der eingebaute Chat ermoeglicht Team-Kommunikation innerhalb der FEGH-Apps ohne externe Messenger. Nachrichten laufen ueber einen selbst gehosteten Matrix-Server (Conduit) und sind **Ende-zu-Ende verschluesselt**. Weder der Serverbetreiber noch Anbieter der Cloud-Infrastruktur koennen die Inhalte mitlesen.

!!! note "Berechtigung"
    Chat-Zugang haben alle angemeldeten Team-Mitglieder. Raeume anlegen und verwalten duerfen Admin und Teamleitung.

## Funktionsweise im Detail

### Das Problem, das wir loesen

In jeder Pflege-/Betreuungseinrichtung lebt eine parallele Shadow-
IT: WhatsApp-Gruppen, SMS-Ketten, private Mail-Adressen. Spontane
Kommunikation ist notwendig — ein Klient ist im Krankenhaus, der
Nachtdienst muss informiert werden, die Fruehschicht braucht einen
Hinweis zur Wochenendruhe.

Das ist rechtlich ein **akutes DSGVO-Problem**:

- Art. 9 DSGVO verbietet die Verarbeitung von Gesundheitsdaten
  ueber Dienste wie WhatsApp **ohne geeignete Garantien**
  (Auftragsverarbeitungsvertrag, EU-Serverstandort, etc.).
- Cloud-Messenger wie WhatsApp, Slack oder Teams haben mindestens
  Metadaten-Zugriff (wer mit wem, wann, wie oft) — das ist schon
  ein Datenschutzverstoss, wenn darauf Rueckschluesse auf Betreute
  moeglich sind ("Team Haupstrasse" + 15 Mitarbeiter = Einrichtung
  identifizierbar).
- Pruefungen durch Aufsichtsbehoerden (LfDI) pruefen genau diese
  Schatten-Kanaele.

Die App loest das mit einem **eigenen Matrix-Chat** (Conduit-Server,
E2E-verschluesselt), der:

- In der dienstlichen Infrastruktur lebt (keine US-Cloud)
- Ende-zu-Ende verschluesselt ist (weder wir noch Betreiber sehen
  Inhalte)
- Offener Standard ist (Matrix), nicht vendor-locked
- Ausscheidende Mitarbeiter zuverlaessig aus allen Kanaelen entfernt

### Konkretes Szenario: Nacht mit Komplikation

**23:45 Uhr — Nachtdienst Nadine bemerkt Auffaelligkeit.**

Herr P. (Klient, lebt in der WG) ist seit 20 Minuten im Bad
eingeschlossen und antwortet nicht auf Ansprache. Nadine hat zwei
Optionen:

- **Akuter Fall**: 112 rufen (klar)
- **Unklar, aber beunruhigend**: Rueckfrage bei Teamleitung oder
  erfahrenen Kollegen

Sie tippt im Klienten-Raum von Herrn P.:

> "Herr P. seit 20 min im Bad, keine Reaktion. Keine Geraeusche.
> Wer hat Erfahrung mit solchen Phasen?"

**23:46 Uhr** — Teamleitung Karin (Bereitschaftsdienst, Handy)
und Kollege Jonas (in der Spaetschicht einer anderen WG) sehen die
Nachricht auf ihren Geraeten. Der Matrix-Server leitet die Nachricht
verschluesselt an beide Geraete aus — entschluesselt wird sie nur
auf ihren Tablets.

**23:48 Uhr** — Karin antwortet: "Ist das die bekannte Rueckzugs-
phase? Ruhe lassen, 30 min warten, dann sanft ansprechen. Bei
weiterer Eskalation: 112." Jonas: "Gestern Abend hat er das auch
gemacht, war nach 40 min wieder raus."

Nadine entspannt, folgt dem Hinweis, notiert spaeter im regulaeren
Verlaufsbericht.

**Kritisch an dieser Situation ist**: Die Kommunikation laeuft
ausschliesslich zwischen drei verifizierten Mitarbeitern. Der
Matrix-Server sieht, dass drei Geraete in einem Raum sind — aber
nicht, welches Klientenzimmer gemeint ist, nicht welche Symptome
beschrieben werden. Selbst wenn der Server kompromittiert wuerde,
bleibt der Inhalt verschluesselt.

### Was genau passiert kryptographisch

Der Chat nutzt das **Matrix-Protokoll** mit Olm/Megolm-
Verschluesselung:

1. **Beim Setup**: Jedes Geraet erzeugt einen **Geraeteschluessel**
   (Public/Private Pair). Der Public Key wird am Server registriert,
   der Private Key bleibt lokal.
2. **Beim Raum-Beitritt**: Fuer jeden Raum wird ein
   **Gruppenschluessel** (Megolm) generiert und mit dem Public Key
   jedes Mitglieds verschluesselt verteilt.
3. **Beim Senden**: Die Nachricht wird mit dem Gruppenschluessel
   verschluesselt; der Server sieht nur Zeichenbrei.
4. **Beim Empfang**: Jeder Mitgliedsschluessel entschluesselt mit
   dem Gruppenschluessel; der Server hat zu keinem Zeitpunkt den
   Klartext.
5. **Bei Mitglieder-Aenderung** (Austritt): Der Gruppenschluessel wird
   **rotiert** — neue Nachrichten sind fuer den Ex-Mitglied nicht
   mehr lesbar.
6. **Schluesselverifizierung**: Beim ersten Kontakt zweier Mitarbeiter
   wird der Geraeteschluessel-Fingerprint per QR oder Emoji-Vergleich
   gepruefet, damit MitM-Angriffe auffallen.

### Raumtypen und ihr Zweck

| Raumtyp | Zweck | Mitglieder |
|---------|-------|------------|
| **Team-Raum** | Allgemeine Dienst-Organisation | alle Teammitglieder |
| **Klienten-Raum** | Schichtuebergabe, Akut-Themen pro Klient | nur Betreuer dieses Klienten |
| **Direkt-Chat** | 1-zu-1 Austausch | zwei Mitarbeiter |
| **Admin-Raum** | Leitungs-Entscheidungen | nur Admin + Teamleitungen |

Wichtig fuer den Datenschutz: **Klienten-Raum ≠ Klienten-Akte**.
Der Raum ist fuer operative Klaerung gedacht ("Wer uebernimmt
morgen fruehe?") — **nicht** fuer Fall-Dokumentation ("Herr P. wurde
heute aggressiv gegenueber Frau L."). Diagnose, Medikation,
Therapieziele gehoeren in die geschuetzte Akte bzw. das
Medikationsmodul.

### Grenzen des Chats — bewusste Nicht-Features

Was der Chat **nicht** ist:

- **Keine formelle Dokumentation** — Nachrichten werden nach 365
  Tagen geloescht (konfigurierbar). Wer etwas festhalten will, muss
  es im Verlaufsbericht dokumentieren.
- **Kein E-Akten-Ersatz** — Verlaeufe mit Klient-Anamnese gehoeren
  nicht in den Chat.
- **Kein externer Kanal** — Behoerden, Angehoerige, Aerzte nutzen den
  Chat nicht (sie haben keinen Zugang zur Infrastruktur). Kontakt
  laeuft wie gewohnt via Telefon / Email / beA.
- **Keine Dateiablage-Ersatz** — Anhaenge (max 50 MB) sind fuer
  situative Hinweise gedacht, nicht als Dokumenten-Archiv.

### Audit und Compliance

Systemereignisse werden im Audit-Log festgehalten:

- `chat.room.created` — wer hat welchen Raum angelegt
- `chat.member.added` / `.removed` — Mitgliederwechsel
- `chat.room.archived` — Raum stillgelegt
- **NICHT** im Audit: Nachrichteninhalte (waeren nicht entschluesselbar
  ueber den zentralen Logger)

Das reicht, um bei einer Pruefung nachzuweisen, dass Zugang sauber
vergeben und entzogen wurde.

### Rechtlicher Hintergrund

- **Art. 9 DSGVO** — besondere Kategorien personenbezogener Daten
  (Gesundheit, psychische Verfassung). Verarbeitung nur mit
  ausdruecklicher Einwilligung oder gesetzlicher Grundlage.
- **Art. 32 DSGVO** — technische und organisatorische Massnahmen zur
  Datensicherheit. E2E-Verschluesselung ist dokumentierbare TOM.
- **Art. 25 DSGVO** — Privacy by Design. E2E-Defaults ab Raumerstellung
  sind genau das.
- **TKG-Beschaeftigtendatenschutz** — Kommunikation zwischen
  Beschaeftigten darf nicht geoeffnet werden. Der Einrichtungs-
  Betreiber kann selbst die Inhalte nicht lesen — das schuetzt
  vor Verdacht der Ueberwachung.

## Warum ein eigener Chat?

- **Keine Klientendaten in WhatsApp** — Art. 9 DSGVO verbietet die Verarbeitung von Gesundheitsdaten ueber US-Dienste ohne geeignete Garantien.
- **Keine Schatten-IT** — Dienstliche Kommunikation bleibt in der dienstlichen Infrastruktur.
- **Auditierbar** — Raeume koennen mit Retention-Policies versehen werden, Audit-Log vermerkt Beitritt/Austritt.
- **Portabel** — Matrix ist ein offener Standard. Die Nachrichten liegen nicht in einer Silo-App.

## Raumtypen

| Typ | Zweck |
|-----|-------|
| Team-Raum | Allgemeine Kommunikation des Teams (Dienstplan-Klaerung, Infos) |
| Klienten-Raum | Schichtuebergabe, Beobachtungen — **nur Grunddaten, keine Diagnosen** |
| Direkt-Chat | 1-zu-1 zwischen zwei Mitarbeitern |
| Admin-Raum | Teamleitung und Verwaltung |

!!! danger "Keine sensiblen Details im Chat"
    Der Chat ist verschluesselt, aber er ist kein Ersatz fuer die Fach-Dokumentation. Diagnosen, Medikation, Therapieziele gehoeren in Klientenakte und Wirkungsmessung — nicht in Chat-Nachrichten. Der Chat dient der operativen Verstaendigung, nicht der Aktenfuehrung.

## Verschluesselung

- **Transport:** TLS zum Conduit-Server
- **Nachrichten:** Olm/Megolm End-to-End-Encryption
- **Schluessel:** Pro Geraet, mit Schluesselverifikation zwischen Team-Mitgliedern beim ersten Kontakt

Der Server sieht nur den Metadaten-Flow (wer mit wem, wann), nicht den Inhalt. Das Schluesselmaterial liegt lokal im sicheren Geraetespeicher (iOS Keychain, Android Keystore, Windows DPAPI).

## Nachrichten senden

1. Linke Leiste: **Chat** oeffnen
2. Raum aus der Liste waehlen oder neuen Raum erstellen (Admin)
3. Nachricht verfassen, optional Datei anhaengen (auch verschluesselt uebertragen)

Anhaenge werden verschluesselt hochgeladen und beim Empfaenger entschluesselt geoeffnet. Groessenlimit: 50 MB je Datei.

## Benachrichtigungen

- **Desktop:** System-Benachrichtigung bei Erwaehnung (@Name), neuer DM oder Eintritt in Raum
- **Mobil:** Push-Benachrichtigung via Conduit-Bridge, Inhalt verschluesselt
- **Im Dienstfrei-Modus** (Einstellung): nur Notfallraum klingelt, andere Raeume stumm bis Dienstbeginn

## Retention und Loeschen

- Standard-Retention pro Raum: 365 Tage
- Individuelle Nachrichten koennen vom Autor bis 15 Minuten nach Senden bearbeitet/geloescht werden
- Admin kann Raum-Historie exportieren (JSON) oder endgueltig loeschen
- Bei Ausscheiden eines Mitarbeiters: Zugang sofort entzogen, bisherige Nachrichten bleiben im Raum

## Audit

Systemereignisse (Raum erstellt, Mitglied hinzugefuegt, Raum archiviert) werden im Audit-Log `administration/audit/` mit Zeitstempel und Akteur vermerkt. Nachrichteninhalte erscheinen nicht im Audit-Log.

## Probleme

- **Meine Nachrichten kommen nicht an** — Schluesselverifikation pruefen. In Raumdetails bei jedem Mitglied den Schluessel per QR oder Emoji-Vergleich bestaetigen. Unverifizierte Schluessel blockieren Nachrichten.
- **"Unable to decrypt"** — Das Schluesselmaterial fehlt oder das Geraet wurde neu angemeldet. Alte Nachrichten bleiben unlesbar, neue Nachrichten funktionieren nach Schluesselaustausch.
- **Server offline** — Nachrichten werden lokal gepuffert und beim naechsten Online-Kontakt zugestellt.
