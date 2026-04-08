// TypeScript types matching the Flutter app models

export type FachleistungsIntervall = 'monatlich' | 'jaehrlich'
export type HilfeTyp = 'familienhilfe' | 'eingliederungshilfe'
export type ArbeitszeitTyp = 'betreuung' | 'buero' | 'fahrt' | 'dokumentation' | 'verwaltung' | 'fortbildung' | 'teambesprechung' | 'sonstige'

export interface FlutterClient {
  id: string
  name: string
  berufsgruppe?: string
  eingliederung?: string
  createdAt: string // ISO date string

  // Stammblatt-Felder
  vorname?: string
  nachname?: string
  geburtsdatum?: string // ISO date string
  betreuungSeit?: string // ISO date string
  kostenuebernahme?: string
  kostenuebernahmeVon?: string // ISO date string
  kostenuebernahmeBis?: string // ISO date string
  fachleistungsstunden?: number
  fachleistungsIntervall?: FachleistungsIntervall
  hilfeTyp?: HilfeTyp
  icfBereiche?: string[]
  verbrauchteStunden: number
}

export interface FlutterAppointment {
  id: string
  clientId: string
  clientName: string
  date: string // ISO date string
  startTime: string // ISO date string
  endTime: string // ISO date string
  notes: string
  recordedText: string
  berufsgruppe: string
  eingliederung: string
  createdAt: string // ISO date string

  // ICF und Fachleistungsstunden Felder
  icfBereiche: string[]
  fachleistungsstunden: number

  // Familienhilfe-spezifische Dokumentationskategorien
  familienhilfeKategorien: string[]
}

export interface FlutterArbeitszeit {
  id: string
  datum: string // ISO date string
  startzeit: string // ISO date string
  endzeit: string // ISO date string
  taetigkeit: string
  notizen: string
  createdAt: string // ISO date string
  clientId?: string // Optional: Verknüpfung zu einem Klienten
  appointmentId?: string // Optional: Verknüpfung zu einem Termin
  typ: ArbeitszeitTyp // Betreuung, Büro, Fahrt, etc.
}

export interface FlutterBackupMetadata {
  backupId: string
  createdAt: string // ISO date string
  deviceName: string
  appVersion: string
  dataVersion: string
}

export interface FlutterAppSettings {
  theme?: string
  notifications?: boolean
  autoBackup?: boolean
  companyName?: string
  [key: string]: any // Flexible für weitere Einstellungen
}

export interface FlutterBackupData {
  metadata: FlutterBackupMetadata
  clients: FlutterClient[]
  appointments: FlutterAppointment[]
  emailTargets: string[]
  settings: FlutterAppSettings
  version: string
  // Optional: Arbeitszeiten falls vorhanden
  arbeitszeiten?: FlutterArbeitszeit[]
}

// Utility types für die Konvertierung
export interface ImportStats {
  clients: number
  appointments: number
  arbeitszeiten: number
  totalTimeHours: number
  errors: string[]
}

export interface ImportResult {
  success: boolean
  stats: ImportStats
  error?: string
}