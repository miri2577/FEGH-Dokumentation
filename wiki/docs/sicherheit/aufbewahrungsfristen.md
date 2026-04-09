# Aufbewahrungsfristen und Archivierung

## Gesetzliche Grundlagen

### Fristen nach Datenart

| Datenart | Frist | Rechtsgrundlage | Fristbeginn |
|----------|-------|----------------|-------------|
| Betreuungsdokumentation | **10 Jahre** | SGB IX §35a, Landesrahmenvertrag | Nach Ende der Massnahme |
| Abrechnungsunterlagen | **10 Jahre** | AO §147 Abs. 1 Nr. 1 | Nach Ablauf des Kalenderjahres der letzten Abrechnung |
| Kostenuebernahme-Bescheide | **10 Jahre** | AO §147 Abs. 1 | Nach Ablauf des Kalenderjahres |
| Informationsberichte | **10 Jahre** | SGB IX, Landesrahmenvertrag | Nach Berichtsdatum |
| Arbeitszeiten | **2 Jahre** | ArbZG §16 Abs. 2 | Nach Aufzeichnung |
| Urlaubsantraege | **2 Jahre** | BUrlG analog | Nach Ende des Urlaubsjahres |
| Personalakten (Mitarbeiter) | **3 Jahre** nach Austritt | BGB §195 (Verjaehrung) | Nach Austritt des Mitarbeiters |
| Einwilligungserklaerungen | **Solange Daten existieren** | DSGVO Art. 7 Abs. 1 | Solange zugehoerige Daten verarbeitet werden |
| Audit-Logs | **3 Jahre** | DSGVO Art. 5 Abs. 2 (Rechenschaftspflicht) | Nach Erstellung |
| Chat-Nachrichten | **Keine gesetzliche Pflicht** | Organisationsintern festlegen | Empfehlung: 1-2 Jahre |

### Besonderheiten Berlin

Der Berliner Rahmenvertrag fuer Eingliederungshilfe kann laengere Fristen vorsehen. Pruefen Sie:

- Rahmenvertrag nach §131 SGB IX fuer Berlin
- Vereinbarungen mit dem jeweiligen Kostentraeger (Bezirksamt, Senatsverwaltung)
- Vorgaben des Traegervereins/Unternehmens

**Im Zweifel: 10 Jahre fuer alles Klientenbezogene.**

## Nach Ablauf der Frist

Nach Ablauf der Aufbewahrungsfrist **muessen** die Daten geloescht werden (DSGVO Art. 5 Abs. 1e -- Speicherbegrenzung). Eine laengere Aufbewahrung ist nur mit neuem Rechtsgrund zulaessig.

### Loeschprozess

1. **Regelmaessige Pruefung** (empfohlen: quartalsweise)
   - Welche Klienten-Massnahmen sind seit >10 Jahren beendet?
   - Welche Arbeitszeiten sind aelter als 2 Jahre?
   - Welche Mitarbeiter sind seit >3 Jahren ausgeschieden?

2. **Loeschung durchfuehren**
   - In der App: Klient loeschen (nur Admin)
   - Die App ueberschreibt Dateien mit Zufallsdaten vor dem Loeschen (Crypto-Erasure)
   - Cloud-Kopien werden automatisch mitgeloescht

3. **Loeschung dokumentieren**
   - Audit-Log protokolliert Zeitpunkt und durchfuehrende Person
   - Loeschprotokoll fuer Datenschutzbeauftragten aufbewahren

## Archivierungsstrategie (3-2-1 Regel)

### Warum 3-2-1?

Die gesetzlichen Aufbewahrungsfristen verlangen, dass Daten **zuverlaessig verfuegbar** sind -- ueber 10 Jahre. Ein einzelner Speicherort (z.B. nur HiDrive) ist dafuer nicht ausreichend.

### Die Regel

| Kopie | Medium | Standort | Beispiel |
|-------|--------|----------|---------|
| **Kopie 1** | App-Geraet | Buero | Windows-PC, Tablet |
| **Kopie 2** | Externe Festplatte | Buero (Safe) | Verschluesselte USB-Festplatte |
| **Kopie 3** | Cloud oder externer Standort | Offsite | HiDrive, Nextcloud, oder Tresor an anderem Ort |

