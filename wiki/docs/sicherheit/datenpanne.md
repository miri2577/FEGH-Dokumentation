# Datenpannen-Prozess (Art. 33/34 DSGVO)

## Was ist eine Datenpanne?

Eine Datenpanne (Verletzung des Schutzes personenbezogener Daten) liegt vor, wenn personenbezogene Daten:

- **Unbefugt offengelegt** werden (z.B. E-Mail an falsche Person, Bildschirm einsehbar)
- **Unbefugt zugaenglich** gemacht werden (z.B. Hacking, gestohlenes Geraet)
- **Verloren gehen** (z.B. defekte Festplatte ohne Backup)
- **Veraendert oder zerstoert** werden (z.B. Ransomware, versehentliches Loeschen)

## Meldepflicht

### An die Aufsichtsbehoerde (Art. 33 DSGVO)

**Frist: 72 Stunden** nach Bekanntwerden.

Meldung an die zustaendige Aufsichtsbehoerde:

| Bundesland | Behoerde | Melde-URL |
|-----------|---------|-----------|
| Berlin | Berliner Beauftragte fuer Datenschutz | datenschutz-berlin.de |
| Brandenburg | LDA Brandenburg | lda.brandenburg.de |
| Bundesweit | Jeweilige Landesbehoerde | bfdi.bund.de/infothek |

**Ausnahme**: Keine Meldepflicht wenn die Panne voraussichtlich **kein Risiko** fuer Betroffene darstellt (z.B. verschluesselte Daten ohne Schluessel verloren).

### An die Betroffenen (Art. 34 DSGVO)

Zusaetzlich muessen **betroffene Personen** informiert werden, wenn ein **hohes Risiko** fuer ihre Rechte besteht.

Bei Eingliederungshilfe-Daten (Gesundheit/Soziales) ist fast immer ein hohes Risiko anzunehmen.

## Sofortmassnahmen bei Datenpanne

### Schritt 1: Eindaemmung (sofort)

| Szenario | Sofortmassnahme |
|----------|----------------|
| **Geraet gestohlen** | Admin: Zugang sofort sperren (Rolle entfernen). Daten sind verschluesselt. |
| **Passwort kompromittiert** | Admin: Passwort zuruecksetzen (Recovery-Token). TOTP-Secret erneuern. |
| **Unbefugter Zugriff auf Server** | SSH-Keys rotieren. Conduit-Passwoerter aendern. Logs pruefen. |
| **Versehentliche Datenweitergabe** | Empfaenger kontaktieren, Loeschung verlangen, dokumentieren. |
| **Ransomware/Malware** | Geraet isolieren (Netzwerk trennen). Backup wiederherstellen. |

### Schritt 2: Dokumentation (innerhalb 24h)

Folgendes dokumentieren:

```
Datenpannen-Protokoll
=====================
Datum/Uhrzeit Bekanntwerden:  _______________
Datum/Uhrzeit des Vorfalls:   _______________
Betroffene Daten:             _______________
Anzahl betroffener Personen:  _______________
Art der Panne:                _______________
Ursache:                      _______________
Ergriffene Massnahmen:        _______________
Risikobewertung:              [ ] kein Risiko  [ ] Risiko  [ ] hohes Risiko
Meldung Aufsichtsbehoerde:    [ ] nicht noetig  [ ] gemeldet am ___
Benachrichtigung Betroffene:  [ ] nicht noetig  [ ] erfolgt am ___
Verantwortlich:               _______________
```

### Schritt 3: Meldung an Aufsichtsbehoerde (innerhalb 72h)

Inhalt der Meldung (Art. 33 Abs. 3 DSGVO):

1. **Art der Verletzung** (was ist passiert)
2. **Kategorien und Anzahl der Betroffenen** (z.B. "5 Klienten, Gesundheitsdaten")
3. **Kontaktdaten des DSB** (Name, E-Mail, Telefon)
4. **Wahrscheinliche Folgen** (Identitaetsdiebstahl, Diskriminierung, etc.)
5. **Ergriffene Massnahmen** (Sperrung, Verschluesselung, Benachrichtigung)

### Schritt 4: Benachrichtigung der Betroffenen (bei hohem Risiko)

Inhalt:

- Was ist passiert (in klarer Sprache)
- Welche Daten betroffen sind
- Welche Massnahmen ergriffen wurden
- Was die Betroffenen selbst tun koennen
- Kontaktdaten fuer Rueckfragen

**Ausnahme**: Keine Benachrichtigung noetig wenn die Daten **verschluesselt** waren und der Schluessel nicht kompromittiert wurde (Art. 34 Abs. 3a DSGVO).

