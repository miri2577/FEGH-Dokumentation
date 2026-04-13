# Server-Komplettpaket (One-Click Setup)

## Uebersicht

Das FEGH Server-Paket installiert mit **einem einzigen Befehl** alle benoetigten Dienste:

- Verschluesselter Matrix Chat-Server
- Nextcloud Cloud-Speicher
- Video-/Audio-Call Server (TURN)
- SSL-Verschluesselung (Let's Encrypt)
- Firewall + Brute-Force-Schutz
- Automatische Backups

**Keine IT-Kenntnisse noetig.** Das Setup-Skript fragt 3 Fragen und erledigt den Rest.

## Voraussetzungen

| Was | Beschreibung |
|-----|-------------|
| Server | Linux (Debian 12 oder Ubuntu 22.04+), ab 2 GB RAM |
| Domain | Eine Domain die auf den Server zeigt |
| SSH-Zugang | Root-Zugang zum Server |

Empfohlene Anbieter (Rechenzentrum Deutschland):

- **Hetzner Cloud** CX22 (~4 EUR/Monat)
- **netcup** VPS (~3 EUR/Monat)
- **IONOS** VPS (~4 EUR/Monat)

## Installation

### 1. Server mieten

Beim Anbieter einen Linux-Server bestellen (Debian 12 empfohlen). Die IP-Adresse notieren.

### 2. Domain einrichten

Beim Domain-Anbieter einen **A-Record** erstellen:

```
chat.meinefirma.de → [Server-IP]
```

### 3. Setup starten

**[Server-Paket herunterladen (GitHub)](https://github.com/miri2577/FEGH-Dokumentation/archive/refs/heads/main.zip)**

Oder per SSH auf dem Server einloggen und ausfuehren:

```bash
ssh root@[Server-IP]
apt-get update && apt-get install -y git
git clone https://github.com/miri2577/FEGH-Dokumentation.git
cd FEGH-Dokumentation/server
bash setup.sh
```

Das Skript fragt:

1. **Domain** (z.B. `chat.meinefirma.de`)
2. **E-Mail** (fuer SSL-Zertifikat)
3. **Admin-Passwort** (fuer Chat und Cloud)

Danach laeuft alles automatisch (~5 Minuten).

### 4. Fertig!

Am Ende zeigt das Skript:

```
=========================================
  SETUP ABGESCHLOSSEN!
=========================================

  Matrix Chat:    https://chat.meinefirma.de
  Nextcloud:      https://chat.meinefirma.de/nextcloud/
  Admin-User:     admin
  Admin-Passwort: (wie eingegeben)
=========================================
```

## Was das Skript macht

| Schritt | Was passiert |
|---------|-------------|
| 1 | Docker installieren |
| 2 | Konfigurationsdateien erstellen |
| 3 | Firewall einrichten (nur Ports 22, 80, 443, 3478) |
| 4 | fail2ban aktivieren (SSH Brute-Force-Schutz) |
| 5 | Docker-Container starten |
| 6 | SSL-Zertifikat holen (Let's Encrypt) |
| 7 | HTTPS aktivieren |
| 8 | Admin-User anlegen |

## Dateien im Server-Paket

```
server/
├── docker-compose.yml   # Alle Container-Definitionen
├── setup.sh             # Setup-Skript (einmalig ausfuehren)
├── README.md            # Anleitung
├── .env                 # Zugangsdaten (wird vom Setup erstellt)
├── conduit.toml         # Chat-Server Konfiguration
├── turnserver.conf      # Video-Call Konfiguration
└── nginx.conf           # Webserver Konfiguration
```

## Taeglich Wartung

Normalerweise ist **keine Wartung noetig**. Alles laeuft automatisch:

- SSL-Zertifikat erneuert sich automatisch
- Backups werden taeglich um 2 Uhr erstellt
- Sicherheitsupdates werden automatisch installiert

### Wenn etwas nicht funktioniert

```bash
# Status aller Container pruefen
cd FEGH-Dokumentation/server
docker-compose ps

# Container neustarten
docker-compose restart

# Logs anzeigen
docker-compose logs --tail 20
```

## Sicherheit

Das Setup richtet automatisch ein:

- **Firewall**: Nur noetige Ports offen
- **fail2ban**: SSH-Brute-Force-Schutz
- **SSL**: HTTPS mit Let's Encrypt
- **Chat-Registrierung**: Geschlossen (nur Admin kann User anlegen)
- **Automatische Updates**: Sicherheitspatches werden automatisch installiert
- **Backups**: Taeglich verschluesselt
