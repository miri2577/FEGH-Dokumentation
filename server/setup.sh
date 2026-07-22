#!/bin/bash
#
# FEGH-Dokumentation Server Setup
# ================================
# Dieses Skript richtet den kompletten Server ein:
# - Matrix Chat-Server (verschluesselt)
# - Nextcloud (Cloud-Speicher)
# - TURN-Server (Video-Calls)
# - Nginx + SSL (Let's Encrypt)
# - Firewall + Sicherheit
#
# Voraussetzungen:
# - Linux Server (Debian 12 / Ubuntu 22.04+)
# - Root-Zugang
# - Eine Domain die auf diesen Server zeigt
# - Ports 80, 443 offen
#

set -e

echo ""
echo "========================================="
echo "  FEGH-Dokumentation Server Setup"
echo "========================================="
echo ""

# Pruefe Root
if [ "$(id -u)" -ne 0 ]; then
    echo "FEHLER: Dieses Skript muss als root ausgefuehrt werden."
    echo "Fuehren Sie aus: sudo bash setup.sh"
    exit 1
fi

# Frage nach Konfiguration
echo "Bitte geben Sie folgende Informationen ein:"
echo ""
read -p "  Domain (z.B. chat.meinefirma.de): " DOMAIN
read -p "  E-Mail fuer SSL-Zertifikat: " EMAIL
read -sp "  Admin-Passwort (min. 8 Zeichen): " ADMIN_PASSWORD
echo ""
read -sp "  Admin-Passwort bestaetigen: " ADMIN_PASSWORD_CONFIRM
echo ""

if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
    echo "FEHLER: Passwoerter stimmen nicht ueberein."
    exit 1
fi

