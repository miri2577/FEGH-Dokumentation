# Server-Sicherheit und Audit

## Uebersicht

Der FEGH Matrix-Server ist mit mehreren Sicherheitsschichten geschuetzt. Diese Seite dokumentiert alle Massnahmen, wie Einbruchsversuche erkannt werden, und wie Audit-Logs fuer Datenschutzpruefungen bereitstehen.

## fail2ban -- Brute-Force-Schutz

### Was ist fail2ban?

fail2ban ist ein Dienst der Server-Logdateien ueberwacht und IP-Adressen automatisch sperrt, wenn sie zu oft fehlschlagen. Bei unserem Server ueberwacht fail2ban SSH-Loginversuche.

### Konfiguration

| Parameter | Wert | Beschreibung |
|-----------|------|-------------|
| Ueberwachter Dienst | SSH (Port 22) | Alle SSH-Loginversuche |
| Maximale Versuche | 3 | Nach 3 fehlgeschlagenen Logins wird gesperrt |
| Sperrdauer | 3600 Sekunden (1 Stunde) | IP ist danach wieder frei |
| Backend | systemd (journald) | Liest aus dem System-Journal |

### Einbruchsversuche einsehen

Per SSH auf dem Server:

```bash
# Aktueller Status: Gesperrte IPs und Statistik
fail2ban-client status sshd
```

Beispiel-Ausgabe:
```
Status for the jail: sshd
|- Filter
|  |- Currently failed:  5
|  |- Total failed:      20
|  `- Journal matches:   _SYSTEMD_UNIT=sshd.service + _COMM=sshd
`- Actions
   |- Currently banned:  4
   |- Total banned:      4
   `- Banned IP list:    186.68.83.104 189.231.243.175 103.170.173.26 87.251.64.145
```

**Bedeutung:**

- **Currently failed**: Aktuelle fehlgeschlagene Versuche (noch nicht gesperrt)
- **Total failed**: Gesamtzahl aller fehlgeschlagenen Versuche seit Start
- **Currently banned**: Aktuell gesperrte IP-Adressen
- **Total banned**: Gesamtzahl aller jemals gesperrten IPs
- **Banned IP list**: Die konkreten gesperrten Adressen

### Weitere fail2ban Befehle

```bash
# Alle Jails (ueberwachte Dienste) anzeigen
fail2ban-client status

# Eine IP manuell entsperren
fail2ban-client set sshd unbanip 192.168.1.100

# Eine IP manuell sperren
fail2ban-client set sshd banip 192.168.1.100

# fail2ban Log einsehen
journalctl -u fail2ban --since today

# Detailliertes Log aller Aktionen
fail2ban-client get sshd bantime
```

### Wo werden Einbruchsversuche protokolliert?

| Log | Pfad / Befehl | Inhalt |
|-----|--------------|--------|
| fail2ban Aktionen | `journalctl -u fail2ban` | Alle Bans und Unbans mit Zeitstempel |
| SSH-Versuche | `journalctl -u sshd` | Alle SSH-Login-Versuche (erfolgreich + fehlgeschlagen) |
| Nginx Zugriffe | `/var/log/nginx/access.log` | Alle HTTP/HTTPS-Anfragen an den Server |
| Nginx Fehler | `/var/log/nginx/error.log` | Fehlerhafte Anfragen |

## Firewall (UFW)

### Aktive Regeln

| Port | Protokoll | Dienst | Zugriff |
|------|-----------|--------|---------|
| 22 | TCP | SSH | Nur mit Public-Key |
| 80 | TCP | HTTP | Weiterleitung auf HTTPS |
| 443 | TCP | HTTPS | Matrix-API + Well-Known |
| Alles andere | -- | -- | Blockiert (deny incoming) |

### Firewall-Status pruefen

```bash
ufw status verbose
```

### Regeln aendern

```bash
# Port oeffnen
ufw allow 8080/tcp

# Port schliessen
ufw deny 8080/tcp

# Bestimmte IP erlauben
ufw allow from 192.168.1.0/24 to any port 22
```

## SSH-Haertung

| Massnahme | Status | Konfiguration |
|-----------|--------|--------------|
| Passwort-Login | **Deaktiviert** | `PasswordAuthentication no` |
| Root-Login | Nur mit Key | `PermitRootLogin prohibit-password` |
| Authentifizierung | Nur Public-Key (Ed25519) | `/root/.ssh/authorized_keys` |

### SSH-Zugriffslog pruefen

```bash
# Alle SSH-Logins heute
journalctl -u sshd --since today

