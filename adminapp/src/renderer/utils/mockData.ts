import { Employee, Shift, VacationRequest } from '../../types'

// Mock Employees for Development
export const mockEmployees: Employee[] = [
  {
    id: '1',
    firstName: 'Anna',
    lastName: 'Schmidt',
    email: 'anna.schmidt@beispiel.de',
    phone: '0171 1234567',
    position: 'Heilerziehungspflegerin',
    department: 'Wohnbereich A',
    startDate: '2022-03-15',
    contractType: 'fulltime',
    weeklyHours: 39,
    skills: ['Pflege', 'Betreuung', 'Erste Hilfe', 'Medikamentengabe'],
    isActive: true,
    createdAt: '2022-03-15T08:00:00Z',
    updatedAt: '2024-01-15T10:30:00Z'
  },
  {
    id: '2',
    firstName: 'Thomas',
    lastName: 'Mueller',
    email: 'thomas.mueller@beispiel.de',
    phone: '0172 2345678',
    position: 'Sozialarbeiter',
    department: 'Tagesstätte',
    startDate: '2021-09-01',
    contractType: 'fulltime',
    weeklyHours: 40,
    skills: ['Pädagogik', 'Beratung', 'Krisenintervention', 'Dokumentation'],
    isActive: true,
    createdAt: '2021-09-01T08:00:00Z',
    updatedAt: '2024-02-10T14:20:00Z'
  },
  {
    id: '3',
    firstName: 'Sarah',
    lastName: 'Weber',
    email: 'sarah.weber@beispiel.de',
    phone: '0173 3456789',
    position: 'Erzieherin',
    department: 'Wohnbereich B',
    startDate: '2023-01-10',
    contractType: 'parttime',
    weeklyHours: 25,
    skills: ['Pädagogik', 'Betreuung', 'Aktivierung', 'Teamleitung'],
    isActive: true,
    createdAt: '2023-01-10T08:00:00Z',
    updatedAt: '2024-03-05T09:15:00Z'
  },
  {
    id: '4',
    firstName: 'Michael',
    lastName: 'Wagner',
    email: 'michael.wagner@beispiel.de',
    phone: '0174 4567890',
    position: 'Pflegefachkraft',
    department: 'Wohnbereich A',
    startDate: '2020-06-01',
    contractType: 'fulltime',
    weeklyHours: 39,
    skills: ['Pflege', 'Medikamentengabe', 'Notfallversorgung', 'Qualitätsmanagement'],
    isActive: true,
    createdAt: '2020-06-01T08:00:00Z',
    updatedAt: '2024-01-20T16:45:00Z'
  },
  {
    id: '5',
    firstName: 'Julia',
    lastName: 'Fischer',
    email: 'julia.fischer@beispiel.de',
    phone: '0175 5678901',
    position: 'Betreuungsassistentin',
    department: 'Werkstatt',
    startDate: '2023-08-15',
    contractType: 'temporary',
    weeklyHours: 30,
    skills: ['Betreuung', 'Aktivierung', 'Hauswirtschaft'],
    isActive: true,
    createdAt: '2023-08-15T08:00:00Z',
    updatedAt: '2024-02-28T11:30:00Z'
  }
]