## Risikobewertung

### Wann ist ein Risiko anzunehmen?

| Faktor | Kein Risiko | Risiko | Hohes Risiko |
|--------|:-----------:|:------:|:------------:|
| Daten verschluesselt, Key sicher | Ja | | |
| Daten verschluesselt, Key evtl. kompromittiert | | Ja | |
| Unverschluesselte Daten zugaenglich | | | Ja |
| Gesundheits-/Sozialdaten betroffen | | | Ja |
| Nur Kontaktdaten betroffen | | Ja | |
| Geraet mit Biometrie/PIN geschuetzt | Ja (meist) | | |

### Besonderheit FEGH-Dokumentation

Da die App alle Daten mit AES-256-GCM verschluesselt:

- **Geraet gestohlen aber gesperrt**: In der Regel **kein Risiko** (Daten verschluesselt, Biometrie/PIN)
- **Cloud-Daten zugaenglich**: In der Regel **kein Risiko** (E2E-verschluesselt, Anbieter hat keinen Schluessel)
- **Passwort kompromittiert + kein TOTP**: **Risiko** (Zugang moeglich)
- **MEK/Team-Key kompromittiert**: **Hohes Risiko** (alle Daten entschluesselbar)

## Praeventionsmassnahmen

### Bereits implementiert

- [x] AES-256-GCM Verschluesselung aller Daten
- [x] E2E-Verschluesselung im Chat (Megolm)
- [x] TOTP 2FA verfuegbar
- [x] Biometrische Authentifizierung
- [x] Session-Timeout (30 Min)
- [x] Sichere Loeschung (Crypto-Erasure)
- [x] Rollenbasierte Zugriffskontrolle
- [x] Audit-Logging
- [x] Server-Firewall + fail2ban
- [x] SSH nur mit Key

### Empfohlen

- [ ] TOTP fuer alle Mitarbeiter aktivieren
- [ ] Regelmaessige Passwort-Aenderung (alle 6 Monate)
- [ ] Geraeteverschluesselung aktivieren (BitLocker, FileVault)
- [ ] Mitarbeiter-Schulung zum Umgang mit Datenpannen
- [ ] Jaehrliche Notfalluebung ("Was tun bei Geraeteverlust?")

## Vorlagen

### E-Mail-Vorlage: Meldung an Aufsichtsbehoerde

```
Betreff: Meldung Datenpanne nach Art. 33 DSGVO

Sehr geehrte Damen und Herren,

hiermit melden wir eine Verletzung des Schutzes personenbezogener Daten
gemaess Art. 33 DSGVO:

1. Art der Verletzung: [Beschreibung]
2. Betroffene Datenkategorien: Gesundheitsdaten/Sozialdaten der Eingliederungshilfe
3. Anzahl betroffener Personen: ca. [Anzahl]
4. Datenschutzbeauftragter: [Name, E-Mail, Telefon]
5. Wahrscheinliche Folgen: [Beschreibung]
6. Ergriffene Massnahmen: [Beschreibung]

Die Verletzung wurde am [Datum, Uhrzeit] festgestellt.
Der Vorfall ereignete sich am [Datum, Uhrzeit].

Mit freundlichen Gruessen
[Name, Organisation]
```

### E-Mail-Vorlage: Benachrichtigung Betroffene

```
Betreff: Wichtige Information zum Schutz Ihrer Daten

Sehr geehrte/r [Name],

wir moechten Sie darueber informieren, dass es am [Datum] zu einem
Datenschutzvorfall gekommen ist, der moeglicherweise auch Ihre Daten betrifft.

Was ist passiert:
[Beschreibung in einfacher Sprache]

Welche Daten betroffen sind:
[Auflistung]

Was wir unternommen haben:
[Massnahmen]

Was Sie tun koennen:
[Empfehlungen]

Bei Fragen wenden Sie sich bitte an:
[Kontaktdaten]

Mit freundlichen Gruessen
[Name, Organisation]
```

## Checkliste Datenpanne

- [ ] Vorfall identifiziert und dokumentiert
- [ ] Sofortmassnahme ergriffen (Sperrung/Isolation)
- [ ] Risikobewertung durchgefuehrt
- [ ] Datenschutzbeauftragten informiert
- [ ] Geschaeftsfuehrung informiert
- [ ] Aufsichtsbehoerde gemeldet (falls Risiko, innerhalb 72h)
- [ ] Betroffene benachrichtigt (falls hohes Risiko)
- [ ] Ursache analysiert
- [ ] Massnahmen zur Verhinderung dokumentiert
- [ ] Datenpannen-Protokoll abgelegt
