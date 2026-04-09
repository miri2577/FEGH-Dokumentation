# Auftragsverarbeitungsvereinbarung (AVV)

## Was ist eine AVV?

Nach **Art. 28 DSGVO** muss eine AVV abgeschlossen werden, wenn personenbezogene Daten von einem Dienstleister (Auftragsverarbeiter) verarbeitet werden. Im Fall der FEGH-Dokumentation App ist dies der Cloud-Speicher-Anbieter.

## Besonderheit bei FEGH-Dokumentation

Da alle Daten **vor dem Upload mit AES-256-GCM verschluesselt** werden, hat der Cloud-Anbieter technisch **keinen Zugriff auf Klartextdaten**. Dennoch ist eine AVV rechtlich erforderlich, da der Anbieter die verschluesselten Dateien speichert und damit personenbezogene Daten im weiteren Sinne verarbeitet.

## AVV mit STRATO (HiDrive Business)

### Wo finden

STRATO stellt eine Standard-AVV fuer HiDrive Business bereit:

1. Im STRATO Kundencenter einloggen
2. Unter **Vertraege** → **Auftragsverarbeitung** die AVV herunterladen
3. Die AVV kann online abgeschlossen werden

### Was die STRATO AVV abdeckt

| Punkt | Inhalt |
|-------|--------|
| Gegenstand | Speicherung von Dateien auf HiDrive Business |
| Dauer | Laufzeit des HiDrive-Vertrags |
| Art der Daten | Verschluesselte Dateien (Klienten-, Mitarbeiter-, Termindaten) |
| Betroffene | Klienten und Mitarbeiter der Organisation |
| Rechenzentrum | Deutschland (STRATO AG, Berlin) |
| Unterauftragnehmer | Liste in der AVV aufgefuehrt |
| Technische Massnahmen | TLS-Verschluesselung, Zugriffskontrollen, Backup-Systeme |
| Kontrollrechte | Audit-Recht des Verantwortlichen |
| Loeschung | Nach Vertragsende Daten loeschen oder zurueckgeben |

### Aufbewahrung

Die unterzeichnete AVV muss aufbewahrt werden:

- Digital: Im Organisations-Dokumentenordner
- Physisch: Zusammen mit dem Verarbeitungsverzeichnis
- Dauer: Fuer die gesamte Laufzeit der Datenverarbeitung + 3 Jahre

## AVV bei alternativen Anbietern

Bei Wechsel des Cloud-Anbieters muss eine neue AVV abgeschlossen werden. Voraussetzungen:

| Anforderung | Pflicht |
|------------|---------|
| Rechenzentrum in EU/EWR | Ja (oder angemessenes Schutzniveau Art. 44-49 DSGVO) |
| AVV nach Art. 28 DSGVO | Ja |
| Technische Massnahmen dokumentiert | Ja |
| Unterauftragnehmer-Liste | Ja |
| Loeschkonzept nach Vertragsende | Ja |

## Checkliste fuer neue AVV

- [ ] AVV unterzeichnet und abgelegt
- [ ] Rechenzentrum-Standort geprueft (EU/EWR)
- [ ] Unterauftragnehmer-Liste erhalten
- [ ] Technische Massnahmen des Anbieters dokumentiert
- [ ] Kontroll- und Audit-Rechte vereinbart
- [ ] Loeschung nach Vertragsende geregelt
- [ ] Verarbeitungsverzeichnis aktualisiert
- [ ] DSFA aktualisiert (falls Anbieter wechselt)
