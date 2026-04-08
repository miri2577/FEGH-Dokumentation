import type {
  FlutterBackupData,
  FlutterClient,
  FlutterAppointment,
  FlutterArbeitszeit,
  ImportResult,
  ImportStats
} from '../types/flutter'
import type { Employee, Client, Shift, VacationRequest, Appointment } from '../types'

export class FlutterDataConverter {

  /**
   * Konvertiert Flutter-Clients zu Electron-Clients
   */
  static convertClientsToClients(clients: FlutterClient[]): Client[] {
    return clients.map(client => ({
      id: client.id,
      name: client.name,
      firstName: client.vorname,
      lastName: client.nachname,
      berufsgruppe: client.berufsgruppe,
      eingliederung: client.eingliederung,
      createdAt: client.createdAt,

      // Stammblatt-Felder
      geburtsdatum: client.geburtsdatum,
      betreuungSeit: client.betreuungSeit,
      kostenuebernahme: client.kostenuebernahme,
      kostenuebernahmeVon: client.kostenuebernahmeVon,
      kostenuebernahmeBis: client.kostenuebernahmeBis,
      fachleistungsstunden: client.fachleistungsstunden,
      fachleistungsIntervall: client.fachleistungsIntervall,
      hilfeTyp: client.hilfeTyp,
      icfBereiche: client.icfBereiche,
      verbrauchteStunden: client.verbrauchteStunden || 0,

      // Admin-Felder
      isActive: true,
      notes: '',
      updatedAt: new Date().toISOString()
    }))
  }

  /**
   * Konvertiert Flutter-Clients zu Electron-Employees (für Kapazitätsplanung)
   */
  static convertClientsToEmployees(clients: FlutterClient[]): Employee[] {
    return clients.map(client => ({
      id: client.id,
      firstName: client.vorname || client.name.split(' ')[0] || 'Unbekannt',
      lastName: client.nachname || client.name.split(' ').slice(1).join(' ') || '',
      email: `${(client.vorname || client.name).toLowerCase().replace(/\s/g, '')}@klient.local`,
      phone: '', // Not available in Flutter client data
      position: this.mapHilfeTypToPosition(client.hilfeTyp),
      department: this.mapBerufsruppeToDepatment(client.berufsgruppe),
      startDate: client.betreuungSeit || client.createdAt,
      contractType: 'fulltime' as const, // Default assumption
      weeklyHours: this.calculateWeeklyHoursFromFLS(client.fachleistungsstunden, client.fachleistungsIntervall),
      skills: client.icfBereiche || [],
      isActive: true, // Assume all imported clients are active
      createdAt: client.createdAt,
      updatedAt: new Date().toISOString()
    }))
  }

  /**
   * Konvertiert Flutter-Appointments zu Electron-Appointments
   */
  static convertAppointmentsToAppointments(appointments: FlutterAppointment[]): Appointment[] {
    return appointments.map(appointment => {
      const date = new Date(appointment.date)
      const startTime = new Date(appointment.startTime)
      const endTime = new Date(appointment.endTime)

      return {
        id: appointment.id,
        clientId: appointment.clientId,
        date: date.toISOString().split('T')[0],
        startTime: this.formatTime(startTime),
        endTime: this.formatTime(endTime),
        type: this.mapAppointmentType(appointment),
        notes: `${appointment.notes}\n\nAufzeichnung: ${appointment.recordedText}`,
        icfBereiche: appointment.icfBereiche,
        fachleistungsstunden: appointment.fachleistungsstunden,
        status: 'durchgefuehrt' as const,
        createdAt: appointment.createdAt,
        updatedAt: new Date().toISOString()
      }
    })
  }

  /**
   * Konvertiert Flutter-Appointments zu Electron-Shifts (für Dienstplanung)
   */
  static convertAppointmentsToShifts(appointments: FlutterAppointment[], clients: FlutterClient[]): Shift[] {
    return appointments.map(appointment => {
      const client = clients.find(c => c.id === appointment.clientId)
      const date = new Date(appointment.date)
      const startTime = new Date(appointment.startTime)
      const endTime = new Date(appointment.endTime)

      return {
        id: appointment.id,
        employeeId: appointment.clientId, // Using client as employee for mapping
        date: date.toISOString().split('T')[0],
        startTime: this.formatTime(startTime),
        endTime: this.formatTime(endTime),
        type: this.mapAppointmentToShiftType(appointment),
        location: client?.berufsgruppe || 'Kliententermin',
        notes: `${appointment.notes}\n\nAufzeichnung: ${appointment.recordedText}`,
        status: 'completed' as const, // Past appointments are completed
        createdAt: appointment.createdAt,
        updatedAt: new Date().toISOString()
      }
    })
  }

