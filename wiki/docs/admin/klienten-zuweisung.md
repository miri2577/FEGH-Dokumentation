# Klienten zuweisen

## Uebersicht

Admins koennen Klienten bestimmten Teams zuordnen. Dies bestimmt, welche Mitarbeiter Zugriff auf die Klientendaten haben.

## Ablauf

1. Im Verwaltung-Tab auf **"Klient zuweisen"** klicken
2. **Ziel-Team** aus der Dropdown-Liste waehlen
3. Einen oder mehrere **Klienten** per Checkbox auswaehlen
4. **"Zuweisen"** klicken (oben rechts)

## Was passiert bei der Zuweisung

- Die Klientendaten werden verschluesselt (AES-256-GCM)
- Die verschluesselten Daten werden auf HiDrive unter `teams/<teamId>/clients/<clientId>.bin` abgelegt
- Mitarbeiter des Teams koennen die Daten mit ihrem Team-Key entschluesseln
- Mitarbeiter anderer Teams haben keinen Zugriff

## Berechtigungen

| Aktion | Mitarbeiter | Teamleitung | Admin |
|--------|------------|-------------|-------|
| Zugewiesene Klienten ansehen | Ja (eigenes Team) | Ja (eigenes Team) | Ja (alle Teams) |
| Klient einem Team zuweisen | Nein | Nein | Ja |
| Klient anderem Team zuweisen | Nein | Nein | Ja |

## Mehrfachzuweisung

Ein Klient kann theoretisch mehreren Teams zugewiesen werden (z.B. bei Teamwechsel oder geteilter Betreuung). Die Daten werden in jedem Team-Verzeichnis separat abgelegt.
