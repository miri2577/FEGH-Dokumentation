// Employee Color Assignment System for Professional Shift Planning

// Color palette optimized for accessibility and professional appearance
const ROLE_COLOR_PALETTE = {
  // Social Services Roles
  'Sozialpädagoge': { primary: '#3B82F6', secondary: '#DBEAFE', accent: '#1E40AF' }, // Blue family
  'Sozialarbeiter': { primary: '#3B82F6', secondary: '#DBEAFE', accent: '#1E40AF' },
  'Heilerziehungspfleger': { primary: '#059669', secondary: '#D1FAE5', accent: '#047857' }, // Green family
  'Heilerzieher': { primary: '#059669', secondary: '#D1FAE5', accent: '#047857' },
  'Erzieherin': { primary: '#8B5CF6', secondary: '#EDE9FE', accent: '#6D28D9' }, // Purple family
  'Erzieher': { primary: '#8B5CF6', secondary: '#EDE9FE', accent: '#6D28D9' },
  'Pflegefachkraft': { primary: '#DC2626', secondary: '#FEE2E2', accent: '#B91C1C' }, // Red family
  'Betreuungsassistent': { primary: '#F59E0B', secondary: '#FEF3C7', accent: '#D97706' }, // Amber family
  'Psychologe': { primary: '#0891B2', secondary: '#CFFAFE', accent: '#0E7490' }, // Cyan family
  'Therapeut': { primary: '#0891B2', secondary: '#CFFAFE', accent: '#0E7490' },

  // Administrative Roles
  'Leitung': { primary: '#1F2937', secondary: '#F3F4F6', accent: '#111827' }, // Gray family
  'Verwaltung': { primary: '#6B7280', secondary: '#F9FAFB', accent: '#374151' },

  // Support Roles
  'Hauswirtschaft': { primary: '#EC4899', secondary: '#FCE7F3', accent: '#DB2777' }, // Pink family
  'Fahrer': { primary: '#7C3AED', secondary: '#F3E8FF', accent: '#5B21B6' }, // Violet family
}

// Fallback colors for unknown roles
const FALLBACK_COLORS = [
  { primary: '#6366F1', secondary: '#E0E7FF', accent: '#4338CA' }, // Indigo
  { primary: '#EF4444', secondary: '#FEE2E2', accent: '#DC2626' }, // Red
  { primary: '#10B981', secondary: '#D1FAE5', accent: '#059669' }, // Emerald
  { primary: '#F59E0B', secondary: '#FEF3C7', accent: '#D97706' }, // Amber
  { primary: '#8B5CF6', secondary: '#EDE9FE', accent: '#6D28D9' }, // Purple
  { primary: '#06B6D4', secondary: '#CFFAFE', accent: '#0891B2' }, // Cyan
]

export interface EmployeeColor {
  primary: string    // Main color for backgrounds
  secondary: string  // Light version for hover states
  accent: string     // Dark version for borders/text
  contrast: string   // High contrast color for text
}

export interface CapacityStatus {
  level: 'optimal' | 'warning' | 'critical' | 'overflow'
  percentage: number
  color: string
  backgroundColor: string
  message: string
}

/**
 * Assigns a consistent color to an employee based on their role
 */
export function getEmployeeColor(position: string, employeeId: string): EmployeeColor {
  // Normalize position for lookup
  const normalizedPosition = position.toLowerCase().replace(/[^a-z]/g, '')

  // Try exact match first
  for (const [role, colors] of Object.entries(ROLE_COLOR_PALETTE)) {
    if (normalizedPosition.includes(role.toLowerCase().replace(/[^a-z]/g, ''))) {
      return {
        ...colors,
        contrast: getContrastColor(colors.primary)
      }
    }
  }

  // Use fallback color based on employee ID hash
  const hash = hashString(employeeId)
  const fallbackColor = FALLBACK_COLORS[hash % FALLBACK_COLORS.length]

  return {
    ...fallbackColor,
    contrast: getContrastColor(fallbackColor.primary)
  }
}

/**
 * Calculates capacity status based on current vs required staffing
 */
