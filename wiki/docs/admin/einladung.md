# Mitarbeiter einladen

## Ablauf

1. Im Verwaltung-Tab auf **"Mitarbeiter einladen"** klicken
2. E-Mail-Adresse des Mitarbeiters eingeben
3. **Rolle** auswaehlen: Mitarbeiter, Teamleitung oder Pruefer
4. **Team(s)** auswaehlen (ein oder mehrere)
5. **"Einladung generieren"** klicken

## Ergebnis

Es werden generiert:

- **QR-Code**: Enthaelt den verschluesselten Provisioning-Token
- **6-stelliger PIN**: Wird separat an den Mitarbeiter uebermittelt (muendlich, SMS, etc.)
- **Token-Text**: Kopierbarer Text als Alternative zum QR-Code

## Provisioning-Token Inhalt

Der Token enthaelt (verschluesselt mit dem PIN):

```json
{
  "type": "egh-provisioning-v1",
  "org": "<orgId>",
  "user": "<email>",
  "role": "team_member",
  "teams": ["<teamId>"],
  "teamKeys": { "<teamId>": "<base64-key>" },
  "totp": "<base32-totp-secret>",
  "hidrive": {
    "username": "<hidrive-user>",
    "appPassword": "<hidrive-pass>"
  },
  "flags": {
    "managed": true,
    "forceInitialSync": true
  },
  "ts": "<ISO-8601>"
}
```

## Sicherheit des Tokens

- Der Token ist mit **AES-256-GCM** verschluesselt
- Der Schluessel wird aus dem 6-stelligen PIN abgeleitet (PBKDF2, 10.000 Iterationen)
- Der PIN wird **separat** uebermittelt (nicht zusammen mit dem QR-Code)
- Ohne den korrekten PIN ist der Token nicht entschluesselbar

## Was der Mitarbeiter tun muss

1. App installieren
2. Im Setup-Wizard **"Einladungscode verwenden"** waehlen
3. QR-Code scannen oder Token-Text einfuegen
4. 6-stelligen PIN eingeben
5. "Token entschluesseln" klicken
6. Profil bestaetigen (Vorname, Nachname)
7. App starten

Die App konfiguriert sich automatisch mit den richtigen HiDrive-Zugangsdaten, Team-Zuordnung, Team-Key und Rolle.

## Verfuegbare Rollen fuer Einladungen

| Rolle | Beschreibung |
|-------|-------------|
| Mitarbeiter | Kann dokumentieren, Termine verwalten, Berichte schreiben |
| Teamleitung | Zusaetzlich: Klienten anlegen, Stammdaten aendern, Mitarbeiter einladen |
| Pruefer | Nur Lesezugriff auf Daten und Audit-Log |

!!! note
    Die Rollen Organisations-Admin und PV-Admin koennen nicht ueber Einladungen vergeben werden. Diese werden direkt im Setup konfiguriert.
