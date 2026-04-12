# Matrix-Chat: Verschluesselter Messenger

## Uebersicht

Die FEGH-Dokumentation App enthaelt einen integrierten, Ende-zu-Ende verschluesselten Messenger basierend auf dem **Matrix-Protokoll**. Der Chat laeuft ueber einen eigenen Server und ist vollstaendig DSGVO-konform.

## Architektur

| Komponente | Technologie | Standort |
|-----------|-------------|----------|
| **Server** | Conduit (Matrix-Server in Rust) | Eigener STRATO-Server, Deutschland |
| **Protokoll** | Matrix (offener Standard) | Dezentral, foederierbar |
| **Verschluesselung** | Megolm (E2E, wie Signal/Threema) | Client-seitig, Server sieht nur Ciphertext |
| **Client** | matrix SDK v6.2.0 (Flutter) | In die App integriert |
| **SSL** | Let's Encrypt (automatische Erneuerung) | TLS 1.2+ |
| **Domain** | DEINE-DOMAIN.de | A-Record auf Server-IP |

## Server-Infrastruktur

### Hardware (Empfehlung)

| Eigenschaft | Mindestanforderung |
|------------|------|
| OS | Debian 12 oder Ubuntu 22.04+ |
| CPU | 2 Kerne |
| RAM | 2 GB (empfohlen: 4 GB) |
| Speicher | 10 GB frei |
| Standort | Rechenzentrum Deutschland (DSGVO) |

### Software-Stack

| Dienst | Zweck | Status |
|--------|-------|--------|
| **Conduit** | Matrix-Homeserver (Docker) | Aktiv, Port 6167 intern |
| **Nginx** | Reverse Proxy, SSL-Termination | Aktiv, Port 80/443 |
| **Let's Encrypt** | SSL-Zertifikat (auto-renew) | Automatische Erneuerung |
| **UFW** | Firewall (nur 22, 80, 443 offen) | Aktiv |
| **fail2ban** | Brute-Force-Schutz (SSH) | Aktiv, 3 Versuche, 1h Ban |
| **unattended-upgrades** | Automatische Sicherheitsupdates | Aktiv |

### Sicherheitsmassnahmen

| Massnahme | Umsetzung |
|-----------|----------|
| **Firewall** | UFW: nur SSH (22), HTTP (80), HTTPS (443) offen |
| **SSH-Haertung** | Nur Public-Key-Auth, kein Passwort-Login |
| **Brute-Force-Schutz** | fail2ban: 3 fehlgeschlagene Versuche → 1 Stunde IP-Sperre |
| **Registrierung geschlossen** | `allow_registration = false` -- neue User nur durch Admin |
| **SSL/TLS** | Let's Encrypt mit automatischer Erneuerung |
| **Auto-Updates** | Debian unattended-upgrades fuer Sicherheitspatches |
| **Backup** | Taeglich um 02:00 Uhr, 30 Tage Aufbewahrung |
| **Federation deaktiviert** | Kein Austausch mit externen Matrix-Servern |

## Verschluesselung

### Ende-zu-Ende (Megolm)

Alle Chat-Raeume werden mit E2E-Verschluesselung erstellt:

- **Algorithmus**: `m.megolm.v1.aes-sha2` (identisch mit Signal-Protokoll-Basis)
- **Schluesselaustausch**: Olm (Double-Ratchet)
- **Der Server sieht nur verschluesselte Nachrichten** -- selbst der Server-Admin kann Inhalte nicht lesen
- **Schluessel liegen nur auf den Endgeraeten** der Teilnehmer

### Was der Server sieht (Metadaten)

| Sichtbar | Nicht sichtbar |
|----------|---------------|
| Wer mit wem kommuniziert | Nachrichteninhalte |
| Zeitpunkt der Nachricht | Dateiinhalte |
| Raum-Mitgliedschaften | Verschluesselungsschluessel |

Da der Server **im eigenen Besitz** ist, sind die Metadaten unter eigener Kontrolle und verlassen nicht die Organisation.

### Vergleich mit gaengigen Messengern

| Eigenschaft | FEGH-Chat | Threema | Signal | WhatsApp |
|------------|:---------:|:-------:|:------:|:--------:|
| E2E-Verschluesselung | Ja | Ja | Ja | Ja |
| Eigener Server | **Ja** | Nein | Nein | Nein |
| Open Source | Ja | Teilweise | Ja | Nein |
| Server in DE | **Ja (eigener)** | Schweiz | USA | USA |
| Kein Drittanbieter | **Ja** | Nein | Nein | Nein |
| DSGVO (eigene Kontrolle) | **Ja** | Teilweise | Nein | Nein |
| Metadaten unter eigener Kontrolle | **Ja** | Nein | Nein | Nein |

