# Datenschutz-Konformitaet: TOTP-basierte Zwei-Faktor-Authentifizierung

## Rechtsgrundlage

- **DSGVO Art. 32**: Angemessene technische und organisatorische Massnahmen zur Sicherheit der Verarbeitung
- **BDSG §64**: Anforderungen an die Sicherheit der Datenverarbeitung
- **BSI-Empfehlung**: TOTP ist vom Bundesamt fuer Sicherheit in der Informationstechnik als gueltige 2FA-Methode empfohlen

## DSGVO-Konformitaet der Implementierung

| Kriterium | DSGVO-Artikel | Status | Begruendung |
|-----------|---------------|--------|-------------|
| Datensparsamkeit | Art. 5 Abs. 1c | Erfuellt | Nur TOTP-Secret gespeichert, kein Tracking, keine Metadaten |
| Zweckbindung | Art. 5 Abs. 1b | Erfuellt | Secret wird ausschliesslich zur Authentifizierung verwendet |
| Integritaet & Vertraulichkeit | Art. 5 Abs. 1f | Erfuellt | AES-256-GCM Verschluesselung, OS-Keychain |
| Technische Massnahmen | Art. 32 | Erfuellt | Kryptographisch sicherer RNG, verschluesselte Speicherung |
| Kein Drittanbieter | Art. 28 | Erfuellt | Kein Auftragsverarbeiter fuer Authentifizierung noetig |
| Datenstandort Deutschland | Art. 44-49 | Erfuellt | HiDrive = STRATO Rechenzentrum in Deutschland |

## Technische Sicherheit

### Zufallsgenerator (Secret-Erzeugung)

- Dart `Random.secure()` nutzt den kryptographischen RNG des Betriebssystems
  - Windows: CryptGenRandom (BCryptGenRandom)
  - macOS/iOS: SecRandomCopyBytes
  - Linux/Android: /dev/urandom
- TOTP-Secret: 160 Bit (20 Byte), konform mit RFC 6238 und RFC 4226 (HOTP)

### Verschluesselung

- TOTP-Secret wird **niemals im Klartext** gespeichert oder uebertragen
- Speicherung: Verschluesselt im OS-Keychain oder mit PBKDF2-abgeleitetem Key (100.000 Iterationen HMAC-SHA256)
- Uebertragung: Im Provisioning-Token mit AES-256-GCM + PIN-basiertem Schluessel verschluesselt
- Algorithmus: HMAC-SHA1 (RFC 6238 Standard), 6-stellig, 30-Sekunden-Intervall

### Kein zentraler Server

- Keine Abhaengigkeit von externen Authentifizierungsdiensten
- Kein Single Point of Failure
- Kein Risiko eines zentralen Datenlecks
- TOTP-Validierung findet komplett lokal auf dem Geraet statt

### Vorteile gegenueber SMS-OTP

| Merkmal | TOTP (unsere Loesung) | SMS-OTP |
|---------|----------------------|---------|
| Drittanbieter noetig | Nein | Ja (Mobilfunkanbieter, SMS-Gateway) |
| Netzwerk noetig | Nein (offline-faehig) | Ja |
| Abfangbar (SS7-Angriff) | Nein | Ja |
| Personenbezogene Daten an Dritte | Nein | Ja (Telefonnummer) |
| BSI-Empfehlung | Ja | Eingeschraenkt |
| DSGVO Art. 28 relevant | Nein | Ja (Auftragsverarbeitung) |

## Organisatorische Pflichten

### Verarbeitungsverzeichnis (Art. 30 DSGVO)

TOTP-Secrets muessen im Verarbeitungsverzeichnis als "Authentifizierungsdaten" aufgefuehrt werden:

```
Kategorie:          Authentifizierungsdaten
Betroffene:         Mitarbeiter der Organisation
Zweck:              Zwei-Faktor-Authentifizierung fuer App-Zugang
Rechtsgrundlage:    Art. 6 Abs. 1f DSGVO (berechtigtes Interesse an IT-Sicherheit)
Speicherort:        Lokal auf Endgeraet (OS-Keychain, verschluesselt)
Speicherdauer:      Bis Widerruf oder Ausscheiden des Mitarbeiters
Loeschung:          Automatisch bei Zugangs-Sperrung durch Admin
```

### Datenschutzerklaerung fuer Mitarbeiter

Mitarbeiter muessen informiert werden ueber:

1. **Welche Daten**: TOTP-Secret (kryptographischer Schluessel), Geraete-Fingerprint
2. **Wo gespeichert**: Ausschliesslich lokal auf dem Endgeraet, verschluesselt
3. **Zweck**: Absicherung des App-Zugangs gegen unbefugten Zugriff
4. **Keine Uebermittlung**: Keine Weitergabe an Dritte, keine Cloud-Speicherung des Secrets
5. **Loeschung**: Bei Ausscheiden wird der Zugang gesperrt und das Secret geloescht

### Loeschkonzept

| Ereignis | Massnahme | Verantwortlich |
|----------|-----------|----------------|
| Mitarbeiter scheidet aus | TOTP-Secret loeschen, Rolle in roles.json entfernen | Admin |
| Geraet verloren/gestohlen | Admin sperrt Zugang sofort, neues Provisioning noetig | Admin |
| Mitarbeiter wechselt Team | Altes Team-Secret loeschen, neues Provisioning | Teamleitung/Admin |
| Geraetewechsel | Neues Provisioning durch Teamleitung/Admin | Teamleitung/Admin |

### Protokollierung (Art. 5 Abs. 2 DSGVO - Rechenschaftspflicht)

Folgende Ereignisse werden im Audit-Log festgehalten:

- TOTP-Setup fuer Mitarbeiter (Zeitpunkt, durch wen)
- Fehlgeschlagene TOTP-Versuche (Zeitpunkt, Geraete-ID)
- TOTP-Sperrung/Entsperrung (Zeitpunkt, durch wen)
- Zugangs-Entzug (Zeitpunkt, Grund, durch wen)

## Empfehlungen fuer den Betrieb

1. **Schulung**: Mitarbeiter ueber sichere Aufbewahrung des Authenticator-Zugangs informieren
2. **Backup**: Admin-Recovery-Key (24 Woerter) ausdrucken und im Safe verwahren
3. **Regelmaessige Pruefung**: Quartalweise pruefen ob ausgeschiedene Mitarbeiter gesperrt sind
4. **Notfallplan**: Dokumentierter Prozess fuer Geraeteverlust und Passwort-Vergessen
5. **Datenschutzfolgenabschaetzung**: Bei mehr als 50 Nutzern empfohlen (Art. 35 DSGVO)
