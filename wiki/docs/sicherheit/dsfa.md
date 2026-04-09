# Datenschutzfolgenabschaetzung (DSFA) nach Art. 35 DSGVO

**Verantwortliche Stelle:** [Name der Organisation einsetzen]  
**Datenschutzbeauftragter:** [Name einsetzen, falls benannt]  
**Erstellt am:** [Datum einsetzen]  
**Version:** 1.0  
**Software:** FEGH-Dokumentation v0.1.0-alpha.1

---

## 1. Beschreibung der Verarbeitung

### 1.1 Zweck

Digitale Dokumentation und Verwaltung von Leistungen der Eingliederungshilfe nach SGB IX. Die App unterstuetzt Fachkraefte bei:

- Dokumentation von Betreuungsterminen mit Klienten
- Erfassung von Arbeitszeiten
- Erstellung von Informationsberichten (Berliner Formular 101)
- Verwaltung von Fachleistungsstunden und Kostenuebernahmen
- Team-basierter Zusammenarbeit ueber verschluesselte Cloud-Synchronisation

### 1.2 Kategorien betroffener Personen

| Kategorie | Beschreibung |
|-----------|-------------|
| **Klienten** | Personen die Eingliederungshilfe erhalten |
| **Mitarbeiter** | Fachkraefte die Leistungen erbringen und dokumentieren |
| **Angehoerige** | Vertreter und Kontaktpersonen der Klienten |

### 1.3 Kategorien personenbezogener Daten

| Datenkategorie | Betroffene | Art. 9 DSGVO | Beispiele |
|---------------|-----------|:------------:|-----------|
| Stammdaten | Klienten | Nein | Name, Geburtsdatum, Adresse |
| Gesundheitsdaten | Klienten | **Ja** | ICF-Klassifikation, Teilhabeziele, Betreuungsbedarf |
| Sozialdaten | Klienten | **Ja** | Rechtsgrundlage, Kostenuebernahme, Hilfe-Typ |
| Betreuungsdokumentation | Klienten | **Ja** | Terminprotokolle, Berichte, Zielerreichung |
| Beschaeftigtendaten | Mitarbeiter | Nein | Name, E-Mail, Arbeitszeiten, Urlaubstage |
| Authentifizierungsdaten | Mitarbeiter | Nein | Passwort-Hash, TOTP-Secret, Geraete-ID |

### 1.4 Rechtsgrundlage

- **Art. 6 Abs. 1b DSGVO**: Vertragserfuellung (Arbeitsvertrag Mitarbeiter, Betreuungsvertrag Klienten)
- **Art. 6 Abs. 1c DSGVO**: Rechtliche Verpflichtung (Dokumentationspflicht SGB IX)
- **Art. 9 Abs. 2b DSGVO**: Verarbeitung im Bereich Sozialrecht

### 1.5 Speicherdauer

| Datenart | Speicherdauer | Grundlage |
|----------|-------------|-----------|
| Betreuungsdokumentation | 10 Jahre nach Betreuungsende | Aufbewahrungspflicht SGB IX |
| Abrechnungsdaten | 10 Jahre | Steuerrecht (AO §147) |
| Arbeitszeiten | 2 Jahre nach Austritt | Arbeitszeitgesetz |
| Authentifizierungsdaten | Bis Austritt des Mitarbeiters | Zweckbindung |

### 1.6 Empfaenger der Daten

| Empfaenger | Zweck | Rechtsgrundlage |
|-----------|-------|----------------|
| Kostentraeger | Abrechnung Fachleistungsstunden | Leistungsvereinbarung |
| STRATO AG (HiDrive) | Cloud-Speicherung (verschluesselt) | AV-Vereinbarung |
| Keine weiteren | -- | -- |

**Wichtig:** STRATO hat keinen Zugriff auf Klartextdaten. Alle Daten sind vor dem Upload mit AES-256-GCM verschluesselt. STRATO speichert nur verschluesselte Dateien.

---

## 2. Notwendigkeit und Verhaeltnismaessigkeit

### 2.1 Erforderlichkeit

| Pruefung | Ergebnis |
|----------|---------|
| Sind alle Daten notwendig? | Ja -- Dokumentationspflicht nach SGB IX erfordert diese Daten |
| Gibt es weniger invasive Alternativen? | Nein -- Papierbasierte Dokumentation bietet weniger Schutz |
| Werden Daten minimiert? | Ja -- Nur fuer Betreuung und Abrechnung notwendige Daten |
| Ist die Speicherdauer angemessen? | Ja -- Entspricht gesetzlichen Aufbewahrungspflichten |

### 2.2 Verhaeltnismaessigkeit

Die digitale Dokumentation bietet gegenueber Papier erhebliche Vorteile:

- Verschluesselung schuetzt vor unbefugtem physischem Zugriff
- Rollenbasierte Zugriffskontrolle (5 Stufen) statt offener Aktenordner
- Loeschung durch Crypto-Erasure ist vollstaendig und nachweisbar
- Audit-Log dokumentiert alle Zugriffe

---

## 3. Risikobewertung

### 3.1 Risikomatrix

