import React, { useState, useEffect } from 'react'
import { X, Save, Calendar, User, AlertCircle } from 'lucide-react'
import { VacationRequest, Employee } from '../../types'
import { differenceInDays, parseISO } from 'date-fns'

interface VacationFormProps {
  request?: VacationRequest | null
  employees: Employee[]
  onSave: (request: Omit<VacationRequest, 'id' | 'requestedAt'> | Partial<VacationRequest>) => void
  onCancel: () => void
}

interface FormData {
  employeeId: string
  startDate: string
  endDate: string
  type: 'vacation' | 'sick' | 'personal' | 'training'
  reason: string
  status: 'pending' | 'approved' | 'rejected' | 'cancelled'
  notes: string
}

const vacationTypes = [
  { value: 'vacation', label: 'Urlaub', description: 'Regulärer Erholungsurlaub' },
  { value: 'sick', label: 'Krankmeldung', description: 'Krankheitsbedingte Abwesenheit' },
  { value: 'personal', label: 'Persönlicher Tag', description: 'Persönliche Angelegenheiten' },
  { value: 'training', label: 'Fortbildung', description: 'Weiterbildung und Schulungen' }
] as const

const statusOptions = [
  { value: 'pending', label: 'Ausstehend', color: 'badge-warning' },
  { value: 'approved', label: 'Genehmigt', color: 'badge-success' },
  { value: 'rejected', label: 'Abgelehnt', color: 'badge-danger' },
  { value: 'cancelled', label: 'Storniert', color: 'badge-secondary' }
] as const