## DSGVO-Konformitaet

### Rechtsgrundlage

- **Art. 6 Abs. 1f DSGVO**: Berechtigtes Interesse an sicherer interner Kommunikation
- **Art. 32 DSGVO**: Angemessene technische Massnahmen (E2E, eigener Server, Firewall)

### Konformitaets-Checkliste

| Anforderung | Status | Details |
|------------|:------:|--------|
| E2E-Verschluesselung | Erfuellt | Megolm (AES-256, Olm Double-Ratchet) |
| Datenstandort Deutschland | Erfuellt | STRATO-Server, deutsches Rechenzentrum |
| Kein Drittanbieter | Erfuellt | Eigener Server, keine AVV noetig |
| Zugriffskontrolle | Erfuellt | Registrierung geschlossen, nur Admin-Einladung |
| Transportverschluesselung | Erfuellt | TLS 1.2+ mit Let's Encrypt |
| Datensparsamkeit | Erfuellt | Nur notwendige Metadaten, Inhalte E2E-verschluesselt |
| Loeschkonzept | Erfuellt | Cleanup-Cronjob, Admin kann Raeume/User loeschen |
| Backup | Erfuellt | Taeglich verschluesselt, 30 Tage Aufbewahrung |
| Protokollierung | Erfuellt | Nginx Access-Log (365 Tage), fail2ban-Log |
| Server-Sicherheit | Erfuellt | Firewall, fail2ban, SSH-Key-Only, Auto-Updates |

### Organisatorische Pflichten

1. **Verarbeitungsverzeichnis** ergaenzen: Matrix-Chat als Kommunikationsmittel auffuehren
2. **Datenschutzerklaerung** fuer Mitarbeiter: Information ueber Chat-Nutzung
3. **Zugang entziehen**: Bei Ausscheiden Mitarbeiter vom Server loeschen

## App-Integration

### Chat-Zugang

Der Chat ist in der App unter dem **Nachrichten-Tab** (Index 5) erreichbar.

### Login

Beim ersten Zugriff melden sich Nutzer mit Matrix-Credentials an:
- **Benutzername**: Vom Admin vergeben
- **Passwort**: Vom Admin vergeben
- **Server**: Wird vom Admin konfiguriert

### Features

| Feature | Status |
|---------|--------|
| 1:1 Chats (verschluesselt) | Verfuegbar |
| Gruppen-Chats (Team-Raeume) | Verfuegbar |
| Ungelesen-Anzeige | Verfuegbar |
| Verschluesselungs-Indikator | Verfuegbar |
| Mitglieder-Ansicht | Verfuegbar |
| Nachrichten-Verlauf | Verfuegbar |
| User einladen | Verfuegbar |
| Video Calls | Geplant (WebRTC/LiveKit) |
| Datei-Versand | Geplant |
| Sprachnachrichten | Geplant |

### Neuen User anlegen

Da die Registrierung geschlossen ist, muss der Admin neue User anlegen. Dies geschieht aktuell ueber die Server-Kommandozeile:

```bash
curl -s -X POST http://localhost:6167/_matrix/client/v3/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"neuer_user","password":"SicheresPasswort123","auth":{"type":"m.login.dummy"}}'
```

Zukuenftig wird die User-Erstellung in den Admin-Bereich der App integriert.

## Backup und Wartung

### Automatisches Backup

- **Zeitplan**: Taeglich um 02:00 Uhr
- **Speicherort**: `/var/backups/conduit/`
- **Aufbewahrung**: 30 Tage
- **Inhalt**: Conduit-Datenbank + Konfiguration (komprimiert)

### SSL-Zertifikat

- Let's Encrypt Zertifikat erneuert sich automatisch (certbot Timer)
- Aktuelles Zertifikat gueltig bis: 08.07.2026

### Server-Monitoring

Regelmaessig pruefen:

```bash
# Conduit laeuft?
docker ps

# Festplatte
df -h /

# fail2ban Status
fail2ban-client status sshd

# SSL-Zertifikat
certbot certificates

# Backup vorhanden?
ls -lh /var/backups/conduit/
```