### Praktische Umsetzung

**Woechentlich:**
- App-Backup erstellen (Einstellungen > Backup)
- Backup auf externe Festplatte kopieren

**Monatlich:**
- Cloud-Sync pruefen (funktioniert die Synchronisation?)
- Backup-Integritaet pruefen (kann ein Backup wiederhergestellt werden?)

**Jaehrlich:**
- Externe Festplatte auf Funktionsfaehigkeit pruefen
- Ggf. Festplatte austauschen (Lebensdauer ~5 Jahre)
- Archivierte Daten auf Loeschfristen pruefen

## Was passiert wenn der Cloud-Anbieter ausfaellt?

### Szenario: STRATO/HiDrive Insolvenz

**Kein Datenverlust, weil:**

1. Die App speichert alle Daten **primaer lokal** auf dem Geraet
2. Cloud-Sync ist eine **Kopie**, nicht der Primaerspeicher
3. Verschluesselte Backups liegen auf der externen Festplatte

**Handlungsschritte bei Anbieter-Ausfall:**

1. Lokale Daten sind weiterhin in der App verfuegbar
2. Externen Backup pruefen (aktuelle Kopie vorhanden?)
3. Neuen Cloud-Anbieter einrichten (Nextcloud, eigener Server, anderer WebDAV-Anbieter)
4. Cloud-Sync auf neuen Anbieter umkonfigurieren (Einstellungen > Cloud-Sync)
5. Daten synchronisieren sich automatisch zum neuen Anbieter

### Szenario: Geraet defekt

1. Neues Geraet einrichten
2. App installieren
3. Cloud-Sync konfigurieren → Daten werden automatisch geladen
4. ODER: Backup von externer Festplatte wiederherstellen

### Szenario: Beides gleichzeitig (Geraet + Cloud)

1. Backup von externer Festplatte auf neues Geraet laden
2. App installieren
3. Backup importieren (Einstellungen > Backup wiederherstellen)
4. Neuen Cloud-Anbieter einrichten

**Deshalb ist die externe Festplatte die wichtigste Sicherung.**

## Archivierung vs. aktive Nutzung

### Aktive Daten

Klienten in laufender Betreuung. Liegen in der App und werden regelmaessig synchronisiert.

### Archivierte Daten

Beendete Betreuungen die noch aufbewahrt werden muessen (bis 10 Jahre). Optionen:

1. **In der App belassen**: Klient als "inaktiv" markieren. Daten bleiben verschluesselt und werden mitgesichert.
2. **Exportieren und separat archivieren**: DSGVO-Export erstellen, verschluesselt auf externer Festplatte ablegen, in der App loeschen.

**Empfehlung**: Option 1 fuer die ersten Jahre, Option 2 wenn die Datenmenge zu gross wird.

## Checkliste fuer Organisationen

### Einmalig einrichten

- [ ] Externe Festplatte beschaffen (verschluesselt, z.B. mit BitLocker/LUKS)
- [ ] Backup-Rhythmus festlegen (woechentlich empfohlen)
- [ ] Verantwortliche Person fuer Backups benennen
- [ ] Aufbewahrungsfristen im Verarbeitungsverzeichnis dokumentieren
- [ ] Loeschkonzept schriftlich festhalten

### Regelmaessig durchfuehren

- [ ] Woechentlich: App-Backup auf externe Festplatte
- [ ] Monatlich: Cloud-Sync pruefen
- [ ] Quartalsweise: Abgelaufene Aufbewahrungsfristen pruefen
- [ ] Jaehrlich: Backup-Medium pruefen, Archivierungsstrategie ueberpruefen

### Bei Mitarbeiter-Austritt

- [ ] App-Zugang sofort sperren (Admin entfernt Rolle)
- [ ] Chat-Account deaktivieren
- [ ] TOTP-Secret loeschen
- [ ] Dokumentieren wer wann gesperrt wurde (Audit-Log)
- [ ] Personalakte: 3 Jahre aufbewahren, dann loeschen

### Bei Klienten-Ende

- [ ] Betreuungsende-Datum dokumentieren
- [ ] Klient als inaktiv markieren (nicht sofort loeschen!)
- [ ] In 10 Jahren: Loeschung durchfuehren und dokumentieren
