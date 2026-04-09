# DSGVO-Konformitaet

## Uebersicht

Die FEGH-Dokumentation App ist fuer den Einsatz nach deutschem Datenschutzrecht (DSGVO, BDSG) konzipiert.

## Technische Massnahmen (Art. 32 DSGVO)

| Massnahme | Umsetzung |
|-----------|----------|
| Verschluesselung | AES-256-GCM mit Envelope Encryption (MEK/DEK) |
| Pseudonymisierung | UUID-basierte Dateinamen, keine PHI in Metadaten |
| Zugriffskontrolle | Rollenbasiert (5 Stufen), biometrisch + TOTP 2FA |
| Transportverschluesselung | HTTPS/TLS mit Certificate-Pinning-Unterstuetzung |
| Datenstandort | STRATO HiDrive, Rechenzentrum Deutschland |
| Geraetesicherheit | Root-/Jailbreak-Erkennung, Screenshot-Schutz |

## Betroffenenrechte

### Art. 15 -- Auskunftsrecht

Alle gespeicherten Daten sind in der App einsehbar (Klienten, Termine, Arbeitszeiten, Berichte).

### Art. 17 -- Recht auf Loeschung

Unter **Einstellungen → Datenverwaltung → Alle Daten loeschen**:

- Unwiderrufliche Loeschung mit Bestaetigungscode
- **Crypto-Erasure**: Loeschung des MEK macht alle verschluesselten Daten unlesbar
- Keine Datenrueckstaende

### Art. 20 -- Recht auf Datenportabilitaet

Unter **Einstellungen → Datenverwaltung → DSGVO-Export**:

- Vollstaendiger Export aller personenbezogenen Daten
- Optional passwortgeschuetzt
- Maschinenlesbares Format (JSON)

## TOTP-spezifische Konformitaet

| DSGVO-Artikel | Status | Begruendung |
|---------------|--------|-------------|
| Art. 5 Abs. 1c (Datensparsamkeit) | Erfuellt | Nur TOTP-Secret gespeichert, kein Tracking |
| Art. 5 Abs. 1b (Zweckbindung) | Erfuellt | Secret nur zur Authentifizierung |
| Art. 5 Abs. 1f (Integritaet) | Erfuellt | AES-256-GCM, OS-Keychain |
| Art. 28 (Auftragsverarbeitung) | Nicht noetig | Kein Drittanbieter fuer Authentifizierung |
| Art. 44-49 (Datenstandort) | Erfuellt | Alle Daten in Deutschland |

## Verarbeitungsverzeichnis (Art. 30)

TOTP-Secrets im Verarbeitungsverzeichnis auffuehren als:

```
Kategorie:          Authentifizierungsdaten
Betroffene:         Mitarbeiter der Organisation
Zweck:              Zwei-Faktor-Authentifizierung
Rechtsgrundlage:    Art. 6 Abs. 1f DSGVO (berechtigtes Interesse)
Speicherort:        Lokal auf Endgeraet (verschluesselt)
Speicherdauer:      Bis Widerruf oder Ausscheiden
Loeschung:          Automatisch bei Zugangs-Sperrung
```

## Loeschkonzept

| Ereignis | Massnahme | Verantwortlich |
|----------|-----------|----------------|
| Mitarbeiter scheidet aus | Zugang sperren, TOTP-Secret loeschen, Rolle entfernen | Admin |
| Geraet verloren | Admin sperrt Zugang sofort | Admin |
| Mitarbeiter wechselt Team | Altes Team-Secret loeschen, neues Provisioning | Teamleitung/Admin |

## Empfehlungen fuer den Betrieb

1. Mitarbeiter ueber Datenspeicherung informieren (Datenschutzerklaerung)
2. Quartalweise pruefen ob ausgeschiedene Mitarbeiter gesperrt sind
3. Recovery-Key sicher aufbewahren (Safe)
4. Bei mehr als 50 Nutzern: Datenschutzfolgenabschaetzung (Art. 35 DSGVO) empfohlen