  /**
   * Konvertiert Flutter-Arbeitszeiten zu Electron-Shifts (ergänzend)
   */
  static convertArbeitszeitenToShifts(arbeitszeiten: FlutterArbeitszeit[]): Shift[] {
    return arbeitszeiten.map(az => {
      const date = new Date(az.datum)
      const startTime = new Date(az.startzeit)
      const endTime = new Date(az.endzeit)

      return {
        id: az.id,
        employeeId: az.clientId || 'system',
        date: date.toISOString().split('T')[0],
        startTime: this.formatTime(startTime),
        endTime: this.formatTime(endTime),
        type: this.mapArbeitszeitTypToShiftType(az.typ),
        location: az.taetigkeit,
        notes: az.notizen,
        status: 'completed' as const,
        createdAt: az.createdAt,
        updatedAt: new Date().toISOString()
      }
    })
  }

  /**
   * Erstellt Sample-Urlaubsanträge basierend auf Klientendaten
   */
  static generateSampleVacationRequests(clients: FlutterClient[]): VacationRequest[] {
    // Generiere einige realistische Urlaubsanträge basierend auf Klientenbetreuung
    const requests: VacationRequest[] = []

    clients.slice(0, 3).forEach((client, index) => {
      const baseDate = new Date()
      baseDate.setDate(baseDate.getDate() + (index * 30) + 7) // Verteilt über nächste Monate

      requests.push({
        id: `vacation-${client.id}-${index}`,
        employeeId: client.id,
        startDate: baseDate.toISOString().split('T')[0],
        endDate: new Date(baseDate.getTime() + (5 * 24 * 60 * 60 * 1000)).toISOString().split('T')[0], // 5 Tage
        days: 5,
        type: index === 0 ? 'vacation' : index === 1 ? 'training' : 'personal',
        reason: index === 0 ? 'Jahresurlaub' : index === 1 ? 'Fortbildung Eingliederungshilfe' : 'Persönliche Angelegenheit',
        status: index === 0 ? 'pending' : 'approved',
        requestedAt: new Date().toISOString(),
        notes: `Generiert aus Klientendaten: ${client.name}`
      })
    })

    return requests
  }

  /**
   * Analysiert die importierten Daten und erstellt Statistiken
   */
  static analyzeImportData(backupData: FlutterBackupData): ImportStats {
    const stats: ImportStats = {
      clients: backupData.clients.length,
      appointments: backupData.appointments.length,
      arbeitszeiten: backupData.arbeitszeiten?.length || 0,
      totalTimeHours: 0,
      errors: []
    }

    // Berechne Gesamtstunden aus Terminen
    backupData.appointments.forEach(appointment => {
      try {
        const start = new Date(appointment.startTime)
        const end = new Date(appointment.endTime)
        const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60)
        stats.totalTimeHours += hours
      } catch (error) {
        stats.errors.push(`Fehler bei Terminberechnung für ${appointment.id}: ${error}`)
      }
    })

    // Berechne Gesamtstunden aus Arbeitszeiten
    backupData.arbeitszeiten?.forEach(az => {
      try {
        const start = new Date(az.startzeit)
        const end = new Date(az.endzeit)
        const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60)
        stats.totalTimeHours += hours
      } catch (error) {
        stats.errors.push(`Fehler bei Arbeitszeitberechnung für ${az.id}: ${error}`)
      }
    })

    return stats
  }

  // Hilfsmethoden

  private static mapHilfeTypToPosition(hilfeTyp?: string): string {
    switch (hilfeTyp) {
      case 'familienhilfe':
        return 'Familienhelfer/in'
      case 'eingliederungshilfe':
        return 'Eingliederungshelfer/in'
      default:
        return 'Sozialarbeiter/in'
    }
  }

  private static mapBerufsruppeToDepatment(berufsgruppe?: string): string {
    if (!berufsgruppe) return 'Allgemein'

    // Mapping häufiger Berufsgruppen
    const mappings: Record<string, string> = {
      'sozialarbeiter': 'Sozialarbeit',
      'heilerzieher': 'Heilerziehungspflege',
      'erzieher': 'Pädagogik',
      'therapeut': 'Therapie',
      'pfleger': 'Pflege'
    }

    const key = berufsgruppe.toLowerCase()
    for (const [pattern, department] of Object.entries(mappings)) {
      if (key.includes(pattern)) {
        return department
      }
    }

    return berufsgruppe
  }

  private static calculateWeeklyHoursFromFLS(fls?: number, intervall?: string): number {
    if (!fls) return 39 // Default 39h/Woche

    if (intervall === 'monatlich') {
      return Math.round(fls / 4.33) // Berlin-Faktor rückwärts
    } else if (intervall === 'jaehrlich') {
      return Math.round(fls / 52)
    }

    return Math.min(fls, 40) // Max 40h/Woche
  }

  private static formatTime(date: Date): string {
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
  }

  private static mapAppointmentType(appointment: FlutterAppointment): Appointment['type'] {
    // Map appointment types based on content or default
    if (appointment.notes.toLowerCase().includes('hausbesuch')) {
      return 'hausbesuch'
    } else if (appointment.notes.toLowerCase().includes('beratung')) {
      return 'beratung'
    } else if (appointment.notes.toLowerCase().includes('begleitung')) {
      return 'begleitung'
    } else if (appointment.notes.toLowerCase().includes('therapie')) {
      return 'therapie'
    } else {
      return 'betreuung'
    }
  }

  private static mapAppointmentToShiftType(appointment: FlutterAppointment): Shift['type'] {
    const duration = new Date(appointment.endTime).getTime() - new Date(appointment.startTime).getTime()
    const hours = duration / (1000 * 60 * 60)

    if (hours > 8) return 'overtime'

    const startHour = new Date(appointment.startTime).getHours()
    if (startHour >= 22 || startHour < 6) return 'night'

    const dayOfWeek = new Date(appointment.date).getDay()
    if (dayOfWeek === 0 || dayOfWeek === 6) return 'weekend'

    return 'regular'
  }

  private static mapArbeitszeitTypToShiftType(typ: string): Shift['type'] {
    switch (typ) {
      case 'betreuung':
        return 'regular'
      case 'buero':
      case 'verwaltung':
      case 'dokumentation':
        return 'regular'
      case 'fortbildung':
      case 'teambesprechung':
        return 'regular'
      default:
        return 'regular'
    }
  }
}