export function calculateCapacityStatus(
  currentStaff: number,
  requiredStaff: number,
  criticalMin: number = 0.9
): CapacityStatus {
  if (requiredStaff === 0) {
    return {
      level: 'optimal',
      percentage: 100,
      color: '#059669',
      backgroundColor: '#D1FAE5',
      message: 'Keine Anforderungen'
    }
  }

  const percentage = (currentStaff / requiredStaff) * 100

  if (percentage >= 100) {
    return {
      level: 'optimal',
      percentage,
      color: '#059669',
      backgroundColor: '#D1FAE5',
      message: 'Optimal besetzt'
    }
  } else if (percentage >= (criticalMin * 100)) {
    return {
      level: 'warning',
      percentage,
      color: '#F59E0B',
      backgroundColor: '#FEF3C7',
      message: 'Knapp besetzt'
    }
  } else if (percentage >= 70) {
    return {
      level: 'critical',
      percentage,
      color: '#DC2626',
      backgroundColor: '#FEE2E2',
      message: 'Unterbesetzt'
    }
  } else {
    return {
      level: 'overflow',
      percentage,
      color: '#FFFFFF',
      backgroundColor: '#DC2626',
      message: 'Kritisch unterbesetzt'
    }
  }
}

/**
 * Analyzes vacation overlap and returns conflict level
 */
export function analyzeVacationConflicts(
  vacationRequests: Array<{
    employeeId: string
    startDate: string
    endDate: string
    position: string
  }>,
  date: string,
  requiredStaffByRole: Record<string, number>
): {
  conflicts: boolean
  severity: 'none' | 'minor' | 'major' | 'critical'
  affectedRoles: string[]
  recommendedActions: string[]
} {
  const dateObj = new Date(date)

  // Find employees on vacation for this date
  const employeesOnVacation = vacationRequests.filter(req => {
    const start = new Date(req.startDate)
    const end = new Date(req.endDate)
    return dateObj >= start && dateObj <= end
  })

  // Group by role
  const vacationsByRole = employeesOnVacation.reduce((acc, emp) => {
    acc[emp.position] = (acc[emp.position] || 0) + 1
    return acc
  }, {} as Record<string, number>)

  const affectedRoles: string[] = []
  let maxSeverity: 'none' | 'minor' | 'major' | 'critical' = 'none'
  const recommendedActions: string[] = []

  // Check each role's coverage
  for (const [role, required] of Object.entries(requiredStaffByRole)) {
    const onVacation = vacationsByRole[role] || 0
    const coverage = ((required - onVacation) / required) * 100

    if (coverage < 100) {
      affectedRoles.push(role)

      if (coverage < 50) {
        maxSeverity = 'critical'
        recommendedActions.push(`${role}: Externe Vertretung organisieren`)
      } else if (coverage < 70) {
        maxSeverity = maxSeverity === 'critical' ? 'critical' : 'major'
        recommendedActions.push(`${role}: Überstunden oder Springerpool aktivieren`)
      } else if (coverage < 90) {
        maxSeverity = maxSeverity === 'critical' || maxSeverity === 'major' ? maxSeverity : 'minor'
        recommendedActions.push(`${role}: Flexible Arbeitszeiten prüfen`)
      }
    }
  }

  return {
    conflicts: affectedRoles.length > 0,
    severity: maxSeverity,
    affectedRoles,
    recommendedActions
  }
}

/**
 * Generates CSS classes for employee color theming
 */
export function getEmployeeCSSClasses(position: string, employeeId: string): {
  background: string
  hover: string
  border: string
  text: string
} {
  const colors = getEmployeeColor(position, employeeId)

  return {
    background: `bg-[${colors.primary}]`,
    hover: `hover:bg-[${colors.secondary}]`,
    border: `border-[${colors.accent}]`,
    text: `text-[${colors.contrast}]`
  }
}

/**
 * Creates a color legend for the shift planning view
 */
export function generateColorLegend(employees: Array<{ id: string, position: string, firstName: string, lastName: string }>) {
  const roleColors = new Map<string, EmployeeColor>()

  employees.forEach(emp => {
    if (!roleColors.has(emp.position)) {
      roleColors.set(emp.position, getEmployeeColor(emp.position, emp.id))
    }
  })

  return Array.from(roleColors.entries()).map(([role, colors]) => ({
    role,
    colors,
    count: employees.filter(emp => emp.position === role).length
  }))
}

