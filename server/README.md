# FEGH-Dokumentation Server

Kompletter Server fuer verschluesselten Chat, Cloud-Speicher und Video-Calls.

## Voraussetzungen

- Ein Linux-Server (Debian 12 oder Ubuntu 22.04+)
- Mindestens 2 GB RAM, 10 GB Speicher
- Root-Zugang (SSH)
- Eine Domain die auf den Server zeigt (DNS A-Record)

Empfohlene Anbieter (Deutschland): Hetzner Cloud (~4 EUR/Monat), netcup, STRATO, IONOS.

## Was wird installiert?

| Dienst | Zweck |
|--------|-------|
| **Conduit** | Matrix Chat-Server (Ende-zu-Ende verschluesselt) |
| **Nextcloud** | Cloud-Speicher (HiDrive-Alternative) |
| **Coturn** | Video-/Audio-Calls (TURN-Server) |
| **Nginx** | Webserver mit SSL (Let's Encrypt) |
| **Firewall** | Nur noetige Ports offen (UFW) |
| **fail2ban** | Brute-Force-Schutz |

## Installation (3 Schritte)

### Schritt 1: Server mieten und Domain einrichten

1. Server mieten (z.B. Hetzner Cloud CX22)
2. Im DNS eine Domain auf die Server-IP zeigen lassen:
   ```
   chat.meinefirma.de → 123.456.789.0
   ```
3. Warten bis DNS aktiv ist (kann bis zu 24h dauern, meist schneller)

### Schritt 2: Per SSH verbinden

```bash
ssh root@DEINE-SERVER-IP
```

### Schritt 3: Setup starten

```bash
# Dateien herunterladen
apt-get update && apt-get install -y git
git clone https://github.com/miri2577/FEGH-Dokumentation.git
cd FEGH-Dokumentation/server

# Setup starten
bash setup.sh
```

Das Skript fragt nach:
- **Domain**: z.B. `chat.meinefirma.de`
- **E-Mail**: Fuer SSL-Zertifikat (Let's Encrypt)
- **Admin-Passwort**: Fuer Chat und Nextcloud

Danach laeuft alles automatisch (~5 Minuten).

## Nach der Installation

### Chat testen

1. Oeffne https://app.element.io
2. **Anmelden** → Homeserver: `chat.meinefirma.de`
3. Username: `admin`, Passwort: wie eingegeben

### Nextcloud testen

1. Oeffne `https://chat.meinefirma.de/nextcloud/`
2. Username: `admin`, Passwort: wie eingegeben

### App konfigurieren

In der FEGH-Dokumentation App:
1. Einstellungen → Cloud-Sync
2. Server-Adresse eingeben

## Wartung

### Server-Status pruefen

```bash
cd /opt/fegh-server  # oder wo Sie die Dateien abgelegt haben
docker-compose ps
```

### Container neustarten

```bash
docker-compose restart
```

### Updates einspielen

```bash
docker-compose pull
docker-compose up -d
```

### Backup

Automatisch taeglich um 2 Uhr. Manuell:
```bash
/opt/fegh-backup.sh
ls -lh /var/backups/fegh/
```

### Neuen Chat-User anlegen

```bash
# Registrierung temporaer oeffnen
sed -i 's/allow_registration = false/allow_registration = true/' conduit.toml
docker-compose restart conduit
sleep 5

# User anlegen
curl -s -X POST http://localhost:6167/_matrix/client/v3/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"neuer_user","password":"SicheresPasswort","auth":{"type":"m.login.dummy"}}'

# Registrierung schliessen
sed -i 's/allow_registration = true/allow_registration = false/' conduit.toml
docker-compose restart conduit
```

## Troubleshooting

### "Domain nicht erreichbar"
- DNS-Eintrag pruefen: `nslookup chat.meinefirma.de`
- Firewall pruefen: `ufw status`
- Ports 80 + 443 muessen beim Hosting-Anbieter offen sein

### "SSL-Zertifikat fehlt"
```bash
docker-compose run --rm certbot certonly \
  --webroot --webroot-path=/var/www/certbot \
  --email DEINE-EMAIL -d DEINE-DOMAIN
docker-compose restart nginx
```

### "Chat-Anmeldung fehlgeschlagen"
```bash
docker logs fegh-conduit --tail 20
```

### "Nextcloud zeigt Fehler"
```bash
docker logs fegh-nextcloud --tail 20
```

## Sicherheit

- Alle Daten verschluesselt (Chat: Megolm E2E, Nextcloud: AES)
- Firewall: nur SSH (22), HTTP (80), HTTPS (443), TURN (3478/5349)
- fail2ban: 3 fehlgeschlagene SSH-Versuche → 1h Sperre
- SSL: Let's Encrypt mit automatischer Erneuerung
- Automatische Sicherheitsupdates (unattended-upgrades)
- Chat-Registrierung geschlossen (nur Admin kann User anlegen)
