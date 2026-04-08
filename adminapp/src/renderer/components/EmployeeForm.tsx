import React, { useState, useEffect } from 'react'
import { X, Save, User } from 'lucide-react'
import { Employee } from '../../types'

interface EmployeeFormProps {
  employee?: Employee | null
  onSave: (employee: Omit<Employee, 'id' | 'createdAt' | 'updatedAt'> | Partial<Employee>) => void
  onCancel: () => void
}

interface FormData {
  firstName: string
  lastName: string
  email: string
  phone: string
  position: string
  department: string
  startDate: string
  contractType: 'fulltime' | 'parttime' | 'temporary'
  weeklyHours: number
  skills: string[]
  isActive: boolean
}

const initialFormData: FormData = {
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  position: '',
  department: '',
  startDate: new Date().toISOString().split('T')[0],
  contractType: 'fulltime',
  weeklyHours: 40,
  skills: [],
  isActive: true
}

const commonDepartments = [
  'Wohnbereich',
  'Tagesstätte',
  'Werkstatt',
  'Betreuung',
  'Pflege',
  'Verwaltung',
  'Küche',
  'Reinigung',
  'Technik'
]

const commonPositions = [
  'Heilerziehungspfleger/in',
  'Erzieher/in',
  'Sozialarbeiter/in',
  'Sozialpädagoge/in',
  'Pflegefachkraft',
  'Betreuungsassistent/in',
  'Hauswirtschaftskraft',
  'Reinigungskraft',
  'Verwaltungsfachkraft',
  'Einrichtungsleitung',
  'Bereichsleitung',
  'Gruppenleitung'
]

const commonSkills = [
  'Pflege',
  'Betreuung',
  'Pädagogik',
  'Therapie',
  'Hauswirtschaft',
  'Erste Hilfe',
  'Medikamentengabe',
  'Dokumentation',
  'Krisenintervention',
  'Teamleitung',
  'Qualitätsmanagement',
  'EDV-Kenntnisse'
]