if [ ${#ADMIN_PASSWORD} -lt 8 ]; then
    echo "FEHLER: Passwort muss mindestens 8 Zeichen haben."
    exit 1
fi

echo ""
echo "Konfiguration:"
echo "  Domain:   $DOMAIN"
echo "  E-Mail:   $EMAIL"
echo "  Passwort: ********"
echo ""
read -p "Stimmt das? (j/n): " CONFIRM
if [ "$CONFIRM" != "j" ]; then
    echo "Abgebrochen."
    exit 0
fi

echo ""
echo "[1/8] Installiere Docker..."
apt-get update -qq
apt-get install -y -qq docker.io docker-compose curl ufw fail2ban > /dev/null 2>&1
systemctl enable docker > /dev/null 2>&1
systemctl start docker

echo "[2/8] Erstelle Konfigurationsdateien..."

# .env Datei
cat > .env << EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
ADMIN_USER=admin
ADMIN_PASSWORD=$ADMIN_PASSWORD
TURN_SECRET=$(openssl rand -hex 32)
EOF

source .env

# Conduit Config
cat > conduit.toml << EOF
[global]
server_name = "$DOMAIN"
database_backend = "rocksdb"
database_path = "/var/lib/matrix-conduit/"
port = 6167
max_request_size = 20000000
allow_registration = false
allow_federation = false
trusted_servers = ["matrix.org"]
address = "0.0.0.0"
log = "warn,rocket=off,_=off,sled=off"
turn_uris = ["turn:$DOMAIN:3478?transport=udp", "turn:$DOMAIN:3478?transport=tcp"]
turn_secret = "$TURN_SECRET"
turn_ttl = 86400
EOF

# TURN Config
cat > turnserver.conf << EOF
listening-port=3478
tls-listening-port=5349
fingerprint
lt-cred-mech
use-auth-secret
static-auth-secret=$TURN_SECRET
realm=$DOMAIN
no-stdout-log
log-file=/var/log/turnserver.log
EOF

# Nginx Config (erstmal HTTP fuer Certbot)
cat > nginx.conf << 'NGINX'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location /.well-known/matrix/server {
        return 200 '{"m.server":"DOMAIN_PLACEHOLDER:443"}';
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }

    location /.well-known/matrix/client {
        return 200 '{"m.homeserver":{"base_url":"https://DOMAIN_PLACEHOLDER"}}';
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }

    location /_matrix/ {
        proxy_pass http://fegh-conduit:6167;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_buffering off;
        client_max_body_size 20M;
    }

    location /nextcloud/ {
        proxy_pass http://fegh-nextcloud:80/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 512M;
    }

    location / {
        return 200 'FEGH-Dokumentation Server';
        add_header Content-Type text/plain;
    }
}
NGINX

sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" nginx.conf

echo "[3/8] Firewall einrichten..."
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1
ufw allow 3478/tcp > /dev/null 2>&1
ufw allow 3478/udp > /dev/null 2>&1
ufw allow 5349/tcp > /dev/null 2>&1
echo "y" | ufw enable > /dev/null 2>&1

echo "[4/8] fail2ban einrichten..."
cat > /etc/fail2ban/jail.local << 'F2B'
[sshd]
enabled = true
port = ssh
filter = sshd
backend = systemd
maxretry = 3
bantime = 3600
F2B
systemctl enable fail2ban > /dev/null 2>&1
systemctl restart fail2ban > /dev/null 2>&1

echo "[5/8] Docker-Container starten..."
docker-compose pull -q
docker-compose up -d

echo "[6/8] Warte auf Container-Start..."
sleep 15

echo "[7/8] SSL-Zertifikat holen..."
docker-compose run --rm certbot certonly \
    --webroot --webroot-path=/var/www/certbot \
    --email "$EMAIL" --agree-tos --no-eff-email \
    -d "$DOMAIN" 2>/dev/null

# Nginx auf HTTPS umstellen
cat > nginx.conf << 'NGINX'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;
    location /.well-known/acme-challenge/ { root /var/www/certbot; }
    location / { return 301 https://$host$request_uri; }
}

server {
    listen 443 ssl;
    server_name DOMAIN_PLACEHOLDER;

    ssl_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;

    location /.well-known/matrix/server {
        return 200 '{"m.server":"DOMAIN_PLACEHOLDER:443"}';
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }

    location /.well-known/matrix/client {
        return 200 '{"m.homeserver":{"base_url":"https://DOMAIN_PLACEHOLDER"}}';
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }

    location /_matrix/ {
        proxy_pass http://fegh-conduit:6167;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_buffering off;
        client_max_body_size 20M;
    }

    location /nextcloud/ {
        proxy_pass http://fegh-nextcloud:80/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 512M;
    }

    location / {
        return 200 'FEGH-Dokumentation Server';
        add_header Content-Type text/plain;
    }
}
NGINX

sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" nginx.conf
docker-compose restart nginx

echo "[8/8] Ersten Matrix-User anlegen..."
sleep 5
# Temporaer Registrierung oeffnen
sed -i 's/allow_registration = false/allow_registration = true/' conduit.toml
docker-compose restart conduit
sleep 8

curl -s -X POST http://localhost:6167/_matrix/client/v3/register \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"admin\",\"password\":\"$ADMIN_PASSWORD\",\"auth\":{\"type\":\"m.login.dummy\"}}" > /dev/null

# Registrierung schliessen
sed -i 's/allow_registration = true/allow_registration = false/' conduit.toml
docker-compose restart conduit

# Backup-Cronjob
cat > /opt/fegh-backup.sh << 'BACKUP'
#!/bin/bash
BACKUP_DIR=/var/backups/fegh
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d-%H%M%S)
CC="docker-compose -f /opt/fegh-server/docker-compose.yml"
# WICHTIG: docker-compose exec erwartet den SERVICE-Namen (conduit/nextcloud),
# nicht den Container-Namen (fegh-conduit) -> sonst schlaegt das Backup still fehl.
# Matrix/Conduit (Chat):
$CC exec -T conduit tar czf - /var/lib/matrix-conduit/ > $BACKUP_DIR/conduit-$DATE.tar.gz 2>/dev/null
# Nextcloud (Cloud-Speicher inkl. SQLite-DB und Dateien unter data/) – war bisher
# NICHT im Backup, d. h. alle Cloud-Dateien waren bei Serververlust weg:
$CC exec -T nextcloud tar czf - /var/www/html > $BACKUP_DIR/nextcloud-$DATE.tar.gz 2>/dev/null
find $BACKUP_DIR -name '*.tar.gz' -mtime +30 -delete
echo "$(date): Backup erstellt (conduit + nextcloud)" >> /var/log/fegh-backup.log
BACKUP
chmod +x /opt/fegh-backup.sh
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/fegh-backup.sh") | sort -u | crontab - 2>/dev/null

# Automatische Updates
apt-get install -y -qq unattended-upgrades > /dev/null 2>&1

echo ""
echo "========================================="
echo "  SETUP ABGESCHLOSSEN!"
echo "========================================="
echo ""
echo "  Matrix Chat:    https://$DOMAIN"
echo "  Nextcloud:      https://$DOMAIN/nextcloud/"
echo "  Admin-User:     admin"
echo "  Admin-Passwort: (wie eingegeben)"
echo ""
echo "  Element Web:    https://app.element.io"
echo "                  Homeserver: $DOMAIN"
echo ""
echo "  Naechste Schritte:"
echo "  1. Im Browser https://$DOMAIN oeffnen → 'FEGH Matrix Server'"
echo "  2. Element Web oeffnen, mit admin/$DOMAIN anmelden"
echo "  3. In der FEGH-App unter Einstellungen den Server konfigurieren"
echo ""
echo "  Zugangsdaten gespeichert in: $(pwd)/.env"
echo "  WICHTIG: .env Datei sicher aufbewahren!"
echo ""
echo "========================================="
