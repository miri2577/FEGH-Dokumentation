import React, { useState, useEffect } from 'react'
import { X, Save, Clock, MapPin, Trash2 } from 'lucide-react'
import { Employee, Shift } from '../../types'
import { format } from 'date-fns'

interface ShiftFormProps {
  shift?: Shift | null
  employees: Employee[]
  selectedDate?: Date | null
  onSave: (shift: Omit<Shift, 'id' | 'createdAt' | 'updatedAt'> | Partial<Shift>) => void
  onDelete?: () => void
  onCancel: () => void
}

interface FormData {
  employeeId: string
  date: string
  startTime: string
  endTime: string
  type: 'regular' | 'overtime' | 'night' | 'weekend'
  location: string
  notes: string
  status: 'planned' | 'confirmed' | 'completed' | 'cancelled'
}

const shiftTypes = [
  { value: 'regular', label: 'Regulärer Dienst', color: 'bg-blue-500' },
  { value: 'overtime', label: 'Überstunden', color: 'bg-orange-500' },
  { value: 'night', label: 'Nachtschicht', color: 'bg-purple-500' },
  { value: 'weekend', label: 'Wochenenddienst', color: 'bg-green-500' }
] as const

const shiftStatuses = [
  { value: 'planned', label: 'Geplant', badge: 'badge-secondary' },
  { value: 'confirmed', label: 'Bestätigt', badge: 'badge-info' },
  { value: 'completed', label: 'Abgeschlossen', badge: 'badge-success' },
  { value: 'cancelled', label: 'Abgesagt', badge: 'badge-danger' }
] as const

const commonLocations = [
  'Wohnbereich A',
  'Wohnbereich B',
  'Wohnbereich C',
  'Tagesstätte',
  'Werkstatt',
  'Küche',
  'Büro',
  'Außenbereich'
]

const timeSlots = [
  '06:00', '06:30', '07:00', '07:30', '08:00', '08:30',
  '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
  '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
  '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
  '18:00', '18:30', '19:00', '19:30', '20:00', '20:30',
  '21:00', '21:30', '22:00'
]

