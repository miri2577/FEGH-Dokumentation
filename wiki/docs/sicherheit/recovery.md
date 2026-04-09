# Passwort-Recovery

## Recovery-Hierarchie

| Wer vergisst Passwort | Wer kann helfen | Methode |
|-----------------------|-----------------|---------|
| Mitarbeiter | Teamleitung oder Admin | Recovery-Token |
| Teamleitung | Admin | Recovery-Token |
| Admin | Nur selbst | 12-Wort Recovery-Key |

## Recovery-Token (Mitarbeiter/Teamleitung)

### Ablauf

1. Teamleitung/Admin generiert einen **Recovery-Token** fuer den betroffenen Mitarbeiter
2. Token wird mit einem neuen 6-stelligen PIN verschluesselt
3. PIN wird separat uebermittelt (muendlich, SMS)
4. Mitarbeiter gibt Token + PIN in der App ein
5. Passwort wird zurueckgesetzt, lokale Daten bleiben erhalten

### Token-Eigenschaften

- Gueltigkeitsdauer: **24 Stunden** (danach ungueltig)
- Verschluesselung: AES-256-GCM mit PIN-abgeleitetem Schluessel
- Einmalig verwendbar
- Enthaelt Mitarbeiter-ID und Ablaufzeitpunkt

## Admin Recovery-Key

### Generierung

Der Recovery-Key wird bei der **Organisationsinitialisierung** einmalig generiert und angezeigt:

- **12 deutsche Woerter** (z.B. "Adler Brücke Flamme Gold Herbst Jade Kliff Lilie Muschel Olive Rubin Stern")
- Aus einer Liste von 128 deutschen Woertern
- Kryptographisch sichere Zufallsauswahl

### Sicherung

!!! danger "Wichtig"
    Ohne den Recovery-Key ist bei Admin-Passwortverlust **kein Zugriff auf die verschluesselten Daten moeglich**. Dies wird beim Setup klar kommuniziert.

Empfohlene Aufbewahrung:

- Ausdrucken und im Safe verwahren
- **Nicht** digital speichern (kein Screenshot, kein Cloud-Speicher)
- Mehrere Kopien an verschiedenen sicheren Orten

### Wiederherstellung

1. Der Recovery-Key wird als PBKDF2-Input verwendet (50.000 Iterationen HMAC-SHA256)
2. Der daraus abgeleitete Schluessel entschluesselt den gesicherten MEK
3. Mit dem wiederhergestellten MEK koennen alle Daten entschluesselt werden
4. Ein neues Passwort kann gesetzt werden
