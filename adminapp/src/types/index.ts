// Mitarbeiter-Typen
export interface Employee {
  id: string
  firstName: string
  lastName: string
  email: string
  phone?: string
  position: string
  department: string
  startDate: string
  contractType: 'fulltime' | 'parttime' | 'temporary'
  weeklyHours: number
  skills: string[]
  isActive: boolean
  createdAt: string
  updatedAt: string
}

// Dienstplan-Typen
export interface Shift {
  id: string
  employeeId: string
  date: string
  startTime: string
  endTime: string
  type: 'regular' | 'overtime' | 'night' | 'weekend'
  location: string
  notes?: string
  status: 'planned' | 'confirmed' | 'completed' | 'cancelled'
  createdAt: string
  updatedAt: string
}

export interface ShiftTemplate {
  id: string
  name: string
  startTime: string
  endTime: string
  type: Shift['type']
  location: string
  requiredSkills: string[]
  maxEmployees: number
}

// Urlaubs-Typen
export interface VacationRequest {
  id: string
  employeeId: string
  startDate: string
  endDate: string
  days: number
  type: 'vacation' | 'sick' | 'personal' | 'training'
  reason?: string
  status: 'pending' | 'approved' | 'rejected' | 'cancelled'
  requestedAt: string
  decidedAt?: string
  decidedBy?: string
  notes?: string
}

export interface VacationBalance {
  employeeId: string
  year: number
  totalDays: number
  usedDays: number
  pendingDays: number
  remainingDays: number
}

// Zeiterfassung-Typen
export interface TimeEntry {
  id: string
  employeeId: string
  date: string
  clockIn: string
  clockOut?: string
  breakMinutes: number
  totalHours: number
  overtime: number
  location: string
  notes?: string
  status: 'active' | 'completed' | 'corrected'
}

// Konfiguration
export interface AppConfig {
  hidriveUrl: string
  username: string
  companyName: string
  businessHours: {
    start: string
    end: string
  }
  overtimeRules: {
    dailyThreshold: number
    weeklyThreshold: number
    rate: number
  }
}

// Verschlüsselung
export interface EncryptedData {
  id: string
  version: number
  algorithm: string
  nonce: string
  ciphertext: string
  tag: string
  metadata?: Record<string, unknown>
  createdAt: string
}

// API Response Typen
export interface ApiResponse<T = unknown> {
  success: boolean
  data?: T
  error?: string
  timestamp: string
}

// Team-Management
export interface Team {
  id: string
  name: string
  description?: string
  leaderId: string
  memberIds: string[]
  skills: string[]
  locations: string[]
  isActive: boolean
  createdAt: string
  updatedAt: string
}

// Statistiken
export interface WorkloadStats {
  employeeId: string
  period: string
  totalHours: number
  regularHours: number
  overtime: number
  shiftsWorked: number
  avgHoursPerDay: number
}

export interface DepartmentStats {
  department: string
  totalEmployees: number
  activeEmployees: number
  totalHours: number
  overtime: number
  vacationDays: number
  sickDays: number
}

// Erweiterte Personalplanung
export interface StaffingRequirement {
  id: string
  date: string
  timeSlot: string
  department: string
  position: string
  requiredCount: number
  minQualification?: string[]
  priority: 'low' | 'medium' | 'high' | 'critical'
  createdAt: string
  updatedAt: string
}

export interface CapacityAlert {
  id: string
  type: 'understaffed' | 'overstaffed' | 'vacation_conflict' | 'overtime_limit' | 'no_coverage'
  severity: 'low' | 'medium' | 'high' | 'critical'
  department: string
  date: string
  timeSlot?: string
  affectedEmployees: string[]
  message: string
  recommendations: string[]
  acknowledged: boolean
  createdAt: string
}

export interface ShiftConflict {
  id: string
  type: 'overlap' | 'rest_violation' | 'qualification_missing' | 'overtime_exceeded'
  severity: 'minor' | 'major' | 'critical'
  employeeId: string
  shiftIds: string[]
  description: string
  resolution?: string
  resolvedAt?: string
  createdAt: string
}

export interface EmployeeAvailability {
  employeeId: string
  date: string
  timeSlots: {
    start: string
    end: string
    availability: 'available' | 'partial' | 'unavailable' | 'preferred'
    reason?: string
  }[]
  constraints?: {
    maxHours?: number
    noConsecutiveShifts?: boolean
    preferredRoles?: string[]
  }
}

export interface SchedulingRule {
  id: string
  name: string
  type: 'minimum_staff' | 'maximum_hours' | 'rest_period' | 'qualification' | 'preference'
  department?: string
  position?: string
  parameters: Record<string, any>
  priority: number
  isActive: boolean
  createdAt: string
  updatedAt: string
}

// Klienten-Typen
export type FachleistungsIntervall = 'monatlich' | 'jaehrlich'
export type HilfeTyp = 'familienhilfe' | 'eingliederungshilfe'

export interface Client {
  id: string
  name: string
  firstName?: string
  lastName?: string
  berufsgruppe?: string
  eingliederung?: string
  createdAt: string

  // Stammblatt-Felder
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

  // Zusätzliche Admin-Felder
  isActive: boolean
  assignedEmployee?: string // ID des zugewiesenen Mitarbeiters
  notes?: string
  updatedAt: string
}

export interface Appointment {
  id: string
  clientId: string
  employeeId?: string
  date: string // ISO date string
  startTime: string
  endTime: string
  type: 'betreuung' | 'beratung' | 'hausbesuch' | 'begleitung' | 'therapie' | 'sonstige'
  location?: string
  notes: string
  icfBereiche?: string[]
  fachleistungsstunden: number
  status: 'geplant' | 'durchgefuehrt' | 'abgesagt' | 'verschoben'
  createdAt: string
  updatedAt: string
}