# FEGH-Dokumentation

Digitale Dokumentations- und Abrechnungs-App für die **Eingliederungshilfe** (SGB IX).
Sie unterstützt Betreuungskräfte bei Verlaufsdokumentation, Terminen, Wirkungsmessung,
Teilhabeplanung und der Abrechnung von Fachleistungsstunden.

> **Prototyp / Beta.** Ausschließlich mit **fiktiven** Demodaten entwickeln – keine echten
> personenbezogenen (Art.-9-DSGVO-) Daten eingeben, solange die organisatorischen
> Datenschutz-Dokumente nicht vorliegen.

## Konzept

- **Flutter-Multiplattform** (Android · iOS · macOS · Linux · Windows · Web), responsiv bis 4K.
- **Ende-zu-Ende-verschlüsselte lokale Ablage** (AES-256-GCM, ein Data-Encryption-Key je
  Datensatz, gewrappt mit einem Master- bzw. Team-Key). Der Speicheranbieter sieht nur
  Ciphertext – kein zentraler Klartext-Server.
- **Cloud-Sync/Backup** über WebDAV (HiDrive Business oder ein self-hosted Stack aus
  Matrix/Conduit + Nextcloud, siehe [`server/`](server/)). Löschungen synchronisieren über
  Tombstones, Änderungen über einen `updatedAt`-Abgleich – ohne Duplikate.
- **Geteilte Basis** im Monorepo [`fegh-shared`](https://github.com/miri2577/fegh-shared)
  (Krypto, Cloud, Backup, Billing/XRechnung, Compliance, Chat, Core, PDF, OIDC) – gemeinsam
  mit der Schwester-App **FEGH-Verwaltung**.

## Fachlicher Umfang

- **Dokumentation & Termine** mit Zielbezug, **Fahrwege** (Nominatim/OSRM, ohne API-Key)
- **Wirkungsmessung** (GAS nach Kiresuk & Sherman, POS-Lebensqualität), **Teilhabeziele** (SMART)
- **Bedarfsermittlung** je Bundesland (Berlin TIB vollständig; BW/NRW/NI u. a. experimentell),
  **Informationsbericht / Formular 101**
- **Abrechnung nach Berliner Modell 2026**: Fachleistungsstunden, **kalkulatorische
  Leistungseinheit (kLE) je Kalendertag**, **HBG-Kontingent (1–12)**, Erbringungsfiktion,
  XRechnung 3.0 (UBL)
- **Arbeitszeit**, Schichten, Freizeitanträge, verschlüsselter Chat

## Handbuch (Wiki)

Ausführliche Anleitungen, Administration und Sicherheit:
**https://miri2577.github.io/FEGH-Dokumentation/** (Quelle unter [`wiki/`](wiki/), MkDocs Material).

## Entwicklung

```bash
flutter pub get
flutter run -d windows      # oder -d macos / -d linux / -d chrome
```

Lokal an den geteilten Paketen arbeiten: `pubspec_overrides.yaml` mit Pfad-Overrides auf einen
Nebenordner-Klon von `fegh-shared` (gitignored). Nach Modelländerungen:
`dart run build_runner build --delete-conflicting-outputs`.

## Lizenz

[AGPL-3.0](LICENSE).