export default function EmployeeForm({ employee, onSave, onCancel }: EmployeeFormProps) {
  const [formData, setFormData] = useState<FormData>(initialFormData)
  const [errors, setErrors] = useState<Partial<FormData>>({})
  const [isLoading, setIsLoading] = useState(false)
  const [newSkill, setNewSkill] = useState('')

  const isEditing = !!employee

  useEffect(() => {
    if (employee) {
      setFormData({
        firstName: employee.firstName,
        lastName: employee.lastName,
        email: employee.email,
        phone: employee.phone || '',
        position: employee.position,
        department: employee.department,
        startDate: employee.startDate.split('T')[0],
        contractType: employee.contractType,
        weeklyHours: employee.weeklyHours,
        skills: employee.skills,
        isActive: employee.isActive
      })
    }
  }, [employee])

  function validateForm(): boolean {
    const newErrors: Partial<FormData> = {}

    if (!formData.firstName.trim()) {
      newErrors.firstName = 'Vorname ist erforderlich'
    }

    if (!formData.lastName.trim()) {
      newErrors.lastName = 'Nachname ist erforderlich'
    }

    if (!formData.email.trim()) {
      newErrors.email = 'E-Mail ist erforderlich'
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Ungültige E-Mail-Adresse'
    }

    if (!formData.position.trim()) {
      newErrors.position = 'Position ist erforderlich'
    }

    if (!formData.department.trim()) {
      newErrors.department = 'Bereich ist erforderlich'
    }

    if (!formData.startDate) {
      newErrors.startDate = 'Startdatum ist erforderlich'
    }

    if (formData.weeklyHours <= 0 || formData.weeklyHours > 60) {
      newErrors.weeklyHours = 'Wochenstunden müssen zwischen 1 und 60 liegen'
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

  function addSkill() {
    const skill = newSkill.trim()
    if (skill && !formData.skills.includes(skill)) {
      handleInputChange('skills', [...formData.skills, skill])
      setNewSkill('')
    }
  }

  function removeSkill(skillToRemove: string) {
    handleInputChange('skills', formData.skills.filter(skill => skill !== skillToRemove))
  }

  function addCommonSkill(skill: string) {
    if (!formData.skills.includes(skill)) {
      handleInputChange('skills', [...formData.skills, skill])
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <div className="card-header">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-sm">
            <User size={24} />
            <h2 className="text-lg font-bold">
              {isEditing ? 'Mitarbeiter bearbeiten' : 'Neuer Mitarbeiter'}
            </h2>
          </div>
          <button type="button" onClick={onCancel} className="btn btn-sm btn-secondary">
            <X size={16} />
          </button>
        </div>
      </div>

      <div className="card-body" style={{ maxHeight: '70vh', overflowY: 'auto' }}>
        <div className="grid grid-cols-2 gap-md">
          {/* Personal Information */}
          <div className="form-group">
            <label className="form-label">Vorname *</label>
            <input
              type="text"
              className={`form-input ${errors.firstName ? 'border-danger' : ''}`}
              value={formData.firstName}
              onChange={(e) => handleInputChange('firstName', e.target.value)}
              disabled={isLoading}
            />
            {errors.firstName && <div className="form-error">{errors.firstName}</div>}
          </div>

          <div className="form-group">
            <label className="form-label">Nachname *</label>
            <input
              type="text"
              className={`form-input ${errors.lastName ? 'border-danger' : ''}`}
              value={formData.lastName}
              onChange={(e) => handleInputChange('lastName', e.target.value)}
              disabled={isLoading}
            />
            {errors.lastName && <div className="form-error">{errors.lastName}</div>}
          </div>

          <div className="form-group">
            <label className="form-label">E-Mail *</label>
            <input
              type="email"
              className={`form-input ${errors.email ? 'border-danger' : ''}`}
              value={formData.email}
              onChange={(e) => handleInputChange('email', e.target.value)}
              disabled={isLoading}
            />
            {errors.email && <div className="form-error">{errors.email}</div>}
          </div>

          <div className="form-group">
            <label className="form-label">Telefon</label>
            <input
              type="tel"
              className="form-input"
              value={formData.phone}
              onChange={(e) => handleInputChange('phone', e.target.value)}
              disabled={isLoading}
            />
          </div>

          {/* Job Information */}
          <div className="form-group">
            <label className="form-label">Position *</label>
            <input
              type="text"
              list="positions"
              className={`form-input ${errors.position ? 'border-danger' : ''}`}
              value={formData.position}
              onChange={(e) => handleInputChange('position', e.target.value)}
              disabled={isLoading}
            />
            <datalist id="positions">
              {commonPositions.map(pos => (
                <option key={pos} value={pos} />
              ))}
            </datalist>
            {errors.position && <div className="form-error">{errors.position}</div>}
          </div>

          <div className="form-group">
            <label className="form-label">Bereich *</label>
            <input
              type="text"
              list="departments"
              className={`form-input ${errors.department ? 'border-danger' : ''}`}
              value={formData.department}
              onChange={(e) => handleInputChange('department', e.target.value)}
              disabled={isLoading}
            />
            <datalist id="departments">
              {commonDepartments.map(dept => (
                <option key={dept} value={dept} />
              ))}
            </datalist>
            {errors.department && <div className="form-error">{errors.department}</div>}
          </div>

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
            <label className="form-label">Vertragsart</label>
            <select
              className="form-select"
              value={formData.contractType}
              onChange={(e) => handleInputChange('contractType', e.target.value as 'fulltime' | 'parttime' | 'temporary')}
              disabled={isLoading}
            >
              <option value="fulltime">Vollzeit</option>
              <option value="parttime">Teilzeit</option>
              <option value="temporary">Befristet</option>
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Wochenstunden *</label>
            <input
              type="number"
              min="1"
              max="60"
              step="0.5"
              className={`form-input ${errors.weeklyHours ? 'border-danger' : ''}`}
              value={formData.weeklyHours}
              onChange={(e) => handleInputChange('weeklyHours', parseFloat(e.target.value) || 0)}
              disabled={isLoading}
            />
            {errors.weeklyHours && <div className="form-error">{errors.weeklyHours}</div>}
          </div>

          <div className="form-group">
            <label className="form-label">Status</label>
            <label className="flex items-center gap-sm">
              <input
                type="checkbox"
                checked={formData.isActive}
                onChange={(e) => handleInputChange('isActive', e.target.checked)}
                disabled={isLoading}
              />
              <span>Aktiv</span>
            </label>
          </div>
        </div>

        {/* Skills Section */}
        <div className="form-group mt-lg">
          <label className="form-label">Qualifikationen & Fähigkeiten</label>

          {/* Current Skills */}
          {formData.skills.length > 0 && (
            <div className="flex flex-wrap gap-xs mb-sm">
              {formData.skills.map((skill, index) => (
                <span key={index} className="badge badge-info flex items-center gap-xs">
                  {skill}
                  <button
                    type="button"
                    onClick={() => removeSkill(skill)}
                    className="text-white hover:text-danger"
                    disabled={isLoading}
                  >
                    <X size={12} />
                  </button>
                </span>
              ))}
            </div>
          )}

          {/* Add New Skill */}
          <div className="flex gap-sm mb-sm">
            <input
              type="text"
              className="form-input flex-1"
              placeholder="Neue Qualifikation hinzufügen..."
              value={newSkill}
              onChange={(e) => setNewSkill(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addSkill())}
              disabled={isLoading}
            />
            <button
              type="button"
              className="btn btn-secondary"
              onClick={addSkill}
              disabled={!newSkill.trim() || isLoading}
            >
              Hinzufügen
            </button>
          </div>

          {/* Common Skills */}
          <div>
            <p className="text-sm text-muted mb-sm">Häufige Qualifikationen:</p>
            <div className="flex flex-wrap gap-xs">
              {commonSkills.filter(skill => !formData.skills.includes(skill)).map(skill => (
                <button
                  key={skill}
                  type="button"
                  className="badge badge-secondary cursor-pointer hover:bg-primary hover:text-white"
                  onClick={() => addCommonSkill(skill)}
                  disabled={isLoading}
                >
                  + {skill}
                </button>
              ))}
            </div>
          </div>
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
              {isEditing ? 'Aktualisieren' : 'Erstellen'}
            </div>
          )}
        </button>
      </div>
    </form>
  )
}