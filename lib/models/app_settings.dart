import 'package:json_annotation/json_annotation.dart';
import 'ui_customization.dart';

part 'app_settings.g.dart';

enum UserRole {
  @JsonValue('org_admin')
  orgAdmin,
  @JsonValue('pv_admin')
  pvAdmin,
  @JsonValue('team_lead')
  teamLead,
  @JsonValue('team_member')
  teamMember,
  @JsonValue('org_auditor')
  orgAuditor,
}

@JsonSerializable()
class AppSettings {
  final String userName;
  final UserRole userRole;
  final bool speechAvailable;
  final List<String> calendarKeywords;
  final List<String> clientNamePatterns;
  final List<String> berufsgruppen;
  final List<String> eingliederungsarten;
  final bool biometricAuthEnabled;
  final bool autoBackupEnabled;
  final int autoBackupInterval; // in days
  final String preferredLanguage;
  final bool darkModeEnabled;
  final bool notificationsEnabled;
  final double wochenarbeitszeit; // Stunden pro Woche
  final int urlaubstage; // Urlaubstage pro Jahr
  final String hidriveUsername; // HiDrive-Benutzername
  final String hidrivePassword; // HiDrive-Passwort (verschlüsselt gespeichert)
  final String organizationId; // Organisation/Träger ID für Multi-Team Setup
  final String teamId; // Team ID für granulare Zugriffsrechte
  final String syncPassphrase; // Gemeinsame Sync-Passphrase (optional, nicht exportieren)
  final String rootSubdirectory; // Optionaler Root-Unterordner (z. B. Gemeinsam/Eingliederungshilfe)
  final bool auditorCanViewDocs; // Auditor darf Dokumentation lesen
  final bool setupCompleted; // Ersteinrichtungs-Wizard abgeschlossen
  final double kalkulationsfaktor; // KLE-Faktor: Gesamtarbeitszeit / abrechnungsfähige Zeit (Berlin-typisch: 1,25–1,33)
  final double stundensatz; // Vergütung pro Fachleistungsstunde in EUR
  final String? bueroStandortId; // Standard-Startort des Mitarbeiters
  final String openRouteServiceApiKey; // API-Key fuer Online-Distanzberechnung
  final String totpSecret; // TOTP-Secret (Base32) fuer 2FA, leer = kein TOTP
  @JsonKey(fromJson: _uiCustomizationFromJson, toJson: _uiCustomizationToJson)
  final UICustomization uiCustomization;

  AppSettings({
    required this.userName,
    this.userRole = UserRole.teamMember,
    required this.speechAvailable,
    required this.calendarKeywords,
    required this.clientNamePatterns,
    required this.berufsgruppen,
    required this.eingliederungsarten,
    required this.biometricAuthEnabled,
    required this.autoBackupEnabled,
    required this.autoBackupInterval,
    required this.preferredLanguage,
    required this.darkModeEnabled,
    required this.notificationsEnabled,
    required this.wochenarbeitszeit,
    required this.urlaubstage,
    required this.hidriveUsername,
    required this.hidrivePassword,
    required this.organizationId,
    required this.teamId,
    required this.syncPassphrase,
    required this.rootSubdirectory,
    required this.auditorCanViewDocs,
    this.setupCompleted = false,
    this.kalkulationsfaktor = 1.33,
    this.stundensatz = 40.0,
    this.bueroStandortId,
    this.openRouteServiceApiKey = '',
    this.totpSecret = '',
    this.uiCustomization = const UICustomization(),
  });

  bool get isAdmin => userRole == UserRole.orgAdmin || userRole == UserRole.pvAdmin;