# Nur erfolgreiche Logins
journalctl -u sshd | grep "Accepted"

# Nur fehlgeschlagene Logins
journalctl -u sshd | grep "Failed\|Invalid"

# Letzte 50 Eintraege
journalctl -u sshd -n 50
```

## Automatische Sicherheitsupdates

Der Server installiert Sicherheitsupdates automatisch ueber `unattended-upgrades`:

```bash
# Status pruefen
systemctl status unattended-upgrades

# Log der installierten Updates
cat /var/log/unattended-upgrades/unattended-upgrades.log

# Manuell Updates pruefen
apt-get update && apt-get upgrade --dry-run
```

## SSL/TLS-Zertifikat

| Eigenschaft | Wert |
|------------|------|
| Anbieter | Let's Encrypt |
| Domain | Eigene Domain |
| Algorithmus | ECDSA |
| Erneuerung | Automatisch (certbot Timer, alle 90 Tage) |

### Zertifikat pruefen

```bash
certbot certificates
```

### Manuelle Erneuerung erzwingen

```bash
certbot renew --force-renewal
```

## Backup

### Automatisches Backup

| Eigenschaft | Wert |
|------------|------|
| Zeitplan | Taeglich um 02:00 Uhr |
| Speicherort | `/var/backups/conduit/` |
| Aufbewahrung | 30 Tage (aeltere werden automatisch geloescht) |
| Inhalt | Conduit-Datenbank + Konfiguration (tar.gz) |

### Backup pruefen

```bash
# Vorhandene Backups anzeigen
ls -lh /var/backups/conduit/

# Manuelles Backup erstellen
/opt/conduit/backup.sh
```

### Backup wiederherstellen

```bash
# Conduit stoppen
cd /opt/conduit && docker-compose down

# Daten loeschen
rm -rf /opt/conduit/data/*

# Backup entpacken
tar xzf /var/backups/conduit/conduit-YYYYMMDD.tar.gz -C /opt/conduit/

# Conduit starten
docker-compose up -d
```

## Audit-Protokoll fuer Datenschutzpruefung

Bei einer Datenschutzpruefung muessen folgende Nachweise erbracht werden:

### 1. Zugriffskontrolle

```bash
# Wer hat Zugang zum Server?
cat /root/.ssh/authorized_keys

# Welche User existieren?
cat /etc/passwd | grep -v nologin | grep -v false
```

### 2. Einbruchsversuche

```bash
# fail2ban Statistik
fail2ban-client status sshd

# Alle gesperrten IPs der letzten 30 Tage
journalctl -u fail2ban --since "30 days ago" | grep "Ban"

# Fehlgeschlagene SSH-Logins der letzten 30 Tage
journalctl -u sshd --since "30 days ago" | grep "Failed" | wc -l
```

### 3. Verschluesselung

```bash
# SSL-Zertifikat gueltig?
certbot certificates

# Matrix E2E aktiv? (Raeume mit Encryption)
curl -s https://DEINE-DOMAIN.de/_matrix/client/versions | python3 -m json.tool
```

### 4. Updates

```bash
# Letztes Update
cat /var/log/unattended-upgrades/unattended-upgrades.log | tail -10

# Offene Updates
apt-get update && apt-get upgrade --dry-run 2>&1 | tail -5
```

### 5. Backup-Nachweis

```bash
# Backups vorhanden und aktuell?
ls -lh /var/backups/conduit/

# Backup-Log
cat /var/log/conduit-backup.log | tail -10
```

### 6. Matrix-User-Verwaltung

```bash
# Registrierung geschlossen?
grep registration /opt/conduit/conduit.toml

# Federation deaktiviert?
grep federation /opt/conduit/conduit.toml
```

## Checkliste fuer regelmaessige Pruefung

Empfohlen: **monatlich** durchfuehren.

- [ ] `fail2ban-client status sshd` -- Einbruchsversuche pruefen
- [ ] `ufw status` -- Firewall-Regeln unveraendert?
- [ ] `certbot certificates` -- SSL-Zertifikat gueltig?
- [ ] `docker ps` -- Conduit laeuft?
- [ ] `ls -lh /var/backups/conduit/` -- Backups aktuell?
- [ ] `df -h /` -- Festplatte nicht voll?
- [ ] `free -h` -- RAM ausreichend?
- [ ] `journalctl -u sshd --since "30 days ago" | grep "Accepted"` -- Nur bekannte Zugriffe?
- [ ] `grep registration /opt/conduit/conduit.toml` -- Registrierung noch geschlossen?
