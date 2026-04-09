# Datenmodelle

Alle Modelle verwenden JSON-Serialisierung ueber `json_annotation` mit Code-Generierung (`build_runner`).

## Client (Klient)

| Feld | Typ | Beschreibung |
|------|-----|-------------|
| id | String | Interne UUID |
| name | String | Anzeigename |
| klientenId | String? | Externe ID |
| vorname, nachname | String? | Namensteile |
| geburtsdatum | DateTime? | Geburtsdatum |
| betreuungSeit | DateTime? | Betreuungsbeginn |
| kostenuebernahme | String? | Kostentraeger |
| kostenuebernahmeVon/Bis | DateTime? | Gueltigkeitszeitraum |
| fachleistungsstunden | int? | Bewilligte Stunden |
| fachleistungsIntervall | Enum | woechentlich/monatlich/jaehrlich |
| verbrauchteStunden | double | Geleistete Stunden |
| kalkulationsfaktorOverride | double? | Klient-spezifischer Faktor |
| stundensatzOverride | double? | Klient-spezifischer Satz |
| tibZiele | List&lt;String&gt;? | Teilhabeziele |
| individuelleTibZiele | List&lt;String&gt;? | Eigene Ziele |
| icfBereiche | List&lt;String&gt;? | ICF-Klassifikation |
| rechtsgrundlage | String? | Rechtliche Basis |
| hilfeTyp | Enum | eingliederungshilfe/familienhilfe |
| vertreter1Id, vertreter2Id | String? | Vertretung |
| customColor | String? | Kalenderfarbe (Hex) |

## Appointment (Termin)

| Feld | Typ | Beschreibung |
|------|-----|-------------|
| id | String | UUID |
| clientId, clientName | String | Zugeordneter Klient |
| date | DateTime | Datum |
| startTime, endTime | DateTime | Zeitraum |
| terminArt | Enum | 8 Termin-Arten |
| notes | String | Dokumentation |
| recordedText | String? | Sprach-Transkript |
| berufsgruppe, eingliederung | String | Berufliche Zuordnung |
| fachleistungsstunden | int? | Abrechenbare Stunden |
| icfBereiche | List&lt;String&gt;? | ICF-Bereiche |
| selectedTibZiele | List&lt;String&gt;? | Verknuepfte TIB-Ziele |
| tibZielMinuten | Map&lt;String, int&gt;? | Zeitverteilung pro Ziel |
| fahrwegHinId, fahrwegRueckId | String? | Verknuepfte Fahrwege |
| clientAllocations | Map? | Zeit-Aufteilung bei indirekten Terminen |

## Arbeitszeit

| Feld | Typ | Beschreibung |
|------|-----|-------------|
| id | String | UUID |
| datum | DateTime | Arbeitstag |
| startzeit, endzeit | DateTime | Zeitraum |
| taetigkeit | String | Taetigkeitsbeschreibung |
| typ | Enum | 8 Taetigkeitstypen |
| notizen | String? | Anmerkungen |
| clientId | String? | Optionale Klienten-Verknuepfung |
| appointmentId | String? | Optionale Termin-Verknuepfung |

## Mitarbeiter

| Feld | Typ | Beschreibung |
|------|-----|-------------|
| id | String | UUID |
| name, vorname | String | Name |
| email, telefon | String | Kontakt |
| teamNummer | int | Team-Nummer (Legacy) |
| teamIds | List&lt;String&gt; | Team-IDs (Multi-Team) |
| bereich | Enum | 6 Arbeitsbereiche |
| wochenarbeitszeit | double | Stunden/Woche |
| urlaubstage | int | Tage/Jahr |
| isActive | bool | Aktiv-Status |

## Team

| Feld | Typ | Beschreibung |
|------|-----|-------------|
| id | String | UUID |
| name, description | String | Bezeichnung |
| department, location | String? | Abteilung, Standort |
| teamLeaderId | String? | Teamleitung |
| memberIds | List&lt;String&gt; | Mitglieder |
| clientIds | List&lt;String&gt; | Zugewiesene Klienten |
| status | Enum | active/inactive/onHold |

## AppSettings

| Feld | Typ | Beschreibung |
|------|-----|-------------|
| userName | String | Anzeigename |
| userRole | UserRole | orgAdmin/pvAdmin/teamLead/teamMember/orgAuditor |
| hidriveUsername/Password | String | HiDrive-Zugangsdaten |
| organizationId, teamId | String | Org/Team-Zuordnung |
| totpSecret | String | TOTP Base32-Secret (leer = deaktiviert) |
| syncPassphrase | String | Zusaetzliche Sync-Verschluesselung |
| kalkulationsfaktor | double | FLS-Faktor (Standard: 1,33) |
| stundensatz | double | EUR pro FLS (Standard: 40,00) |
| setupCompleted | bool | Ersteinrichtung abgeschlossen |

## Informationsbericht

Berliner Formular 101 mit 137 Feldern, gegliedert in 6 Abschnitte. Enthaelt verschachtelte `Teilhabeziel`-Objekte mit Leitziel, Teilhabeziel, Indikator und Zielerreichungsstatus.

## FreizeitAntrag

Urlaubs- und Freizeitantraege mit 6 Typen (Urlaub, Freizeitausgleich, Sonderurlaub, Fortbildung, Krankmeldung, Unbezahlt) und 4 Status (Beantragt, Genehmigt, Abgelehnt, Zurueckgezogen).

## Message

Verschluesseltes Nachrichtenformat mit geraetespezifischem Key-Wrapping, 4 Prioritaetsstufen und 6 Nachrichtentypen.