export default function ShiftForm({
  shift,
  employees,
  selectedDate,
  onSave,
  onDelete,
  onCancel
}: ShiftFormProps) {
  const [formData, setFormData] = useState<FormData>({
    employeeId: '',
    date: selectedDate ? format(selectedDate, 'yyyy-MM-dd') : format(new Date(), 'yyyy-MM-dd'),
    startTime: '08:00',
    endTime: '16:00',
    type: 'regular',
    location: '',
    notes: '',
    status: 'planned'
  })
  const [errors, setErrors] = useState<Partial<FormData>>({})
  const [isLoading, setIsLoading] = useState(false)

  const isEditing = !!shift

  useEffect(() => {
    if (shift) {
      setFormData({
        employeeId: shift.employeeId,
        date: shift.date.split('T')[0],
        startTime: shift.startTime,
        endTime: shift.endTime,
        type: shift.type,
        location: shift.location,
        notes: shift.notes || '',
        status: shift.status
      })
    }
  }, [shift])

  function validateForm(): boolean {
    const newErrors: Partial<FormData> = {}

    if (!formData.employeeId) {
      newErrors.employeeId = 'Mitarbeiter auswählen'
    }

    if (!formData.date) {
      newErrors.date = 'Datum ist erforderlich'
    }

    if (!formData.startTime) {
      newErrors.startTime = 'Startzeit ist erforderlich'
    }

    if (!formData.endTime) {
      newErrors.endTime = 'Endzeit ist erforderlich'
    }

    if (formData.startTime && formData.endTime) {
      const start = new Date(`2000-01-01T${formData.startTime}`)
      const end = new Date(`2000-01-01T${formData.endTime}`)

      if (end <= start) {
        newErrors.endTime = 'Endzeit muss nach Startzeit liegen'
      }
    }

    if (!formData.location.trim()) {
      newErrors.location = 'Standort ist erforderlich'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()

    if (!validateForm()) {
      return
    }

    setIsLoading(true)

    try {
      await onSave(formData)
    } catch (error) {
      console.error('Form submission error:', error)
    } finally {
      setIsLoading(false)
    }
  }

  function handleInputChange(field: keyof FormData, value: any) {
    setFormData(prev => ({ ...prev, [field]: value }))

    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }))
    }
  }

  function calculateDuration(): string {
    if (!formData.startTime || !formData.endTime) return ''

    const start = new Date(`2000-01-01T${formData.startTime}`)
    const end = new Date(`2000-01-01T${formData.endTime}`)

    if (end <= start) return ''

    const diffMs = end.getTime() - start.getTime()
    const hours = diffMs / (1000 * 60 * 60)

    return `${hours.toFixed(1)}h`
  }

  function getSelectedEmployee(): Employee | undefined {
    return employees.find(emp => emp.id === formData.employeeId)
  }

  const selectedEmployee = getSelectedEmployee()
  const duration = calculateDuration()
  const selectedShiftType = shiftTypes.find(t => t.value === formData.type)

  return (
    <form onSubmit={handleSubmit}>
      <div className="card-header">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-sm">
            <Clock size={24} />
            <h2 className="text-lg font-bold">
              {isEditing ? 'Schicht bearbeiten' : 'Neue Schicht'}
            </h2>
          </div>
          <button type="button" onClick={onCancel} className="btn btn-sm btn-secondary">
            <X size={16} />
          </button>
        </div>
      </div>

      <div className="card-body">
        <div className="grid grid-cols-2 gap-md">
          {/* Employee Selection */}
          <div className="form-group col-span-2">
            <label className="form-label">Mitarbeiter *</label>
            <select
              className={`form-select ${errors.employeeId ? 'border-danger' : ''}`}
              value={formData.employeeId}
              onChange={(e) => handleInputChange('employeeId', e.target.value)}
              disabled={isLoading}
            >
              <option value="">Mitarbeiter auswählen</option>
              {employees
                .filter(emp => emp.isActive)
                .sort((a, b) => `${a.lastName} ${a.firstName}`.localeCompare(`${b.lastName} ${b.firstName}`))
                .map(employee => (
                  <option key={employee.id} value={employee.id}>
                    {employee.lastName}, {employee.firstName} - {employee.position}
                  </option>
                ))}
            </select>
            {errors.employeeId && <div className="form-error">{errors.employeeId}</div>}

            {selectedEmployee && (
              <div className="mt-xs p-sm bg-secondary rounded text-sm">
                <div className="flex items-center gap-sm">
                  <div className="w-6 h-6 rounded-full bg-primary text-white flex items-center justify-center text-xs font-bold">
                    {selectedEmployee.firstName[0]}{selectedEmployee.lastName[0]}
                  </div>
                  <div>
                    <span className="font-medium">{selectedEmployee.department}</span>
                    <span className="text-muted"> • {selectedEmployee.weeklyHours}h/Woche</span>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Date */}
          <div className="form-group">
            <label className="form-label">Datum *</label>
            <input
              type="date"
              className={`form-input ${errors.date ? 'border-danger' : ''}`}
              value={formData.date}
              onChange={(e) => handleInputChange('date', e.target.value)}
              disabled={isLoading}
            />
            {errors.date && <div className="form-error">{errors.date}</div>}
          </div>

          {/* Shift Type */}
          <div className="form-group">
            <label className="form-label">Schichttyp</label>
            <select
              className="form-select"
              value={formData.type}
              onChange={(e) => handleInputChange('type', e.target.value)}
              disabled={isLoading}
            >
              {shiftTypes.map(type => (
                <option key={type.value} value={type.value}>
                  {type.label}
                </option>
              ))}
            </select>
            {selectedShiftType && (
              <div className="flex items-center gap-sm mt-xs">
                <div className={`w-4 h-4 ${selectedShiftType.color} rounded`}></div>
                <span className="text-sm text-muted">{selectedShiftType.label}</span>
              </div>
            )}
          </div>

          {/* Start Time */}
          <div className="form-group">
            <label className="form-label">Startzeit *</label>
            <select
              className={`form-select ${errors.startTime ? 'border-danger' : ''}`}
              value={formData.startTime}
              onChange={(e) => handleInputChange('startTime', e.target.value)}
              disabled={isLoading}
            >
              {timeSlots.map(time => (
                <option key={time} value={time}>{time}</option>
              ))}
            </select>
            {errors.startTime && <div className="form-error">{errors.startTime}</div>}
          </div>

          {/* End Time */}
          <div className="form-group">
            <label className="form-label">Endzeit *</label>
            <select
              className={`form-select ${errors.endTime ? 'border-danger' : ''}`}
              value={formData.endTime}
              onChange={(e) => handleInputChange('endTime', e.target.value)}
              disabled={isLoading}
            >
              {timeSlots.map(time => (
                <option key={time} value={time}>{time}</option>
              ))}
            </select>
            {errors.endTime && <div className="form-error">{errors.endTime}</div>}
            {duration && (
              <div className="text-sm text-muted mt-xs">
                Dauer: {duration}
              </div>
            )}
          </div>

          {/* Location */}
          <div className="form-group">
            <label className="form-label">Standort *</label>
            <input
              type="text"
              list="locations"
              className={`form-input ${errors.location ? 'border-danger' : ''}`}
              value={formData.location}
              onChange={(e) => handleInputChange('location', e.target.value)}
              placeholder="z.B. Wohnbereich A"
              disabled={isLoading}
            />
            <datalist id="locations">
              {commonLocations.map(location => (
                <option key={location} value={location} />
              ))}
            </datalist>
            {errors.location && <div className="form-error">{errors.location}</div>}
          </div>

          {/* Status */}
          <div className="form-group">
            <label className="form-label">Status</label>
            <select
              className="form-select"
              value={formData.status}
              onChange={(e) => handleInputChange('status', e.target.value as Shift['status'])}
              disabled={isLoading}
            >
              {shiftStatuses.map(status => (
                <option key={status.value} value={status.value}>
                  {status.label}
                </option>
              ))}
            </select>
            <div className="flex items-center gap-sm mt-xs">
              <div className={`badge ${shiftStatuses.find(s => s.value === formData.status)?.badge}`}>
                {shiftStatuses.find(s => s.value === formData.status)?.label}
              </div>
            </div>
          </div>

          {/* Notes */}
          <div className="form-group col-span-2">
            <label className="form-label">Notizen</label>
            <textarea
              className="form-textarea"
              value={formData.notes}
              onChange={(e) => handleInputChange('notes', e.target.value)}
              placeholder="Zusätzliche Informationen zur Schicht..."
              rows={3}
              disabled={isLoading}
            />
          </div>
        </div>

        {/* Shift Summary */}
        {formData.employeeId && formData.date && duration && (
          <div className="card mt-md" style={{ backgroundColor: 'var(--background-secondary)' }}>
            <div className="card-body">
              <h3 className="font-bold mb-sm flex items-center gap-sm">
                <Clock size={16} />
                Schicht-Übersicht
              </h3>
              <div className="grid grid-cols-2 gap-md text-sm">
                <div>
                  <span className="text-muted">Mitarbeiter:</span>
                  <div className="font-medium">
                    {selectedEmployee && `${selectedEmployee.firstName} ${selectedEmployee.lastName}`}
                  </div>
                </div>
                <div>
                  <span className="text-muted">Datum:</span>
                  <div className="font-medium">
                    {window.electronAPI.utils.formatDate(formData.date)}
                  </div>
                </div>
                <div>
                  <span className="text-muted">Zeit:</span>
                  <div className="font-medium">
                    {formData.startTime} - {formData.endTime} ({duration})
                  </div>
                </div>
                <div>
                  <span className="text-muted">Standort:</span>
                  <div className="font-medium flex items-center gap-xs">
                    <MapPin size={12} />
                    {formData.location}
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      <div className="card-footer flex justify-between">
        <div>
          {isEditing && onDelete && (
            <button
              type="button"
              className="btn btn-danger"
              onClick={onDelete}
              disabled={isLoading}
            >
              <Trash2 size={16} />
              Löschen
            </button>
          )}
        </div>

        <div className="flex gap-sm">
          <button
            type="button"
            className="btn btn-secondary"
            onClick={onCancel}
            disabled={isLoading}
          >
            Abbrechen
          </button>
          <button
            type="submit"
            className="btn btn-primary"
            disabled={isLoading}
          >
            {isLoading ? (
              <div className="flex items-center gap-sm">
                <div className="spinner"></div>
                Speichern...
              </div>
            ) : (
              <div className="flex items-center gap-sm">
                <Save size={16} />
                {isEditing ? 'Aktualisieren' : 'Erstellen'}
              </div>
            )}
          </button>
        </div>
      </div>
    </form>
  )
}