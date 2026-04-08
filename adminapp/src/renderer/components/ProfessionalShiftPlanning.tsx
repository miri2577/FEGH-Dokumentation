import React, { useState, useEffect, useMemo } from 'react'
import {
  Calendar,
  Plus,
  Filter,
  Download,
  Upload,
  Users,
  Clock,
  MapPin,
  ChevronLeft,
  ChevronRight,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Bell,
  Settings,
  Eye,
  EyeOff,
  TrendingUp,
  TrendingDown,
  Minus
} from 'lucide-react'
import { Employee, Shift, CapacityAlert, VacationRequest } from '../../types'
import ShiftForm from './ShiftForm'
import { getCurrentEmployees, getCurrentShifts, getCurrentVacationRequests, mockApiCall } from '../utils/mockData'
import { format, startOfWeek, endOfWeek, eachDayOfInterval, addWeeks, subWeeks, isSameDay, parseISO, isToday, isFuture } from 'date-fns'
import { de } from 'date-fns/locale'
import {
  getEmployeeColor,
  calculateCapacityStatus,
  analyzeVacationConflicts,
  generateColorLegend,
  getCapacityAlerts,
  detectVacationConflicts,
  type EmployeeColor,
  type CapacityStatus
} from '../../utils/employeeColors'

type ViewMode = 'week' | 'month'
type DisplayMode = 'compact' | 'detailed' | 'overview'

interface ProfessionalShiftPlanningProps {}