// Mock Shifts for Development
export const mockShifts: Shift[] = [
  {
    id: 'shift1',
    employeeId: '1',
    date: '2024-09-17',
    startTime: '06:00',
    endTime: '14:00',
    type: 'regular',
    location: 'Wohnbereich A',
    notes: 'Frühdienst, Medikamente um 8 Uhr',
    status: 'confirmed',
    createdAt: '2024-09-15T10:00:00Z',
    updatedAt: '2024-09-15T10:00:00Z'
  },
  {
    id: 'shift2',
    employeeId: '2',
    date: '2024-09-17',
    startTime: '08:00',
    endTime: '16:00',
    type: 'regular',
    location: 'Tagesstätte',
    notes: 'Gruppenaktivitäten leiten',
    status: 'planned',
    createdAt: '2024-09-15T10:00:00Z',
    updatedAt: '2024-09-15T10:00:00Z'
  },
  {
    id: 'shift3',
    employeeId: '3',
    date: '2024-09-18',
    startTime: '14:00',
    endTime: '22:00',
    type: 'regular',
    location: 'Wohnbereich B',
    notes: 'Spätdienst, Abendroutine',
    status: 'planned',
    createdAt: '2024-09-15T10:00:00Z',
    updatedAt: '2024-09-15T10:00:00Z'
  },
  {
    id: 'shift4',
    employeeId: '4',
    date: '2024-09-19',
    startTime: '22:00',
    endTime: '06:00',
    type: 'night',
    location: 'Wohnbereich A',
    notes: 'Nachtdienst, Bereitschaft',
    status: 'planned',
    createdAt: '2024-09-15T10:00:00Z',
    updatedAt: '2024-09-15T10:00:00Z'
  },
  {
    id: 'shift5',
    employeeId: '1',
    date: '2024-09-21',
    startTime: '06:00',
    endTime: '18:00',
    type: 'overtime',
    location: 'Wohnbereich A',
    notes: 'Doppelschicht wegen Personalausfall',
    status: 'confirmed',
    createdAt: '2024-09-15T10:00:00Z',
    updatedAt: '2024-09-15T10:00:00Z'
  }
]

// Mock Vacation Requests for Development
export const mockVacationRequests: VacationRequest[] = [
  {
    id: 'vacation1',
    employeeId: '1',
    startDate: '2024-10-15',
    endDate: '2024-10-25',
    days: 11,
    type: 'vacation',
    reason: 'Herbsturlaub mit Familie',
    status: 'pending',
    requestedAt: '2024-09-10T09:30:00Z',
    notes: 'Wichtiger Familienurlaub, bereits gebucht'
  },
  {
    id: 'vacation2',
    employeeId: '2',
    startDate: '2024-09-20',
    endDate: '2024-09-20',
    days: 1,
    type: 'sick',
    reason: 'Grippe',
    status: 'approved',
    requestedAt: '2024-09-19T07:15:00Z',
    decidedAt: '2024-09-19T08:00:00Z',
    decidedBy: 'Anna Schmidt',
    notes: 'Ärztliche Bescheinigung liegt vor'
  },
  {
    id: 'vacation3',
    employeeId: '3',
    startDate: '2024-11-05',
    endDate: '2024-11-08',
    days: 4,
    type: 'training',
    reason: 'Fortbildung Krisenintervention',
    status: 'approved',
    requestedAt: '2024-08-15T14:20:00Z',
    decidedAt: '2024-08-16T10:30:00Z',
    decidedBy: 'Thomas Mueller',
    notes: 'Anmeldung bereits erfolgt, Kosten übernommen'
  },
  {
    id: 'vacation4',
    employeeId: '4',
    startDate: '2024-12-23',
    endDate: '2024-12-30',
    days: 8,
    type: 'vacation',
    reason: 'Weihnachtsurlaub',
    status: 'rejected',
    requestedAt: '2024-09-05T16:45:00Z',
    decidedAt: '2024-09-06T09:00:00Z',
    decidedBy: 'Personalleitung',
    notes: 'Zu viele Urlaubsanträge in diesem Zeitraum'
  },
  {
    id: 'vacation5',
    employeeId: '5',
    startDate: '2024-09-25',
    endDate: '2024-09-25',
    days: 1,
    type: 'personal',
    reason: 'Arzttermin Zahnarzt',
    status: 'pending',
    requestedAt: '2024-09-17T12:00:00Z',
    notes: 'Wichtiger Kontrolltermin'
  }
]

// Mock function to simulate API calls with delay
export function mockApiCall<T>(data: T, delay = 500): Promise<{ success: true; data: T }> {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve({ success: true, data })
    }, delay)
  })
}

// Get current data (imported or mock)
export function getCurrentEmployees(): Employee[] {
  return window._importedData?.employees || mockEmployees
}

export function getCurrentShifts(): Shift[] {
  return window._importedData?.shifts || mockShifts
}

export function getCurrentVacationRequests(): VacationRequest[] {
  return window._importedData?.vacationRequests || mockVacationRequests
}

// Mock error simulation
export function mockApiError(message: string, delay = 300): Promise<{ success: false; error: string }> {
  return new Promise(resolve => {
    setTimeout(() => {
      resolve({ success: false, error: message })
    }, delay)
  })
}