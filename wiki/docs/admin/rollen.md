# Rollen und Berechtigungen

## Rollensystem

Die App verwendet ein abgestuftes Rollenmodell mit 5 Rollen:

| Rolle | Beschreibung |
|-------|-------------|
| **Organisations-Admin** (`orgAdmin`) | Vollzugriff auf alle Funktionen und Daten der Organisation |
| **PV-Admin** (`pvAdmin`) | Personalverwaltungs-Admin, gleiche Rechte wie Org-Admin |
| **Teamleitung** (`teamLead`) | Erweiterte Rechte im eigenen Team |
| **Mitarbeiter** (`teamMember`) | Standard-Dokumentationsrechte im eigenen Team |
| **Pruefer** (`orgAuditor`) | Nur Lesezugriff, fuer Audits und Pruefungen |

## Berechtigungsmatrix

### Klienten

| Aktion | Mitarbeiter | Teamleitung | Admin | Pruefer |
|--------|:-----------:|:-----------:|:-----:|:-------:|
| Klienten ansehen (eigenes Team) | Ja | Ja | Ja | Ja |
| Dokumentation bearbeiten | Ja | Ja | Ja | Nein |
| Neuen Klient anlegen | Nein | Ja | Ja | Nein |
| Stammdaten aendern | Nein | Ja | Ja | Nein |
| Klient loeschen/archivieren | Nein | Nein | Ja | Nein |
| Klient anderem Team zuweisen | Nein | Nein | Ja | Nein |

### Termine und Berichte

| Aktion | Mitarbeiter | Teamleitung | Admin | Pruefer |
|--------|:-----------:|:-----------:|:-----:|:-------:|
| Termine verwalten | Ja | Ja | Ja | Nein |
| Berichte schreiben | Ja | Ja | Ja | Nein |
| Berichte exportieren | Ja | Ja | Ja | Ja |

### Arbeitszeit

| Aktion | Mitarbeiter | Teamleitung | Admin | Pruefer |
|--------|:-----------:|:-----------:|:-----:|:-------:|
| Eigene Arbeitszeit erfassen | Ja | Ja | Ja | Nein |
| Arbeitszeit anderer einsehen | Nein | Ja | Ja | Nein |

### Organisation und Teams

| Aktion | Mitarbeiter | Teamleitung | Admin | Pruefer |
|--------|:-----------:|:-----------:|:-----:|:-------:|
| Teams erstellen/bearbeiten | Nein | Nein | Ja | Nein |
| Mitarbeiter einladen | Nein | Ja | Ja | Nein |
| Rollen aendern | Nein | Nein | Ja | Nein |
| Organisation verwalten | Nein | Nein | Ja | Nein |
| Verwaltung-Tab sehen | Nein | Nein | Ja | Nein |
| Admin-Tools nutzen | Nein | Nein | Ja | Nein |

### Recovery und Audit

| Aktion | Mitarbeiter | Teamleitung | Admin | Pruefer |
|--------|:-----------:|:-----------:|:-----:|:-------:|
| Recovery-Token fuer Mitarbeiter | Nein | Ja | Ja | Nein |
| Recovery-Token fuer Teamleitung | Nein | Nein | Ja | Nein |
| Audit-Log einsehen | Nein | Nein | Ja | Ja |

## Rollen-Verwaltung auf HiDrive

Die Rollenzuordnung wird in einer `roles.json`-Datei auf HiDrive gespeichert:

```
administration/users/roles.bin
```

Format:
```json
{
  "users": [
    {
      "id": "admin@example.com",
      "role": "org_admin",
      "teams": []
    },
    {
      "id": "mitarbeiter@example.com",
      "role": "team_member",
      "teams": ["team-nord"]
    }
  ],
  "createdAt": "2026-04-08T..."
}
```

## Rolle aendern

Nur Organisations-Admins und PV-Admins koennen Rollen aendern. Die Aenderung wird in der `roles.json` auf HiDrive aktualisiert und ist sofort wirksam.
