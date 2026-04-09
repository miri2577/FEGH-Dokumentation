# Matrix-Server aufsetzen (Anleitung)

## Voraussetzungen

| Anforderung | Minimum |
|------------|---------|
| Server | Linux (Debian 12 empfohlen), Root-Zugang |
| RAM | 1 GB (empfohlen: 2+ GB) |
| Speicher | 5 GB frei |
| Domain | Eine Domain die auf den Server zeigt (A-Record) |
| Ports | 22 (SSH), 80 (HTTP), 443 (HTTPS) offen |

Empfohlene Anbieter (Deutschland): Hetzner Cloud, netcup, STRATO, IONOS.

## Schritt 1: Server vorbereiten

```bash
# System aktualisieren
apt-get update && apt-get upgrade -y

# Docker installieren
apt-get install -y docker.io docker-compose

# Docker starten
systemctl enable docker && systemctl start docker

# Nginx und Certbot installieren
apt-get install -y nginx certbot python3-certbot-nginx
```

## Schritt 2: Conduit einrichten

```bash
# Verzeichnis erstellen
mkdir -p /opt/conduit/data
```

### Konfigurationsdatei erstellen

```bash
cat > /opt/conduit/conduit.toml << 'EOF'
[global]
server_name = "DEINE-DOMAIN.de"
database_backend = "rocksdb"
database_path = "/var/lib/matrix-conduit/"
port = 6167
max_request_size = 20000000
allow_registration = false
allow_federation = false
trusted_servers = ["matrix.org"]
address = "0.0.0.0"
log = "warn,rocket=off,_=off,sled=off"
EOF
```

**Wichtig:** `DEINE-DOMAIN.de` durch die eigene Domain ersetzen.

**Parameter erklaert:**

| Parameter | Wert | Beschreibung |
|-----------|------|-------------|
| `server_name` | Deine Domain | Matrix-Adresse (z.B. @user:domain.de) |
| `database_backend` | `rocksdb` | Schnelle Datenbank (empfohlen) |
| `port` | `6167` | Interner Port (Nginx leitet weiter) |
| `max_request_size` | `20000000` | Max. 20 MB pro Anfrage (Datei-Upload) |
| `allow_registration` | `false` | Keine offene Registrierung (Sicherheit!) |
| `allow_federation` | `false` | Kein Austausch mit fremden Servern |

### Docker-Compose erstellen

```bash
cat > /opt/conduit/docker-compose.yml << 'EOF'
version: '3'
services:
  conduit:
    image: matrixconduit/matrix-conduit:latest
    container_name: conduit
    restart: unless-stopped
    ports:
      - '6167:6167'
    volumes:
      - ./data:/var/lib/matrix-conduit/
      - ./conduit.toml:/etc/matrix-conduit/conduit.toml
    environment:
      CONDUIT_CONFIG: /etc/matrix-conduit/conduit.toml
EOF
```

### Conduit starten

```bash
cd /opt/conduit
docker-compose pull
docker-compose up -d
```

### Pruefen ob Conduit laeuft

```bash
docker ps
curl -s http://localhost:6167/_matrix/client/versions
```

Erwartete Antwort: JSON mit `"versions":["r0.5.0",...,"v1.12"]`

## Schritt 3: Nginx Reverse Proxy

```bash
cat > /etc/nginx/sites-available/conduit << 'CONF'
server {
    listen 80;
    server_name DEINE-DOMAIN.de;

    location /.well-known/matrix/server {
        return 200 '{"m.server":"DEINE-DOMAIN.de:443"}';
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }

    location /.well-known/matrix/client {
        return 200 '{"m.homeserver":{"base_url":"https://DEINE-DOMAIN.de"}}';
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }

    location /_matrix/ {
        proxy_pass http://127.0.0.1:6167;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_buffering off;
        client_max_body_size 20M;
    }

    location / {
        return 200 'FEGH Matrix Server';
        add_header Content-Type text/plain;
    }
}
CONF
```

**Wichtig:** Alle `DEINE-DOMAIN.de` durch die eigene Domain ersetzen.

```bash
# Aktivieren
ln -sf /etc/nginx/sites-available/conduit /etc/nginx/sites-enabled/conduit
rm -f /etc/nginx/sites-enabled/default

# Testen und starten
nginx -t && systemctl restart nginx
```

## Schritt 4: SSL-Zertifikat (Let's Encrypt)

```bash
certbot --nginx -d DEINE-DOMAIN.de --non-interactive --agree-tos --email DEINE-EMAIL@example.com --redirect
```