// Helper functions
function hashString(str: string): number {
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash // Convert to 32bit integer
  }
  return Math.abs(hash)
}

function getContrastColor(hexColor: string): string {
  // Remove # if present
  const color = hexColor.replace('#', '')

  // Convert to RGB
  const r = parseInt(color.substr(0, 2), 16)
  const g = parseInt(color.substr(2, 2), 16)
  const b = parseInt(color.substr(4, 2), 16)

  // Calculate relative luminance
  const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

  // Return black or white based on luminance
  return luminance > 0.5 ? '#000000' : '#FFFFFF'
}

/**
 * Real-time capacity monitoring
 */
export function getCapacityAlerts(
  shifts: Array<{ employeeId: string, date: string, startTime: string, endTime: string }>,
  employees: Array<{ id: string, position: string }>,
  date: string,
  timeSlot: string
): {
  alerts: Array<{
    type: 'understaffed' | 'overstaffed' | 'no_coverage' | 'overtime_risk'
    severity: 'low' | 'medium' | 'high' | 'critical'
    message: string
    affectedRoles: string[]
  }>
} {
  const alerts: Array<{
    type: 'understaffed' | 'overstaffed' | 'no_coverage' | 'overtime_risk'
    severity: 'low' | 'medium' | 'high' | 'critical'
    message: string
    affectedRoles: string[]
  }> = []

  const dateObj = new Date(date)
  const dayShifts = shifts.filter(shift => shift.date === date)

  // Group employees by role
  const employeesByRole = new Map<string, Array<{ id: string, position: string }>>()
  employees.forEach(emp => {
    if (!employeesByRole.has(emp.position)) {
      employeesByRole.set(emp.position, [])
    }
    employeesByRole.get(emp.position)!.push(emp)
  })

  // Standard staffing requirements by role (can be configured)
  const minStaffingRequirements: Record<string, number> = {
    'Sozialpädagoge': 2,
    'Heilerziehungspfleger': 1,
    'Pflegefachkraft': 1,
    'Betreuungsassistent': 1,
    'Leitung': 1
  }

  // Check each role's capacity
  for (const [role, employees] of employeesByRole) {
    const minRequired = minStaffingRequirements[role] || 1
    const scheduled = dayShifts.filter(shift =>
      employees.some(emp => emp.id === shift.employeeId)
    ).length

    const coveragePercent = (scheduled / minRequired) * 100

    if (scheduled === 0) {
      alerts.push({
        type: 'no_coverage',
        severity: 'critical',
        message: `Keine ${role} eingeteilt`,
        affectedRoles: [role]
      })
    } else if (coveragePercent < 70) {
      alerts.push({
        type: 'understaffed',
        severity: 'critical',
        message: `${role}: Kritisch unterbesetzt (${scheduled}/${minRequired})`,
        affectedRoles: [role]
      })
    } else if (coveragePercent < 90) {
      alerts.push({
        type: 'understaffed',
        severity: 'high',
        message: `${role}: Unterbesetzt (${scheduled}/${minRequired})`,
        affectedRoles: [role]
      })
    } else if (scheduled > minRequired * 1.5) {
      alerts.push({
        type: 'overstaffed',
        severity: 'medium',
        message: `${role}: Möglicherweise überbesetzt (${scheduled}/${minRequired})`,
        affectedRoles: [role]
      })
    }
  }

  // Check for overtime risks
  const employeeHours = new Map<string, number>()
  dayShifts.forEach(shift => {
    const start = new Date(`${shift.date}T${shift.startTime}`)
    const end = new Date(`${shift.date}T${shift.endTime}`)
    const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60)

    employeeHours.set(shift.employeeId, (employeeHours.get(shift.employeeId) || 0) + hours)
  })

  for (const [employeeId, hours] of employeeHours) {
    const employee = employees.find(emp => emp.id === employeeId)
    if (employee && hours > 10) {
      alerts.push({
        type: 'overtime_risk',
        severity: hours > 12 ? 'critical' : 'high',
        message: `${employee.position}: Überstunden-Risiko (${hours.toFixed(1)}h)`,
        affectedRoles: [employee.position]
      })
    }
  }

  return { alerts }
}

