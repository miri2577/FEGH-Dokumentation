# Zwei-Faktor-Authentifizierung (TOTP)

## Uebersicht

Die App unterstuetzt zeitbasierte Einmalpasswoerter (TOTP) nach **RFC 6238** als zweiten Authentifizierungsfaktor. Die Implementierung ist komplett offline und benoetigt keinen Drittanbieter.

## Technische Spezifikation

| Parameter | Wert |
|-----------|------|
| Algorithmus | HMAC-SHA1 |
| Secret-Laenge | 160 Bit (20 Byte) |
| Code-Laenge | 6 Ziffern |
| Zeitintervall | 30 Sekunden |
| Toleranz | ±1 Zeitschritt (90 Sekunden Fenster) |
| Kodierung | Base32 (RFC 4648) |

## TOTP einrichten

### Als Admin/Mitarbeiter (manuell)

1. **Einstellungen** oeffnen
2. Unter **Zugriffsstatus** auf **"Einrichten"** klicken
3. Den angezeigten **Base32-Code** in eine Authenticator-App eingeben (Google Authenticator, Microsoft Authenticator, Authy, etc.)
4. **"TOTP aktivieren"** klicken
5. Ab der naechsten Anmeldung wird ein Code abgefragt

### Ueber Provisioning-Token (automatisch)

Bei der Mitarbeiter-Einladung wird automatisch ein TOTP-Secret generiert und im Provisioning-Token mitgeliefert. Der Mitarbeiter muss es dann in seiner Authenticator-App einrichten.

## Anmeldung mit TOTP

1. Benutzername und Passwort eingeben
2. Nach erfolgreichem Login erscheint das **TOTP-Eingabefeld**
3. 6-stelligen Code aus der Authenticator-App eingeben
4. **"Verifizieren"** klicken
5. Ein Countdown zeigt die verbleibenden Sekunden bis zum naechsten Code

## TOTP deaktivieren

1. **Einstellungen** → **Zugriffsstatus** → **"Details"**
2. **"TOTP deaktivieren"** klicken
3. Bestaetigen

!!! warning
    Das Deaktivieren von TOTP verringert die Sicherheit. Es wird empfohlen, TOTP fuer alle Benutzer mit Zugang zu sensiblen Daten aktiviert zu lassen.

## Kompatible Authenticator-Apps

- Google Authenticator (iOS/Android)
- Microsoft Authenticator (iOS/Android)
- Authy (iOS/Android/Desktop)
- FreeOTP (iOS/Android)
- Jede App die `otpauth://` URIs unterstuetzt

## otpauth:// URI Format

```
otpauth://totp/FEGH-Dokumentation:<accountName>
  ?secret=<Base32Secret>
  &issuer=FEGH-Dokumentation
  &period=30
  &digits=6
  &algorithm=SHA1
```

## DSGVO-Konformitaet

Die TOTP-Implementierung ist vollstaendig DSGVO-konform:

- Kein Drittanbieter involviert (kein Google, kein SMS-Provider)
- TOTP-Secret wird lokal verschluesselt gespeichert
- Validierung findet komplett offline auf dem Geraet statt
- Keine personenbezogenen Daten verlassen das Geraet
- BSI-empfohlen als 2FA-Methode

Details zur DSGVO-Konformitaet: [DSGVO-Dokumentation](dsgvo.md)
