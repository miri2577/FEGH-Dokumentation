# Konzepte: 2FA, Berechtigungen, Passwort-Recovery, Dokument-Locking

## 1. Anmeldung Fremdrechner / Mobil -- 2FA

### Empfehlung: TOTP + Geraete-Bindung

- **TOTP** (zeitbasierte Einmalpasswoerter, wie Google Authenticator): Der Admin generiert beim Onboarding ein TOTP-Secret, das im Provisioning-Token mitkommt. Der Mitarbeiter hat dann eine 6-stellige Zahl die sich alle 30 Sekunden aendert.
- **Geraete-Bindung**: Beim Erststart wird ein Geraete-Fingerprint erzeugt (Hardware-ID, OS). Anmeldung auf neuem Geraet erfordert erneutes Scannen des Provisioning-Tokens + Admin-Freigabe.
- **Session-Timeout**: Nach 30 Min Inaktivitaet → Biometrie/Passwort noetig. Nach 24h → TOTP noetig.
- **Fremdrechner**: Kein persistenter Zugang. Temporaere Session mit TOTP, alle Daten werden nach Abmeldung geloescht.

### Warum kein SMS/E-Mail-OTP

Kein zentraler Server, alles laeuft ueber HiDrive. TOTP funktioniert komplett offline.

---

## 2. Klienten anlegen -- Berechtigungsmodell

### Empfehlung: Abgestuftes Modell

| Aktion | Mitarbeiter | Teamleitung | Admin |
|--------|------------|-------------|-------|
| Klient ansehen (eigenes Team) | Ja | Ja | Ja |
| Klient-Dokumentation bearbeiten | Ja | Ja | Ja |
| Neuen Klient anlegen | Nein | Ja | Ja |
| Klient loeschen/archivieren | Nein | Nein | Ja |
| Klient anderem Team zuweisen | Nein | Nein | Ja |
| Stammdaten aendern (Name, Kostenuebernahme) | Nein | Ja | Ja |
| Termine/Berichte schreiben | Ja | Ja | Ja |

### Begruendung

Mitarbeiter dokumentieren, aber strukturelle Aenderungen (neuer Klient, Loeschung, Teamwechsel) brauchen Verantwortung. Teamleitung kann im Alltag Klienten aufnehmen ohne den Admin zu bemuehen.

---

## 3. Passwort vergessen -- Recovery-Prozess

### Mitarbeiter vergisst Passwort

1. Teamleitung kann einen **Recovery-Token** generieren (aehnlich wie Einladung, aber mit bestehender Geraete-ID)
2. Mitarbeiter gibt Recovery-Token + neuen PIN ein → Passwort wird zurueckgesetzt
3. Lokale Daten bleiben erhalten (MEK ist an Geraet gebunden, nicht ans Passwort)

### Teamleitung vergisst Passwort

1. Nur der **Admin** kann Recovery-Token fuer Teamleitungen generieren
2. Gleicher Prozess wie oben

### Admin vergisst Passwort

1. **Recovery-Key** -- wird beim Admin-Setup einmalig generiert (24 Woerter, wie Crypto-Wallet)
2. Admin muss diesen Key sicher aufbewahren (ausdrucken, Safe)
3. Damit kann der MEK wiederhergestellt und ein neues Passwort gesetzt werden
4. **Ohne Recovery-Key: Daten verloren** -- das muss beim Setup klar kommuniziert werden

---

## 4. Dokumente in Bearbeitung -- Locking

### Empfehlung: Optimistic Locking + Konflikt-Dialog

- **Lock-Marker**: Wenn ein Mitarbeiter ein Dokument oeffnet, wird eine `.lock`-Datei auf HiDrive geschrieben:
  ```json
  {
    "user": "max@team.de",
    "since": "2026-04-08T10:30:00",
    "device": "Windows-PC"
  }
  ```
- **Beim Oeffnen pruefen**: Ist eine `.lock`-Datei vorhanden und juenger als 15 Min? → Warnung: "Max Mustermann bearbeitet dieses Dokument seit 10:30"
- **Optionen fuer den Nutzer**:
  - "Nur lesen" -- schreibgeschuetzt oeffnen
  - "Trotzdem bearbeiten" -- eigene Kopie, spaeter zusammenfuehren
  - "Warten" -- Benachrichtigung wenn frei
- **Auto-Unlock**: Lock wird nach 15 Min Inaktivitaet automatisch freigegeben
- **Konflikt-Erkennung**: Beim Speichern wird der Timestamp geprueft. Wenn sich die Datei seit dem Oeffnen geaendert hat → Konflikt-Dialog mit Diff-Ansicht

---

## Umsetzungsreihenfolge (Empfehlung)

1. **Berechtigungen** -- groesster Einfluss auf taeglichen Betrieb, baut auf bestehendem UserRole-System auf
2. **Dokument-Locking** -- verhindert Datenverlust bei Teamarbeit
3. **Passwort-Recovery** -- wichtig fuer Betriebssicherheit
4. **2FA/TOTP** -- zusaetzliche Sicherheitsebene