Certbot richtet automatisch HTTPS ein und erneuert das Zertifikat alle 90 Tage.

### Pruefen

```bash
curl -s https://DEINE-DOMAIN.de/_matrix/client/versions
```

## Schritt 5: Server absichern

### Firewall

```bash
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
echo 'y' | ufw enable
```

### fail2ban (Brute-Force-Schutz)

```bash
apt-get install -y fail2ban

cat > /etc/fail2ban/jail.local << 'F2B'
[sshd]
enabled = true
port = ssh
filter = sshd
backend = systemd
maxretry = 3
bantime = 3600
F2B

systemctl enable fail2ban && systemctl restart fail2ban
```

### SSH haerten

```bash
# Nur Key-Auth, kein Passwort
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart sshd
```

### Automatische Sicherheitsupdates

```bash
apt-get install -y unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades
```

## Schritt 6: Backup einrichten

```bash
cat > /opt/conduit/backup.sh << 'SCRIPT'
#!/bin/bash
BACKUP_DIR=/var/backups/conduit
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d)
tar czf $BACKUP_DIR/conduit-$DATE.tar.gz -C /opt/conduit data/ conduit.toml
find $BACKUP_DIR -name 'conduit-*.tar.gz' -mtime +30 -delete
echo "$(date): Backup erstellt" >> /var/log/conduit-backup.log
SCRIPT
chmod +x /opt/conduit/backup.sh

# Cron installieren und Backup taeglich um 2 Uhr
apt-get install -y cron
systemctl enable cron && systemctl start cron
echo '0 2 * * * /opt/conduit/backup.sh' | crontab -

# Erstes Backup sofort
/opt/conduit/backup.sh
```

## Schritt 7: Ersten User anlegen

Da `allow_registration = false` ist, muss der erste User ueber die API angelegt werden. Einmalig Registrierung oeffnen:

```bash
# Temporaer Registrierung oeffnen
sed -i 's/allow_registration = false/allow_registration = true/' /opt/conduit/conduit.toml
cd /opt/conduit && docker-compose restart
sleep 5

# Admin-User anlegen
curl -s -X POST http://localhost:6167/_matrix/client/v3/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"SICHERES_PASSWORT","auth":{"type":"m.login.dummy"}}'

# Sofort Registrierung wieder schliessen!
sed -i 's/allow_registration = true/allow_registration = false/' /opt/conduit/conduit.toml
docker-compose restart
```

**Wichtig:** `SICHERES_PASSWORT` durch ein sicheres Passwort ersetzen. Registrierung danach immer geschlossen lassen!

### Weitere User anlegen

Fuer jeden neuen Mitarbeiter den gleichen Vorgang wiederholen (temporaer oeffnen, registrieren, schliessen). Oder per Admin-API:

```bash
# Temporaer oeffnen
sed -i 's/allow_registration = false/allow_registration = true/' /opt/conduit/conduit.toml
cd /opt/conduit && docker-compose restart && sleep 5

# User anlegen
curl -s -X POST http://localhost:6167/_matrix/client/v3/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"mitarbeiter1","password":"Passwort123","auth":{"type":"m.login.dummy"}}'

# Sofort schliessen
sed -i 's/allow_registration = true/allow_registration = false/' /opt/conduit/conduit.toml
docker-compose restart
```

## Schritt 8: Testen

1. Oeffne https://app.element.io
2. **Anmelden** klicken
3. **Homeserver bearbeiten** → `DEINE-DOMAIN.de`
4. Username + Passwort eingeben
5. Chat erstellen und Nachricht senden

Wenn das funktioniert, ist der Server einsatzbereit.

## Zusammenfassung der Befehle

```bash
# Conduit Status
docker ps
curl -s https://DEINE-DOMAIN.de/_matrix/client/versions

# Firewall
ufw status

# fail2ban
fail2ban-client status sshd

# SSL
certbot certificates

# Backup
ls -lh /var/backups/conduit/

# Logs
docker logs conduit --tail 20
journalctl -u nginx --since today
```

## Zeitaufwand

| Schritt | Dauer |
|---------|-------|
| Server vorbereiten | 5 Minuten |
| Conduit einrichten | 5 Minuten |
| Nginx + SSL | 5 Minuten |
| Absichern (Firewall, fail2ban, SSH) | 10 Minuten |
| Backup einrichten | 5 Minuten |
| User anlegen + testen | 5 Minuten |
| **Gesamt** | **~35 Minuten** |
