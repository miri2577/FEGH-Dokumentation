# Nachrichten

## Internes Nachrichtensystem

Die App verfuegt ueber ein internes Nachrichtensystem fuer die Team-Kommunikation. Nachrichten werden ueber HiDrive synchronisiert und sind verschluesselt.

## Nachricht

| Feld | Beschreibung |
|------|-------------|
| Titel | Betreff der Nachricht |
| Inhalt | Nachrichtentext |
| Absender | Name und ID des Absenders |
| Prioritaet | Niedrig, Normal, Hoch, Dringend |
| Typ | Info, Warnung, Fehler, Erfolg, Ankuendigung, Update |
| Route | Optionaler Deep-Link in die App |
| Gelesen | Status und Zeitpunkt |

## Prioritaeten

| Prioritaet | Verwendung |
|------------|-----------|
| Niedrig | Informelle Mitteilungen |
| Normal | Standard-Nachrichten |
| Hoch | Wichtige Informationen |
| Dringend | Sofortige Aufmerksamkeit noetig |

## Ungelesen-Anzeige

Die Anzahl ungelesener Nachrichten wird als Badge im Nachrichten-Tab und in der Navigation angezeigt.

## Verschluesselung

Nachrichten werden mit geraetefspezifischen Schluesseln verschluesselt (`EncryptedMessage` mit `DeviceKey`-Wrapping). Jedes Geraet erhaelt einen eigenen Entschluesselungsschluessel.