/**
 * Enhanced vacation conflict detection with detailed recommendations
 */
export function detectVacationConflicts(
  vacationRequests: Array<{
    employeeId: string
    startDate: string
    endDate: string
    position: string
    status: 'pending' | 'approved' | 'rejected'
  }>,
  shifts: Array<{ employeeId: string, date: string }>,
  dateRange: { start: string, end: string }
): {
  conflicts: Array<{
    date: string
    severity: 'minor' | 'major' | 'critical'
    affectedPositions: string[]
    details: {
      position: string
      scheduled: number
      onVacation: number
      coverage: number
      recommendation: string
    }[]
    overallRecommendation: string
  }>
} {
  const conflicts: Array<{
    date: string
    severity: 'minor' | 'major' | 'critical'
    affectedPositions: string[]
    details: {
      position: string
      scheduled: number
      onVacation: number
      coverage: number
      recommendation: string
    }[]
    overallRecommendation: string
  }> = []

  const startDate = new Date(dateRange.start)
  const endDate = new Date(dateRange.end)

  // Analyze each day in the range
  for (let date = new Date(startDate); date <= endDate; date.setDate(date.getDate() + 1)) {
    const dateStr = date.toISOString().split('T')[0]

    // Find approved vacations for this date
    const vacationsToday = vacationRequests.filter(req => {
      if (req.status !== 'approved') return false
      const vacStart = new Date(req.startDate)
      const vacEnd = new Date(req.endDate)
      return date >= vacStart && date <= vacEnd
    })

    if (vacationsToday.length === 0) continue

    // Group by position
    const vacationsByPosition = new Map<string, number>()
    vacationsToday.forEach(vac => {
      vacationsByPosition.set(vac.position, (vacationsByPosition.get(vac.position) || 0) + 1)
    })

    // Check shifts for this date
    const shiftsToday = shifts.filter(shift => shift.date === dateStr)
    const shiftsByPosition = new Map<string, number>()
    shiftsToday.forEach(shift => {
      // Need to get employee position from shift - this would be resolved with proper data structure
      // For now, assume we have this information
    })

    const affectedPositions: string[] = []
    const details: Array<{
      position: string
      scheduled: number
      onVacation: number
      coverage: number
      recommendation: string
    }> = []

    let maxSeverity: 'minor' | 'major' | 'critical' = 'minor'

    for (const [position, onVacation] of vacationsByPosition) {
      const scheduled = shiftsByPosition.get(position) || 0
      const coverage = scheduled > 0 ? ((scheduled - onVacation) / scheduled) * 100 : 0

      let recommendation = ''
      let severity: 'minor' | 'major' | 'critical' = 'minor'

      if (coverage < 50) {
        severity = 'critical'
        recommendation = 'Externe Vertretung organisieren oder Dienst umplanen'
      } else if (coverage < 70) {
        severity = 'major'
        recommendation = 'Überstunden oder Springerpool aktivieren'
      } else if (coverage < 90) {
        severity = 'minor'
        recommendation = 'Flexible Arbeitszeiten oder interne Umverteilung prüfen'
      }

      if (severity === 'critical' || (severity === 'major' && maxSeverity !== 'critical')) {
        maxSeverity = severity
      }

      affectedPositions.push(position)
      details.push({
        position,
        scheduled,
        onVacation,
        coverage: Math.round(coverage),
        recommendation
      })
    }

    if (affectedPositions.length > 0) {
      let overallRecommendation = ''
      if (maxSeverity === 'critical') {
        overallRecommendation = 'Sofortige Maßnahmen erforderlich: Externe Unterstützung organisieren'
      } else if (maxSeverity === 'major') {
        overallRecommendation = 'Personalplanung anpassen: Überstunden oder Umverteilung'
      } else {
        overallRecommendation = 'Interne Lösung möglich: Flexible Arbeitszeiten nutzen'
      }

      conflicts.push({
        date: dateStr,
        severity: maxSeverity,
        affectedPositions,
        details,
        overallRecommendation
      })
    }
  }

  return { conflicts }
}