  AppSettings.defaultSettings()
      : userName = "",
        userRole = UserRole.teamMember,
        speechAvailable = false,
        calendarKeywords = [
          "Eingliederungshilfe",
          "Beratung",
          "Termin",
          "Gespräch",
          "Sozial",
          "Rehabilitation"
        ],
        clientNamePatterns = [],
        berufsgruppen = [
          "Sozialpädagoge/in",
          "Ergotherapeut/in", 
          "Physiotherapeut/in",
          "Psychologe/in",
          "Sozialarbeiter/in",
          "Heilerziehungspfleger/in",
          "Gesundheits- und Krankenpfleger/in"
        ],
        eingliederungsarten = [
          "Berufliche Rehabilitation",
          "Soziale Teilhabe",
          "Medizinische Rehabilitation", 
          "Schulische Integration",
          "Wohnbegleitung",
          "Arbeitsplatzvermittlung",
          "Lebenshilfe"
        ],
        biometricAuthEnabled = true,
        autoBackupEnabled = false,
        autoBackupInterval = 7,
        preferredLanguage = "de-DE",
        darkModeEnabled = false,
        notificationsEnabled = true,
        wochenarbeitszeit = 40.0,
        urlaubstage = 30,
        hidriveUsername = "",
        hidrivePassword = "",
        organizationId = "",
        teamId = "",
        syncPassphrase = "",
        rootSubdirectory = "",
        auditorCanViewDocs = false,
        setupCompleted = false,
        kalkulationsfaktor = 1.33,
        stundensatz = 40.0,
        bueroStandortId = null,
        openRouteServiceApiKey = '',
        totpSecret = '',
        uiCustomization = const UICustomization();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // Migration: alte isAdmin bool → neue userRole
    if (!json.containsKey('userRole') && json.containsKey('isAdmin')) {
      json['userRole'] = (json['isAdmin'] == true) ? 'org_admin' : 'team_member';
    }
    return _$AppSettingsFromJson(json);
  }
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  AppSettings copyWith({
    String? userName,
    UserRole? userRole,
    bool? isAdmin,
    bool? speechAvailable,
    List<String>? calendarKeywords,
    List<String>? clientNamePatterns,
    List<String>? berufsgruppen,
    List<String>? eingliederungsarten,
    bool? biometricAuthEnabled,
    bool? autoBackupEnabled,
    int? autoBackupInterval,
    String? preferredLanguage,
    bool? darkModeEnabled,
    bool? notificationsEnabled,
    double? wochenarbeitszeit,
    int? urlaubstage,
    String? hidriveUsername,
    String? hidrivePassword,
    String? organizationId,
    String? teamId,
    String? syncPassphrase,
    String? rootSubdirectory,
    bool? auditorCanViewDocs,
    bool? setupCompleted,
    double? kalkulationsfaktor,
    double? stundensatz,
    String? bueroStandortId,
    String? openRouteServiceApiKey,
    String? totpSecret,
    UICustomization? uiCustomization,
  }) {
    return AppSettings(
      userName: userName ?? this.userName,
      userRole: isAdmin != null
          ? (isAdmin ? UserRole.orgAdmin : UserRole.teamMember)
          : (userRole ?? this.userRole),
      speechAvailable: speechAvailable ?? this.speechAvailable,
      calendarKeywords: calendarKeywords ?? this.calendarKeywords,
      clientNamePatterns: clientNamePatterns ?? this.clientNamePatterns,
      berufsgruppen: berufsgruppen ?? this.berufsgruppen,
      eingliederungsarten: eingliederungsarten ?? this.eingliederungsarten,
      biometricAuthEnabled: biometricAuthEnabled ?? this.biometricAuthEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupInterval: autoBackupInterval ?? this.autoBackupInterval,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      wochenarbeitszeit: wochenarbeitszeit ?? this.wochenarbeitszeit,
      urlaubstage: urlaubstage ?? this.urlaubstage,
      hidriveUsername: hidriveUsername ?? this.hidriveUsername,
      hidrivePassword: hidrivePassword ?? this.hidrivePassword,
      organizationId: organizationId ?? this.organizationId,
      teamId: teamId ?? this.teamId,
      syncPassphrase: syncPassphrase ?? this.syncPassphrase,
      rootSubdirectory: rootSubdirectory ?? this.rootSubdirectory,
      auditorCanViewDocs: auditorCanViewDocs ?? this.auditorCanViewDocs,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      kalkulationsfaktor: kalkulationsfaktor ?? this.kalkulationsfaktor,
      stundensatz: stundensatz ?? this.stundensatz,
      bueroStandortId: bueroStandortId ?? this.bueroStandortId,
      openRouteServiceApiKey: openRouteServiceApiKey ?? this.openRouteServiceApiKey,
      totpSecret: totpSecret ?? this.totpSecret,
      uiCustomization: uiCustomization ?? this.uiCustomization,
    );
  }
}

UICustomization _uiCustomizationFromJson(Map<String, dynamic>? json) =>
    json != null ? UICustomization.fromJson(json) : const UICustomization();

Map<String, dynamic> _uiCustomizationToJson(UICustomization ui) => ui.toJson();