/**
 * Validiert Flutter-Backup-Daten
 */
export function validateFlutterBackup(data: any): data is FlutterBackupData {
  try {
    console.log('🔍 Validating backup data:', {
      hasData: !!data,
      hasMetadata: !!data?.metadata,
      hasClients: Array.isArray(data?.clients),
      clientsCount: data?.clients?.length,
      hasAppointments: Array.isArray(data?.appointments),
      appointmentsCount: data?.appointments?.length,
      hasEmailTargets: Array.isArray(data?.emailTargets),
      hasSettings: !!data?.settings,
      hasVersion: typeof data?.version === 'string',
      version: data?.version
    })

    const isValid = (
      data &&
      typeof data === 'object' &&
      data.metadata &&
      typeof data.metadata === 'object' &&
      Array.isArray(data.clients) &&
      Array.isArray(data.appointments) &&
      Array.isArray(data.emailTargets) &&
      data.settings &&
      typeof data.settings === 'object' &&
      typeof data.version === 'string'
    )

    console.log('✓ Validation result:', isValid)
    return isValid
  } catch (error) {
    console.error('❌ Validation error:', error)
    return false
  }
}

/**
 * Importiert Flutter-Backup-Daten in das Electron-App-Format
 */
export async function importFlutterBackup(backupData: FlutterBackupData): Promise<ImportResult> {
  try {
    console.log('🚀 Starting import process with data:', backupData)
    const stats = FlutterDataConverter.analyzeImportData(backupData)
    console.log('📊 Import stats:', stats)

    // Konvertiere die Daten
    const clients = FlutterDataConverter.convertClientsToClients(backupData.clients)
    console.log('👥 Converted clients:', clients.length)

    const appointments = FlutterDataConverter.convertAppointmentsToAppointments(backupData.appointments)
    console.log('📅 Converted appointments:', appointments.length)

    const employees = FlutterDataConverter.convertClientsToEmployees(backupData.clients)
    console.log('👔 Converted employees:', employees.length)

    const appointmentShifts = FlutterDataConverter.convertAppointmentsToShifts(backupData.appointments, backupData.clients)
    const arbeitszeitShifts = backupData.arbeitszeiten
      ? FlutterDataConverter.convertArbeitszeitenToShifts(backupData.arbeitszeiten)
      : []
    const vacationRequests = FlutterDataConverter.generateSampleVacationRequests(backupData.clients)

    // Alle Shifts kombinieren
    const allShifts = [...appointmentShifts, ...arbeitszeitShifts]
    console.log('🔄 Total shifts:', allShifts.length)

    // Speichere die konvertierten Daten in den globalen Mock-Daten
    // (In Produktionsumgebung würde das über die echte API gehen)
    const isDevMode = await window.electronAPI?.dev?.isDevMode()
    console.log('🔧 Dev mode check:', isDevMode)
    if (isDevMode) {
      // Aktualisiere Mock-Daten für Dev-Mode
      window._importedData = {
        clients,
        employees,
        shifts: allShifts,
        vacationRequests,
        originalBackup: backupData
      }
      console.log('✅ Imported data stored in window._importedData:', window._importedData)
    }

    return {
      success: true,
      stats
    }
  } catch (error) {
    console.error('❌ Import error:', error)
    return {
      success: false,
      stats: {
        clients: 0,
        appointments: 0,
        arbeitszeiten: 0,
        totalTimeHours: 0,
        errors: [error instanceof Error ? error.message : 'Unbekannter Fehler']
      },
      error: error instanceof Error ? error.message : 'Import fehlgeschlagen'
    }
  }
}