export default function ProfessionalShiftPlanning({}: ProfessionalShiftPlanningProps) {
  const [currentDate, setCurrentDate] = useState(new Date())
  const [viewMode, setViewMode] = useState<ViewMode>('week')
  const [displayMode, setDisplayMode] = useState<DisplayMode>('detailed')
  const [shifts, setShifts] = useState<Shift[]>([])
  const [employees, setEmployees] = useState<Employee[]>([])
  const [vacationRequests, setVacationRequests] = useState<VacationRequest[]>([])
  const [filteredEmployees, setFilteredEmployees] = useState<Employee[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingShift, setEditingShift] = useState<Shift | null>(null)
  const [selectedDate, setSelectedDate] = useState<Date | null>(null)
  const [departmentFilter, setDepartmentFilter] = useState('all')
  const [positionFilter, setPositionFilter] = useState('all')
  const [capacityAlerts, setCapacityAlerts] = useState<CapacityAlert[]>([])
  const [showAlerts, setShowAlerts] = useState(true)
  const [showColorLegend, setShowColorLegend] = useState(true)

  // Calculate date range for current view
  const weekStart = startOfWeek(currentDate, { locale: de })
  const weekEnd = endOfWeek(currentDate, { locale: de })
  const weekDays = eachDayOfInterval({ start: weekStart, end: weekEnd })

  // Time slots for better planning visualization
  const timeSlots = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00', '22:00'
  ]

  // Staffing requirements (would come from configuration)
  const staffingRequirements = {
    'Sozialarbeiter': { min: 2, optimal: 3 },
    'Heilerziehungspfleger': { min: 1, optimal: 2 },
    'Erzieherin': { min: 1, optimal: 1 },
    'Pflegefachkraft': { min: 1, optimal: 2 }
  }

  useEffect(() => {
    loadData()
  }, [])

  useEffect(() => {
    loadShifts()
  }, [currentDate])

  useEffect(() => {
    filterEmployees()
  }, [employees, departmentFilter, positionFilter])

  useEffect(() => {
    analyzeCapacity()
  }, [shifts, employees, vacationRequests, currentDate])

  // Color legend for roles
  const colorLegend = useMemo(() => {
    return generateColorLegend(employees)
  }, [employees])

  async function loadData() {
    try {
      setIsLoading(true)
      setError(null)

      const isDev = await window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        const [employeeResponse, vacationResponse] = await Promise.all([
          mockApiCall(getCurrentEmployees()),
          mockApiCall(getCurrentVacationRequests())
        ])

        if (employeeResponse.success && employeeResponse.data) {
          setEmployees(employeeResponse.data.filter(emp => emp.isActive))
        }

        if (vacationResponse.success && vacationResponse.data) {
          setVacationRequests(vacationResponse.data)
        }
      } else {
        const employeeResponse = await window.electronAPI.employees.list()
        if (employeeResponse.success && employeeResponse.data) {
          setEmployees(employeeResponse.data.filter(emp => emp.isActive))
        }
      }

      await loadShifts()
    } catch (err) {
      setError('Fehler beim Laden der Daten')
      console.error(err)
    } finally {
      setIsLoading(false)
    }
  }

  async function loadShifts() {
    try {
      const startDate = format(weekStart, 'yyyy-MM-dd')
      const endDate = format(weekEnd, 'yyyy-MM-dd')

      const isDev = await window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        const response = await mockApiCall(getCurrentShifts())
        if (response.success && response.data) {
          setShifts(response.data)
        }
      } else {
        const response = await window.electronAPI.shifts.list(startDate, endDate)
        if (response.success && response.data) {
          setShifts(response.data)
        }
      }
    } catch (err) {
      console.error('Fehler beim Laden der Schichten:', err)
    }
  }

  function filterEmployees() {
    let filtered = [...employees]

    if (departmentFilter !== 'all') {
      filtered = filtered.filter(emp => emp.department === departmentFilter)
    }

    if (positionFilter !== 'all') {
      filtered = filtered.filter(emp => emp.position === positionFilter)
    }

    // Sort by position then by name for better grouping
    filtered.sort((a, b) => {
      if (a.position !== b.position) {
        return a.position.localeCompare(b.position)
      }
      return a.lastName.localeCompare(b.lastName)
    })

    setFilteredEmployees(filtered)
  }

  function analyzeCapacity() {
    const alerts: CapacityAlert[] = []

    weekDays.forEach(day => {
      const dayStr = format(day, 'yyyy-MM-dd')
      const dayShifts = shifts.filter(shift => shift.date === dayStr)

      // Use enhanced capacity alerts
      const capacityAlerts = getCapacityAlerts(
        dayShifts.map(shift => ({
          employeeId: shift.employeeId,
          date: shift.date,
          startTime: shift.startTime,
          endTime: shift.endTime
        })),
        employees.map(emp => ({ id: emp.id, position: emp.position })),
        dayStr,
        '08:00-17:00' // Default time slot
      )

      // Convert capacity alerts to CapacityAlert format
      capacityAlerts.alerts.forEach(alert => {
        alerts.push({
          id: `capacity-${alert.type}-${dayStr}-${Date.now()}`,
          type: alert.type as any,
          severity: alert.severity as any,
          department: 'Alle',
          date: dayStr,
          affectedEmployees: [],
          message: alert.message,
          recommendations: [alert.message],
          acknowledged: false,
          createdAt: new Date().toISOString()
        })
      })

      // Enhanced vacation conflict detection
      const vacationConflicts = detectVacationConflicts(
        vacationRequests
          .filter(req => req.status === 'approved')
          .map(req => ({
            employeeId: req.employeeId,
            startDate: req.startDate,
            endDate: req.endDate,
            position: employees.find(emp => emp.id === req.employeeId)?.position || 'Unknown',
            status: req.status
          })),
        dayShifts,
        { start: dayStr, end: dayStr }
      )

      // Add vacation conflict alerts
      vacationConflicts.conflicts.forEach(conflict => {
        alerts.push({
          id: `vacation-conflict-${conflict.date}-${Date.now()}`,
          type: 'vacation_conflict',
          severity: conflict.severity === 'critical' ? 'critical' :
                   conflict.severity === 'major' ? 'high' : 'medium',
          department: 'Alle',
          date: conflict.date,
          affectedEmployees: [],
          message: `Urlaubskonflikt: ${conflict.affectedPositions.join(', ')} - ${conflict.overallRecommendation}`,
          recommendations: conflict.details.map(d => d.recommendation),
          acknowledged: false,
          createdAt: new Date().toISOString()
        })
      })
    })

    setCapacityAlerts(alerts)
  }

  function navigateWeek(direction: 'prev' | 'next') {
    setCurrentDate(prev => direction === 'next' ? addWeeks(prev, 1) : subWeeks(prev, 1))
  }

  function goToToday() {
    setCurrentDate(new Date())
  }

  function getShiftsForEmployeeAndDay(employeeId: string, date: Date): Shift[] {
    return shifts.filter(shift =>
      shift.employeeId === employeeId && isSameDay(parseISO(shift.date), date)
    )
  }

  function getEmployeeById(id: string): Employee | undefined {
    return employees.find(emp => emp.id === id)
  }

  function getEmployeeColorInfo(employee: Employee): EmployeeColor {
    return getEmployeeColor(employee.position, employee.id)
  }

  function getDayCapacityStatus(date: Date) {
    const dayStr = format(date, 'yyyy-MM-dd')
    const dayShifts = shifts.filter(shift => shift.date === dayStr)
    const totalEmployeesScheduled = new Set(dayShifts.map(shift => shift.employeeId)).size
    const totalRequired = Object.values(staffingRequirements).reduce((sum, req) => sum + req.optimal, 0)

    return calculateCapacityStatus(totalEmployeesScheduled, totalRequired)
  }

  function getShiftTypeIcon(type: Shift['type']) {
    switch (type) {
      case 'regular': return <Clock size={12} />
      case 'overtime': return <TrendingUp size={12} />
      case 'night': return <Minus size={12} />
      case 'weekend': return <Calendar size={12} />
      default: return <Clock size={12} />
    }
  }

  const departments = [...new Set(employees.map(emp => emp.department))].sort()
  const positions = [...new Set(employees.map(emp => emp.position))].sort()
  const criticalAlerts = capacityAlerts.filter(alert => alert.severity === 'critical').length
  const highAlerts = capacityAlerts.filter(alert => alert.severity === 'high').length

  // Quick action functions
  async function handleCreateShift(shiftData: Omit<Shift, 'id' | 'createdAt' | 'updatedAt'>) {
    try {
      const isDev = await window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        const response = await mockApiCall({ success: true })
        if (response.success) {
          await loadShifts()
          setShowForm(false)
          setSelectedDate(null)
        }
      } else {
        const response = await window.electronAPI.shifts.create(shiftData)
        if (response.success) {
          await loadShifts()
          setShowForm(false)
          setSelectedDate(null)
        } else {
          setError(response.error || 'Fehler beim Erstellen der Schicht')
        }
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Erstellen')
      console.error(err)
    }
  }

  function openShiftForm(date?: Date, employeeId?: string) {
    setSelectedDate(date || null)
    setShowForm(true)
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="flex flex-col items-center gap-md">
          <div className="spinner" style={{ width: '40px', height: '40px' }}></div>
          <p className="text-muted">Dienstplan wird geladen...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="h-full flex flex-col bg-gray-50">
      {/* Enhanced Header with Alerts */}
      <div className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-md">
            <Calendar size={28} className="text-blue-600" />
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Professionelle Dienstplanung</h1>
              <p className="text-gray-600">
                {format(weekStart, 'dd.MM.', { locale: de })} - {format(weekEnd, 'dd.MM.yyyy', { locale: de })}
              </p>
            </div>

            {/* Alert Summary */}
            {(criticalAlerts > 0 || highAlerts > 0) && (
              <div className="flex items-center gap-2 ml-6">
                {criticalAlerts > 0 && (
                  <div className="flex items-center gap-1 px-3 py-1 bg-red-100 text-red-800 rounded-full text-sm font-medium">
                    <AlertTriangle size={14} />
                    {criticalAlerts} Kritisch
                  </div>
                )}
                {highAlerts > 0 && (
                  <div className="flex items-center gap-1 px-3 py-1 bg-orange-100 text-orange-800 rounded-full text-sm font-medium">
                    <Bell size={14} />
                    {highAlerts} Warnung
                  </div>
                )}
              </div>
            )}
          </div>

          <div className="flex items-center gap-3">
            {/* Display Mode Toggle */}
            <div className="flex bg-gray-100 rounded-lg p-1">
              {(['compact', 'detailed', 'overview'] as DisplayMode[]).map(mode => (
                <button
                  key={mode}
                  onClick={() => setDisplayMode(mode)}
                  className={`px-3 py-1 text-sm rounded transition-colors ${
                    displayMode === mode
                      ? 'bg-white text-gray-900 shadow-sm'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  {mode === 'compact' ? 'Kompakt' : mode === 'detailed' ? 'Detail' : 'Übersicht'}
                </button>
              ))}
            </div>

            {/* Filters */}
            <select
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              value={departmentFilter}
              onChange={(e) => setDepartmentFilter(e.target.value)}
            >
              <option value="all">Alle Bereiche</option>
              {departments.map(dept => (
                <option key={dept} value={dept}>{dept}</option>
              ))}
            </select>

            <select
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              value={positionFilter}
              onChange={(e) => setPositionFilter(e.target.value)}
            >
              <option value="all">Alle Positionen</option>
              {positions.map(pos => (
                <option key={pos} value={pos}>{pos}</option>
              ))}
            </select>

            {/* Navigation */}
            <button
              className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:ring-2 focus:ring-blue-500"
              onClick={goToToday}
            >
              Heute
            </button>

            <div className="flex">
              <button
                className="px-3 py-2 bg-white border border-gray-300 rounded-l-lg hover:bg-gray-50 focus:ring-2 focus:ring-blue-500"
                onClick={() => navigateWeek('prev')}
              >
                <ChevronLeft size={16} />
              </button>
              <button
                className="px-3 py-2 bg-white border-l-0 border border-gray-300 rounded-r-lg hover:bg-gray-50 focus:ring-2 focus:ring-blue-500"
                onClick={() => navigateWeek('next')}
              >
                <ChevronRight size={16} />
              </button>
            </div>

            {/* Quick Actions */}
            <button
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 font-medium"
              onClick={() => openShiftForm()}
            >
              <Plus size={16} className="inline mr-2" />
              Neue Schicht
            </button>

            {/* Settings Toggle */}
            <div className="flex gap-1">
              <button
                onClick={() => setShowAlerts(!showAlerts)}
                className={`p-2 rounded-lg transition-colors ${showAlerts ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600'}`}
                title="Warnungen anzeigen"
              >
                <Bell size={16} />
              </button>
              <button
                onClick={() => setShowColorLegend(!showColorLegend)}
                className={`p-2 rounded-lg transition-colors ${showColorLegend ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600'}`}
                title="Farblegende anzeigen"
              >
                {showColorLegend ? <Eye size={16} /> : <EyeOff size={16} />}
              </button>
            </div>
          </div>
        </div>

        {error && (
          <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <div className="flex items-center">
              <XCircle size={16} className="text-red-500 mr-2" />
              <span className="text-red-800">{error}</span>
            </div>
          </div>
        )}
      </div>

      {/* Alerts Panel */}
      {showAlerts && capacityAlerts.length > 0 && (
        <div className="bg-white border-b border-gray-200 px-6 py-3">
          <div className="flex items-center justify-between mb-2">
            <h3 className="font-semibold text-gray-900">Aktuelle Warnungen</h3>
            <button
              onClick={() => setShowAlerts(false)}
              className="text-gray-400 hover:text-gray-600"
            >
              <XCircle size={16} />
            </button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 max-h-32 overflow-y-auto">
            {capacityAlerts.slice(0, 6).map(alert => (
              <div
                key={alert.id}
                className={`p-3 rounded-lg border-l-4 ${
                  alert.severity === 'critical' ? 'bg-red-50 border-red-500' :
                  alert.severity === 'high' ? 'bg-orange-50 border-orange-500' :
                  'bg-yellow-50 border-yellow-500'
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <p className={`text-sm font-medium ${
                      alert.severity === 'critical' ? 'text-red-800' :
                      alert.severity === 'high' ? 'text-orange-800' :
                      'text-yellow-800'
                    }`}>
                      {alert.message}
                    </p>
                    <p className="text-xs text-gray-600 mt-1">
                      {format(parseISO(alert.date), 'dd.MM.yyyy', { locale: de })}
                    </p>
                  </div>
                  <AlertTriangle
                    size={16}
                    className={
                      alert.severity === 'critical' ? 'text-red-500' :
                      alert.severity === 'high' ? 'text-orange-500' :
                      'text-yellow-500'
                    }
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Color Legend */}
      {showColorLegend && colorLegend.length > 0 && (
        <div className="bg-white border-b border-gray-200 px-6 py-3">
          <div className="flex items-center justify-between mb-2">
            <h3 className="font-semibold text-gray-900">Positionen</h3>
            <button
              onClick={() => setShowColorLegend(false)}
              className="text-gray-400 hover:text-gray-600"
            >
              <XCircle size={16} />
            </button>
          </div>
          <div className="flex flex-wrap gap-4">
            {colorLegend.map(({ role, colors, count }) => (
              <div key={role} className="flex items-center gap-2">
                <div
                  className="w-4 h-4 rounded"
                  style={{ backgroundColor: colors.primary }}
                />
                <span className="text-sm text-gray-700">{role} ({count})</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Main Calendar Grid */}
      <div className="flex-1 overflow-auto bg-white">
        <div className="min-w-max">
          <table className="w-full border-collapse">
            <thead className="bg-gray-50 sticky top-0 z-10">
              <tr>
                <th className="w-48 p-4 text-left border-r border-gray-200 font-semibold text-gray-900">
                  Mitarbeiter ({filteredEmployees.length})
                </th>
                {weekDays.map(day => {
                  const capacityStatus = getDayCapacityStatus(day)
                  const isCurrentDay = isToday(day)
                  const isFutureDay = isFuture(day)

                  return (
                    <th
                      key={day.toISOString()}
                      className={`min-w-[180px] p-4 text-center border-r border-gray-200 ${
                        isCurrentDay ? 'bg-blue-50' : ''
                      }`}
                    >
                      <div className="space-y-1">
                        <div className={`font-semibold ${isCurrentDay ? 'text-blue-700' : 'text-gray-900'}`}>
                          {format(day, 'EEE', { locale: de })}
                        </div>
                        <div className={`text-sm ${isCurrentDay ? 'text-blue-600' : 'text-gray-600'}`}>
                          {format(day, 'dd.MM', { locale: de })}
                        </div>
                        <div
                          className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                            capacityStatus.level === 'optimal' ? 'bg-green-100 text-green-800' :
                            capacityStatus.level === 'warning' ? 'bg-yellow-100 text-yellow-800' :
                            capacityStatus.level === 'critical' ? 'bg-orange-100 text-orange-800' :
                            'bg-red-100 text-red-800'
                          }`}
                          style={{ backgroundColor: capacityStatus.backgroundColor, color: capacityStatus.color }}
                        >
                          {capacityStatus.percentage.toFixed(0)}%
                        </div>
                      </div>
                    </th>
                  )
                })}
              </tr>
            </thead>
            <tbody>
              {filteredEmployees.length === 0 ? (
                <tr>
                  <td colSpan={8} className="p-12 text-center text-gray-500">
                    <Users size={48} className="mx-auto mb-4 text-gray-400" />
                    <p className="text-lg font-medium">Keine Mitarbeiter gefunden</p>
                    <p className="text-sm">Passen Sie die Filter an oder fügen Sie Mitarbeiter hinzu</p>
                  </td>
                </tr>
              ) : (
                filteredEmployees.map((employee, index) => {
                  const colors = getEmployeeColorInfo(employee)
                  const isEvenRow = index % 2 === 0

                  return (
                    <tr key={employee.id} className={`${isEvenRow ? 'bg-gray-50' : 'bg-white'} hover:bg-blue-50 transition-colors`}>
                      <td className="p-4 border-r border-gray-200">
                        <div className="flex items-center gap-3">
                          <div
                            className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold text-sm"
                            style={{ backgroundColor: colors.primary }}
                          >
                            {employee.firstName[0]}{employee.lastName[0]}
                          </div>
                          <div className="flex-1">
                            <div className="font-medium text-gray-900">
                              {employee.firstName} {employee.lastName}
                            </div>
                            <div className="text-sm text-gray-600">
                              {employee.position}
                            </div>
                            <div className="text-xs text-gray-500">
                              {employee.department}
                            </div>
                          </div>
                        </div>
                      </td>
                      {weekDays.map(day => {
                        const dayShifts = getShiftsForEmployeeAndDay(employee.id, day)
                        const isCurrentDay = isToday(day)

                        return (
                          <td
                            key={day.toISOString()}
                            className={`p-2 border-r border-gray-200 align-top cursor-pointer hover:bg-blue-100 transition-colors ${
                              isCurrentDay ? 'bg-blue-25' : ''
                            }`}
                            onClick={() => openShiftForm(day, employee.id)}
                            style={{ minHeight: displayMode === 'compact' ? '60px' : '100px' }}
                          >
                            <div className="space-y-1 min-h-full">
                              {dayShifts.map(shift => (
                                <div
                                  key={shift.id}
                                  className="p-2 rounded-lg text-xs text-white cursor-pointer hover:shadow-md transition-all"
                                  style={{ backgroundColor: colors.primary }}
                                  onClick={(e) => {
                                    e.stopPropagation()
                                    setEditingShift(shift)
                                  }}
                                >
                                  <div className="flex items-center justify-between mb-1">
                                    <div className="flex items-center gap-1">
                                      {getShiftTypeIcon(shift.type)}
                                      <span className="font-medium">
                                        {shift.startTime} - {shift.endTime}
                                      </span>
                                    </div>
                                    <div className={`
                                      px-1 py-0.5 rounded text-xs
                                      ${shift.status === 'completed' ? 'bg-green-600' :
                                        shift.status === 'confirmed' ? 'bg-blue-600' :
                                        shift.status === 'planned' ? 'bg-yellow-600' :
                                        'bg-red-600'}
                                    `}>
                                      {shift.status === 'completed' ? <CheckCircle size={10} /> :
                                       shift.status === 'confirmed' ? <Clock size={10} /> :
                                       shift.status === 'planned' ? <Calendar size={10} /> :
                                       <XCircle size={10} />}
                                    </div>
                                  </div>
                                  {displayMode !== 'compact' && shift.location && (
                                    <div className="flex items-center gap-1 text-xs opacity-90">
                                      <MapPin size={8} />
                                      <span className="truncate">{shift.location}</span>
                                    </div>
                                  )}
                                  {displayMode === 'detailed' && shift.notes && (
                                    <div className="text-xs opacity-75 mt-1 truncate">
                                      {shift.notes}
                                    </div>
                                  )}
                                </div>
                              ))}
                              {dayShifts.length === 0 && (
                                <div className="h-full flex items-center justify-center text-gray-400 opacity-0 hover:opacity-100 transition-opacity">
                                  <Plus size={20} />
                                </div>
                              )}
                            </div>
                          </td>
                        )
                      })}
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Shift Form Modal */}
      {(showForm || editingShift) && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4">
            <ShiftForm
              shift={editingShift}
              employees={employees}
              selectedDate={selectedDate}
              onSave={editingShift
                ? (updates) => console.log('Update shift:', updates)
                : handleCreateShift
              }
              onDelete={editingShift ? () => console.log('Delete shift:', editingShift.id) : undefined}
              onCancel={() => {
                setShowForm(false)
                setEditingShift(null)
                setSelectedDate(null)
              }}
            />
          </div>
        </div>
      )}
    </div>
  )
}