| Nr | Risiko | Eintrittswahrscheinlichkeit | Schwere | Risikostufe | Massnahme |
|----|--------|:---------------------------:|:-------:|:-----------:|-----------|
| R1 | Unbefugter Zugriff auf Klientendaten | Niedrig | Hoch | Mittel | AES-256-GCM, RBAC, 2FA |
| R2 | Datenverlust durch Geraeteverlust | Mittel | Hoch | Hoch | Verschluesselung, Cloud-Backup |
| R3 | Zugriff durch ehemalige Mitarbeiter | Niedrig | Hoch | Mittel | Sofortige Sperrung, Key-Rotation |
| R4 | Man-in-the-Middle bei Cloud-Sync | Sehr niedrig | Hoch | Niedrig | TLS, Certificate Pinning |
| R5 | Kompromittierung des Cloud-Speichers | Sehr niedrig | Mittel | Niedrig | E2E-Verschluesselung, Daten fuer Angreifer unlesbar |
| R6 | Verlust des Admin-Recovery-Keys | Niedrig | Sehr hoch | Hoch | Klare Anweisung zur sicheren Aufbewahrung |
| R7 | Brute-Force auf TOTP | Sehr niedrig | Mittel | Niedrig | 6-stellig, 30s Intervall, Toleranz ±1 |
| R8 | Social Engineering (PIN-Weitergabe) | Mittel | Mittel | Mittel | Schulung, PIN separat uebermitteln |

### 3.2 Risikobewertungs-Skala

- **Eintrittswahrscheinlichkeit**: Sehr niedrig / Niedrig / Mittel / Hoch
- **Schwere**: Niedrig / Mittel / Hoch / Sehr hoch
- **Risikostufe**: Niedrig / Mittel / Hoch / Sehr hoch

---

## 4. Technische und organisatorische Massnahmen

### 4.1 Verschluesselung

| Massnahme | Umsetzung |
|-----------|----------|
| Verschluesselung ruhender Daten | AES-256-GCM mit Envelope Encryption (MEK/DEK) |
| Verschluesselung bei Uebertragung | HTTPS/TLS 1.2+ mit Certificate-Pinning-Unterstuetzung |
| Schluesselmanagement | MEK in OS-Keychain, DEK pro Datensatz, Team-Keys pro Team |
| Pseudonymisierung | UUID-basierte Dateinamen, keine PHI in Metadaten |

### 4.2 Zugriffskontrolle

| Massnahme | Umsetzung |
|-----------|----------|
| Authentifizierung | Biometrie (Face ID, Fingerabdruck) + App-Passwort |
| Zwei-Faktor | TOTP nach RFC 6238, offline-faehig, DSGVO-konform |
| Rollenmodell | 5 Stufen (Admin, PV-Admin, Teamleitung, Mitarbeiter, Pruefer) |
| Team-Isolation | Mitarbeiter sehen nur Daten des eigenen Teams |
| Session-Management | Automatischer Lock bei Inaktivitaet |

### 4.3 Datensicherung und Wiederherstellung

| Massnahme | Umsetzung |
|-----------|----------|
| Backup | Automatisch (konfigurierbar) + manuell, verschluesselt |
| Cloud-Sync | STRATO HiDrive Business, Rechenzentrum Deutschland |
| Recovery | 12-Wort Recovery-Key fuer Admin, Recovery-Token fuer Mitarbeiter |
| Crypto-Erasure | Loeschung des MEK macht alle Daten unwiderruflich unlesbar |

### 4.4 Geraetesicherheit

| Massnahme | Umsetzung |
|-----------|----------|
| Root/Jailbreak-Erkennung | Warnung bei kompromittierten Geraeten |
| Screenshot-Schutz | FLAG_SECURE (Android), Blur (iOS) |
| USB-Debug-Erkennung | Warnung bei aktiviertem Debug-Modus (Android) |
| Entwicklermodus-Schutz | Automatische Deaktivierung unsicherer Features im Release |

### 4.5 Organisatorische Massnahmen

| Massnahme | Umsetzung |
|-----------|----------|
| Einweisung | Mitarbeiter werden bei Onboarding ueber Datenschutz informiert |
| Zugangsentzug | Sofortige Sperrung bei Ausscheiden (Admin entfernt Rolle) |
| Protokollierung | Audit-Log fuer sicherheitsrelevante Aktionen |
| Datenschutzerklaerung | Information der Betroffenen ueber Datenverarbeitung |
| AV-Vereinbarung | Mit STRATO AG fuer HiDrive-Nutzung abgeschlossen |

---

## 5. Stellungnahme des Datenschutzbeauftragten

[Vom DSB auszufuellen]

Datum: _______________

Stellungnahme: _______________________________________________

Unterschrift DSB: _______________

---

## 6. Ergebnis und Freigabe

### 6.1 Gesamtbewertung

Die Datenschutzfolgenabschaetzung ergibt, dass die Verarbeitung personenbezogener Daten durch die FEGH-Dokumentation App bei Umsetzung aller beschriebenen Massnahmen **ein vertretbares Restrisiko** aufweist.

Die Hauptrisiken (unbefugter Zugriff, Datenverlust) werden durch mehrschichtige technische Massnahmen (Verschluesselung, RBAC, 2FA) auf ein akzeptables Niveau reduziert.

### 6.2 Empfehlungen

1. Recovery-Key sicher aufbewahren (Safe, nicht digital)
2. TOTP fuer alle Nutzer mit Zugang zu Klientendaten aktivieren
3. Quartalweise Pruefung: Ausgeschiedene Mitarbeiter gesperrt?
4. Jaehrliche Ueberpruefung dieser DSFA
5. AV-Vereinbarung mit STRATO AG aktuell halten

### 6.3 Freigabe

| Rolle | Name | Datum | Unterschrift |
|-------|------|-------|-------------|
| Verantwortlicher | _______________ | _______________ | _______________ |
| DSB | _______________ | _______________ | _______________ |

---

*Diese DSFA ist jaehrlich oder bei wesentlichen Aenderungen der Verarbeitung zu ueberpruefen.*