export default function VacationForm({
  request,
  employees,
  onSave,
  onCancel
}: VacationFormProps) {
  const [formData, setFormData] = useState<FormData>({
    employeeId: '',
    startDate: new Date().toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
    type: 'vacation',
    reason: '',
    status: 'pending',
    notes: ''
  })
  const [errors, setErrors] = useState<Partial<FormData>>({})
  const [isLoading, setIsLoading] = useState(false)

  const isEditing = !!request

  useEffect(() => {
    if (request) {
      setFormData({
        employeeId: request.employeeId,
        startDate: request.startDate.split('T')[0],
        endDate: request.endDate.split('T')[0],
        type: request.type,
        reason: request.reason || '',
        status: request.status,
        notes: request.notes || ''
      })
    }
  }, [request])

  function validateForm(): boolean {
    const newErrors: Partial<FormData> = {}

    if (!formData.employeeId) {
      newErrors.employeeId = 'Mitarbeiter auswählen'
    }

    if (!formData.startDate) {
      newErrors.startDate = 'Startdatum ist erforderlich'
    }

    if (!formData.endDate) {
      newErrors.endDate = 'Enddatum ist erforderlich'
    }

    if (formData.startDate && formData.endDate) {
      const start = parseISO(formData.startDate)
      const end = parseISO(formData.endDate)

      if (end < start) {
        newErrors.endDate = 'Enddatum muss nach Startdatum liegen'
      }

      // Check for very long vacation periods
      const days = differenceInDays(end, start) + 1
      if (days > 365) {
        newErrors.endDate = 'Zeitraum darf nicht länger als 1 Jahr sein'
      }
    }

    // Reason is required for certain types
    if ((formData.type === 'personal' || formData.type === 'training') && !formData.reason.trim()) {
      newErrors.reason = `Grund ist für ${vacationTypes.find(t => t.value === formData.type)?.label} erforderlich`
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
      const days = calculateDays()
      const requestData = {
        ...formData,
        days,
        // Only include decision fields if status is not pending
        ...(formData.status !== 'pending' && {
          decidedAt: new Date().toISOString(),
          decidedBy: 'Admin' // In a real app, this would be the current user
        })
      }

      await onSave(requestData)
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

    // Auto-calculate end date for sick leave (typically 1 day)
    if (field === 'type' && value === 'sick' && !isEditing) {
      setFormData(prev => ({ ...prev, endDate: prev.startDate }))
    }
  }

  function calculateDays(): number {
    if (!formData.startDate || !formData.endDate) return 0
    return differenceInDays(parseISO(formData.endDate), parseISO(formData.startDate)) + 1
  }

  function getSelectedEmployee(): Employee | undefined {
    return employees.find(emp => emp.id === formData.employeeId)
  }

  function getWeekendWarning(): boolean {
    if (!formData.startDate || !formData.endDate) return false

    const start = parseISO(formData.startDate)
    const end = parseISO(formData.endDate)

    // Check if weekend days are included
    const isWeekendIncluded = start.getDay() === 0 || start.getDay() === 6 ||
      end.getDay() === 0 || end.getDay() === 6

    return isWeekendIncluded && formData.type === 'vacation'
  }

  const selectedEmployee = getSelectedEmployee()
  const days = calculateDays()
  const selectedType = vacationTypes.find(t => t.value === formData.type)
  const selectedStatus = statusOptions.find(s => s.value === formData.status)
  const showWeekendWarning = getWeekendWarning()

  return (
    <form onSubmit={handleSubmit}>
      <div className="card-header">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-sm">
            <Calendar size={24} />
            <h2 className="text-lg font-bold">
              {isEditing ? 'Urlaubsantrag bearbeiten' : 'Neuer Urlaubsantrag'}
            </h2>
          </div>
          <button type="button" onClick={onCancel} className="btn btn-sm btn-secondary">
            <X size={16} />
          </button>
        </div>
      </div>

      <div className="card-body">
        <div className="space-y-md">
          {/* Employee Selection */}
          <div className="form-group">
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
                    {employee.lastName}, {employee.firstName} - {employee.department}
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
                    <span className="font-medium">{selectedEmployee.position}</span>
                    <span className="text-muted"> • {selectedEmployee.department}</span>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Date Range */}
          <div className="grid grid-cols-2 gap-md">
            <div className="form-group">
              <label className="form-label">Startdatum *</label>
              <input
                type="date"
                className={`form-input ${errors.startDate ? 'border-danger' : ''}`}
                value={formData.startDate}
                onChange={(e) => handleInputChange('startDate', e.target.value)}
                disabled={isLoading}
              />
              {errors.startDate && <div className="form-error">{errors.startDate}</div>}
            </div>

            <div className="form-group">
              <label className="form-label">Enddatum *</label>
              <input
                type="date"
                className={`form-input ${errors.endDate ? 'border-danger' : ''}`}
                value={formData.endDate}
                onChange={(e) => handleInputChange('endDate', e.target.value)}
                min={formData.startDate}
                disabled={isLoading}
              />
              {errors.endDate && <div className="form-error">{errors.endDate}</div>}
              {days > 0 && (
                <div className="text-sm text-muted mt-xs">
                  Dauer: {days} {days === 1 ? 'Tag' : 'Tage'}
                </div>
              )}
            </div>
          </div>

          {showWeekendWarning && (
            <div className="alert alert-warning">
              <AlertCircle size={16} />
              <span>Achtung: Der gewählte Zeitraum umfasst Wochenendtage</span>
            </div>
          )}

          {/* Type Selection */}
          <div className="form-group">
            <label className="form-label">Art des Antrags</label>
            <div className="grid grid-cols-2 gap-md">
              {vacationTypes.map(type => (
                <label
                  key={type.value}
                  className={`
                    flex items-center p-sm border rounded cursor-pointer transition-colors
                    ${formData.type === type.value
                      ? 'border-primary bg-primary text-white'
                      : 'border-border-color hover:border-primary'
                    }
                  `}
                >
                  <input
                    type="radio"
                    name="type"
                    value={type.value}
                    checked={formData.type === type.value}
                    onChange={(e) => handleInputChange('type', e.target.value)}
                    className="sr-only"
                    disabled={isLoading}
                  />
                  <div>
                    <div className="font-medium">{type.label}</div>
                    <div className={`text-xs ${formData.type === type.value ? 'text-white opacity-90' : 'text-muted'}`}>
                      {type.description}
                    </div>
                  </div>
                </label>
              ))}
            </div>
          </div>

          {/* Reason */}
          <div className="form-group">
            <label className="form-label">
              Grund {(formData.type === 'personal' || formData.type === 'training') && '*'}
            </label>
            <textarea
              className={`form-textarea ${errors.reason ? 'border-danger' : ''}`}
              value={formData.reason}
              onChange={(e) => handleInputChange('reason', e.target.value)}
              placeholder={
                formData.type === 'vacation' ? 'Optionale Begründung für den Urlaub...' :
                formData.type === 'sick' ? 'Beschreibung der Erkrankung (optional)...' :
                formData.type === 'personal' ? 'Grund für den persönlichen Tag...' :
                'Details zur Fortbildung...'
              }
              rows={3}
              disabled={isLoading}
            />
            {errors.reason && <div className="form-error">{errors.reason}</div>}
          </div>

          {/* Status (only for editing) */}
          {isEditing && (
            <div className="form-group">
              <label className="form-label">Status</label>
              <select
                className="form-select"
                value={formData.status}
                onChange={(e) => handleInputChange('status', e.target.value as VacationRequest['status'])}
                disabled={isLoading}
              >
                {statusOptions.map(status => (
                  <option key={status.value} value={status.value}>
                    {status.label}
                  </option>
                ))}
              </select>
              {selectedStatus && (
                <div className="flex items-center gap-sm mt-xs">
                  <div className={`badge ${selectedStatus.color}`}>
                    {selectedStatus.label}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Notes */}
          <div className="form-group">
            <label className="form-label">Anmerkungen</label>
            <textarea
              className="form-textarea"
              value={formData.notes}
              onChange={(e) => handleInputChange('notes', e.target.value)}
              placeholder="Zusätzliche Anmerkungen oder Hinweise..."
              rows={2}
              disabled={isLoading}
            />
          </div>

          {/* Summary */}
          {formData.employeeId && formData.startDate && formData.endDate && days > 0 && (
            <div className="card" style={{ backgroundColor: 'var(--background-secondary)' }}>
              <div className="card-body">
                <h3 className="font-bold mb-sm flex items-center gap-sm">
                  <User size={16} />
                  Antrags-Übersicht
                </h3>
                <div className="grid grid-cols-2 gap-md text-sm">
                  <div>
                    <span className="text-muted">Mitarbeiter:</span>
                    <div className="font-medium">
                      {selectedEmployee && `${selectedEmployee.firstName} ${selectedEmployee.lastName}`}
                    </div>
                  </div>
                  <div>
                    <span className="text-muted">Zeitraum:</span>
                    <div className="font-medium">
                      {window.electronAPI.utils.formatDate(formData.startDate)} - {window.electronAPI.utils.formatDate(formData.endDate)}
                    </div>
                  </div>
                  <div>
                    <span className="text-muted">Dauer:</span>
                    <div className="font-medium">
                      {days} {days === 1 ? 'Tag' : 'Tage'}
                    </div>
                  </div>
                  <div>
                    <span className="text-muted">Art:</span>
                    <div className="font-medium">
                      {selectedType?.label}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="card-footer flex justify-end gap-sm">
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
              {isEditing ? 'Aktualisieren' : 'Antrag stellen'}
            </div>
          )}
        </button>
      </div>
    </form>
  )
}