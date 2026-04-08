import React, { useState, useEffect } from 'react'
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
  MoreHorizontal
} from 'lucide-react'
import { Employee, Shift, ShiftTemplate } from '../../types'
import ShiftForm from './ShiftForm'
import { mockEmployees, mockShifts, mockApiCall } from '../utils/mockData'
import { format, startOfWeek, endOfWeek, eachDayOfInterval, addWeeks, subWeeks, isSameDay, parseISO } from 'date-fns'
import { de } from 'date-fns/locale'

type ViewMode = 'week' | 'month'

interface ShiftPlanningProps {}

export default function ShiftPlanning({}: ShiftPlanningProps) {
  const [currentDate, setCurrentDate] = useState(new Date())
  const [viewMode, setViewMode] = useState<ViewMode>('week')
  const [shifts, setShifts] = useState<Shift[]>([])
  const [employees, setEmployees] = useState<Employee[]>([])
  const [filteredEmployees, setFilteredEmployees] = useState<Employee[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingShift, setEditingShift] = useState<Shift | null>(null)
  const [selectedDate, setSelectedDate] = useState<Date | null>(null)
  const [departmentFilter, setDepartmentFilter] = useState('all')

  // Calculate date range for current view
  const weekStart = startOfWeek(currentDate, { locale: de })
  const weekEnd = endOfWeek(currentDate, { locale: de })
  const weekDays = eachDayOfInterval({ start: weekStart, end: weekEnd })

  const timeSlots = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00', '22:00'
  ]

  useEffect(() => {
    loadData()
  }, [])

  useEffect(() => {
    loadShifts()
  }, [currentDate])

  useEffect(() => {
    filterEmployees()
  }, [employees, departmentFilter])

  async function loadData() {
    try {
      setIsLoading(true)
      setError(null)

      // Check if we're in development mode
      const isDev = window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        // Use mock data in development mode
        const response = await mockApiCall(mockEmployees)
        if (response.success && response.data) {
          setEmployees(response.data.filter(emp => emp.isActive))
        }
      } else {
        // Load employees from API
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

      // Check if we're in development mode
      const isDev = window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        // Use mock data in development mode
        const response = await mockApiCall(mockShifts)
        if (response.success && response.data) {
          setShifts(response.data)
        }
      } else {
        const response = await window.electronAPI.shifts.list(startDate, endDate)
        if (response.success && response.data) {
          setShifts(response.data)
        } else {
          console.warn('Fehler beim Laden der Schichten:', response.error)
        }
      }
    } catch (err) {
      console.error('Unerwarteter Fehler beim Laden der Schichten:', err)
    }
  }

  function filterEmployees() {
    let filtered = [...employees]

    if (departmentFilter !== 'all') {
      filtered = filtered.filter(emp => emp.department === departmentFilter)
    }

    setFilteredEmployees(filtered)
  }

  function navigateWeek(direction: 'prev' | 'next') {
    setCurrentDate(prev => direction === 'next' ? addWeeks(prev, 1) : subWeeks(prev, 1))
  }

  function goToToday() {
    setCurrentDate(new Date())
  }

  function getShiftsForDay(date: Date): Shift[] {
    return shifts.filter(shift => isSameDay(parseISO(shift.date), date))
  }

  function getShiftsForEmployeeAndDay(employeeId: string, date: Date): Shift[] {
    return shifts.filter(shift =>
      shift.employeeId === employeeId && isSameDay(parseISO(shift.date), date)
    )
  }

  function getEmployeeById(id: string): Employee | undefined {
    return employees.find(emp => emp.id === id)
  }

  function getShiftTypeColor(type: Shift['type']): string {
    switch (type) {
      case 'regular': return 'bg-blue-500'
      case 'overtime': return 'bg-orange-500'
      case 'night': return 'bg-purple-500'
      case 'weekend': return 'bg-green-500'
      default: return 'bg-gray-500'
    }
  }

  function getShiftStatusBadge(status: Shift['status']) {
    switch (status) {
      case 'planned': return 'badge-secondary'
      case 'confirmed': return 'badge-info'
      case 'completed': return 'badge-success'
      case 'cancelled': return 'badge-danger'
      default: return 'badge-secondary'
    }
  }

  async function handleCreateShift(shiftData: Omit<Shift, 'id' | 'createdAt' | 'updatedAt'>) {
    try {
      // Check if we're in development mode
      const isDev = window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        // Simulate API call in development mode
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

  async function handleUpdateShift(id: string, updates: Partial<Shift>) {
    try {
      // Check if we're in development mode
      const isDev = window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        // Simulate API call in development mode
        const response = await mockApiCall({ success: true })
        if (response.success) {
          await loadShifts()
          setEditingShift(null)
        }
      } else {
        const response = await window.electronAPI.shifts.update(id, updates)
        if (response.success) {
          await loadShifts()
          setEditingShift(null)
        } else {
          setError(response.error || 'Fehler beim Aktualisieren der Schicht')
        }
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Aktualisieren')
      console.error(err)
    }
  }

  async function handleDeleteShift(id: string) {
    if (!confirm('Möchten Sie diese Schicht wirklich löschen?')) {
      return
    }

    try {
      // Check if we're in development mode
      const isDev = window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        // Simulate API call in development mode
        const response = await mockApiCall({ success: true })
        if (response.success) {
          await loadShifts()
        }
      } else {
        const response = await window.electronAPI.shifts.delete(id)
        if (response.success) {
          await loadShifts()
        } else {
          setError(response.error || 'Fehler beim Löschen der Schicht')
        }
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Löschen')
      console.error(err)
    }
  }

  function openShiftForm(date?: Date, employeeId?: string) {
    setSelectedDate(date || null)
    if (date && employeeId) {
      // Pre-fill form with selected date and employee
      setShowForm(true)
    } else {
      setShowForm(true)
    }
  }

  const departments = [...new Set(employees.map(emp => emp.department))].sort()

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
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="card-header">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-md">
            <Calendar size={24} />
            <div>
              <h1 className="text-xl font-bold">Dienstplanung</h1>
              <p className="text-muted">
                {format(weekStart, 'dd.MM.', { locale: de })} - {format(weekEnd, 'dd.MM.yyyy', { locale: de })}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-sm">
            <select
              className="form-select"
              value={departmentFilter}
              onChange={(e) => setDepartmentFilter(e.target.value)}
            >
              <option value="all">Alle Bereiche</option>
              {departments.map(dept => (
                <option key={dept} value={dept}>{dept}</option>
              ))}
            </select>

            <button
              className="btn btn-secondary"
              onClick={goToToday}
            >
              Heute
            </button>

            <div className="flex">
              <button
                className="btn btn-secondary"
                onClick={() => navigateWeek('prev')}
              >
                <ChevronLeft size={16} />
              </button>
              <button
                className="btn btn-secondary"
                onClick={() => navigateWeek('next')}
              >
                <ChevronRight size={16} />
              </button>
            </div>

            <button
              className="btn btn-primary"
              onClick={() => openShiftForm()}
            >
              <Plus size={16} />
              Neue Schicht
            </button>
          </div>
        </div>

        {error && (
          <div className="alert alert-danger mt-md">
            {error}
          </div>
        )}
      </div>

      {/* Calendar Grid */}
      <div className="flex-1 overflow-auto">
        <div className="p-md">
          <div className="card">
            <div className="overflow-x-auto">
              <table className="w-full border-collapse">
                <thead>
                  <tr className="bg-secondary">
                    <th className="p-sm text-left border border-border-color" style={{ minWidth: '200px' }}>
                      Mitarbeiter
                    </th>
                    {weekDays.map(day => (
                      <th
                        key={day.toISOString()}
                        className="p-sm text-center border border-border-color"
                        style={{ minWidth: '150px' }}
                      >
                        <div className="font-bold">
                          {format(day, 'EEE', { locale: de })}
                        </div>
                        <div className="text-sm text-muted">
                          {format(day, 'dd.MM', { locale: de })}
                        </div>
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filteredEmployees.length === 0 ? (
                    <tr>
                      <td colSpan={8} className="p-lg text-center text-muted">
                        <Users size={32} className="mx-auto mb-sm" />
                        <p>Keine Mitarbeiter im ausgewählten Bereich</p>
                      </td>
                    </tr>
                  ) : (
                    filteredEmployees.map(employee => (
                      <tr key={employee.id} className="hover:bg-secondary">
                        <td className="p-sm border border-border-color">
                          <div className="flex items-center gap-sm">
                            <div className="w-8 h-8 rounded-full bg-primary text-white flex items-center justify-center text-sm font-bold">
                              {employee.firstName[0]}{employee.lastName[0]}
                            </div>
                            <div>
                              <div className="font-medium">
                                {employee.firstName} {employee.lastName}
                              </div>
                              <div className="text-xs text-muted">
                                {employee.position}
                              </div>
                            </div>
                          </div>
                        </td>
                        {weekDays.map(day => {
                          const dayShifts = getShiftsForEmployeeAndDay(employee.id, day)
                          return (
                            <td
                              key={day.toISOString()}
                              className="p-1 border border-border-color align-top cursor-pointer hover:bg-tertiary"
                              onClick={() => openShiftForm(day, employee.id)}
                              style={{ minHeight: '80px' }}
                            >
                              <div className="space-y-1">
                                {dayShifts.map(shift => (
                                  <div
                                    key={shift.id}
                                    className={`
                                      p-1 rounded text-xs text-white cursor-pointer
                                      ${getShiftTypeColor(shift.type)}
                                    `}
                                    onClick={(e) => {
                                      e.stopPropagation()
                                      setEditingShift(shift)
                                    }}
                                  >
                                    <div className="flex items-center justify-between">
                                      <div className="font-medium">
                                        {shift.startTime} - {shift.endTime}
                                      </div>
                                      <div className={`badge badge-sm ${getShiftStatusBadge(shift.status)}`}>
                                        {shift.status}
                                      </div>
                                    </div>
                                    {shift.location && (
                                      <div className="flex items-center gap-xs mt-1">
                                        <MapPin size={10} />
                                        <span>{shift.location}</span>
                                      </div>
                                    )}
                                    {shift.notes && (
                                      <div className="text-xs opacity-75 mt-1 truncate">
                                        {shift.notes}
                                      </div>
                                    )}
                                  </div>
                                ))}
                                {dayShifts.length === 0 && (
                                  <div className="h-16 flex items-center justify-center text-muted opacity-0 hover:opacity-100">
                                    <Plus size={16} />
                                  </div>
                                )}
                              </div>
                            </td>
                          )
                        })}
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {/* Legend */}
          <div className="card mt-md">
            <div className="card-body">
              <h3 className="font-bold mb-sm">Legende</h3>
              <div className="flex flex-wrap gap-md">
                <div className="flex items-center gap-xs">
                  <div className="w-4 h-4 bg-blue-500 rounded"></div>
                  <span className="text-sm">Regulärer Dienst</span>
                </div>
                <div className="flex items-center gap-xs">
                  <div className="w-4 h-4 bg-orange-500 rounded"></div>
                  <span className="text-sm">Überstunden</span>
                </div>
                <div className="flex items-center gap-xs">
                  <div className="w-4 h-4 bg-purple-500 rounded"></div>
                  <span className="text-sm">Nachtschicht</span>
                </div>
                <div className="flex items-center gap-xs">
                  <div className="w-4 h-4 bg-green-500 rounded"></div>
                  <span className="text-sm">Wochenende</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Shift Form Modal */}
      {(showForm || editingShift) && (
        <div className="modal-overlay">
          <div className="modal" style={{ width: '600px' }}>
            <ShiftForm
              shift={editingShift}
              employees={employees}
              selectedDate={selectedDate}
              onSave={editingShift
                ? (updates) => handleUpdateShift(editingShift.id, updates)
                : handleCreateShift
              }
              onDelete={editingShift ? () => handleDeleteShift(editingShift.id) : undefined}
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