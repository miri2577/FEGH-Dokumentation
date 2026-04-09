# Nachrichten und Chat

## Verschluesselter Team-Chat (Matrix)

Seit Version 0.2.0-beta.1 nutzt die App einen integrierten **Matrix-Chat** fuer die Team-Kommunikation. Alle Nachrichten sind Ende-zu-Ende verschluesselt (Megolm, wie Signal/Threema).

Der Chat laeuft ueber einen eigenen Server -- keine Drittanbieter, keine Daten in der Cloud fremder Unternehmen.

## Chat-Zugang

Der Chat ist ueber den **Nachrichten-Tab** (5. Tab) erreichbar.

### Erstmalige Anmeldung

1. Nachrichten-Tab oeffnen
2. **Benutzername** und **Passwort** eingeben (vom Admin erhalten)
3. Server ist vorkonfiguriert
4. **Anmelden** klicken

### Neuen Chat starten

- **Direktchat**: Auf "+" klicken → `@username:server` eingeben → Erstellen
- **Gruppenraum**: Auf "+" klicken → Team-Name eingeben → Erstellen

Alle Raeume werden automatisch mit E2E-Verschluesselung erstellt.

## Features

| Feature | Status |
|---------|:------:|
| 1:1 Chats (verschluesselt) | Verfuegbar |
| Gruppen-Chats (Team-Raeume) | Verfuegbar |
| Ungelesen-Anzeige | Verfuegbar |
| Verschluesselungs-Indikator (Schloss-Icon) | Verfuegbar |
| Mitglieder-Ansicht | Verfuegbar |
| Nachrichten-Verlauf | Verfuegbar |
| Dateien senden (Bilder, Dokumente) | Verfuegbar |
| User einladen | Verfuegbar |
| Video-Anruf | Ueber Element Web |
| Audio-Anruf | Ueber Element Web |
| Sprachnachrichten | Geplant |

## Verschluesselung

- **Algorithmus**: Megolm (m.megolm.v1.aes-sha2)
- **Schluesselaustausch**: Olm (Double-Ratchet, wie Signal)
- **Der Server sieht nur verschluesselte Nachrichten**
- Schluessel liegen ausschliesslich auf den Endgeraeten

## Dateien senden

Im Chat koennen Dateien gesendet werden:

1. Auf das **Bueroklammer-Icon** links neben dem Eingabefeld klicken
2. Datei auswaehlen (Bilder, Dokumente, etc.)
3. Datei wird verschluesselt gesendet

## Video- und Audio-Anrufe

Anrufe sind ueber die Buttons in der Chat-Leiste verfuegbar:

- **Kamera-Icon**: Video-Anruf
- **Telefon-Icon**: Audio-Anruf

Aktuell werden Anrufe ueber Element Web gefuehrt. Die native Integration in die App folgt in einem zukuenftigen Update.

## Administration

### Chat-User anlegen

Neue Chat-User werden vom Admin ueber den **Verwaltung-Tab** angelegt:

1. Verwaltung → **"Chat-User anlegen"**
2. Benutzername und Passwort vergeben
3. User kann sich sofort anmelden

### Kompatibilitaet

Der Chat ist kompatibel mit allen Matrix-Clients:

- **Element** (Web, iOS, Android, Desktop)
- **FluffyChat** (iOS, Android)
- **Nheko** (Desktop)
- Und alle weiteren Matrix-Clients
