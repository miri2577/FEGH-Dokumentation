import React, { useState, useEffect } from 'react'
import {
  Plus,
  Search,
  Edit3,
  Trash2,
  User,
  Mail,
  Phone,
  Calendar,
  Clock,
  MapPin,
  CheckCircle,
  XCircle,
  Filter
} from 'lucide-react'
import { Employee } from '../../types'
import EmployeeForm from './EmployeeForm'
import { getCurrentEmployees, mockApiCall } from '../utils/mockData'

export default function EmployeeManagement() {
  const [employees, setEmployees] = useState<Employee[]>([])
  const [filteredEmployees, setFilteredEmployees] = useState<Employee[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [departmentFilter, setDepartmentFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [showForm, setShowForm] = useState(false)
  const [editingEmployee, setEditingEmployee] = useState<Employee | null>(null)

  useEffect(() => {
    loadEmployees()
  }, [])

  useEffect(() => {
    filterEmployees()
  }, [employees, searchTerm, departmentFilter, statusFilter])

  async function loadEmployees() {
    try {
      setIsLoading(true)
      setError(null)

      // Check if we're in development mode
      const isDev = window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        // Use mock data in development mode (with potential imported data)
        const response = await mockApiCall(getCurrentEmployees())
        if (response.success && response.data) {
          setEmployees(response.data)
        }
      } else {
        const response = await window.electronAPI.employees.list()
        if (response.success && response.data) {
          setEmployees(response.data)
        } else {
          setError(response.error || 'Fehler beim Laden der Mitarbeiter')
        }
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Laden der Mitarbeiter')
      console.error(err)
    } finally {
      setIsLoading(false)
    }
  }

  function filterEmployees() {
    let filtered = [...employees]

    // Search filter
    if (searchTerm) {
      const term = searchTerm.toLowerCase()
      filtered = filtered.filter(emp =>
        emp.firstName.toLowerCase().includes(term) ||
        emp.lastName.toLowerCase().includes(term) ||
        emp.email.toLowerCase().includes(term) ||
        emp.position.toLowerCase().includes(term)
      )
    }

    // Department filter
    if (departmentFilter !== 'all') {
      filtered = filtered.filter(emp => emp.department === departmentFilter)
    }

    // Status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter(emp =>
        statusFilter === 'active' ? emp.isActive : !emp.isActive
      )
    }

    setFilteredEmployees(filtered)
  }

  async function handleCreateEmployee(employeeData: Omit<Employee, 'id' | 'createdAt' | 'updatedAt'>) {
    try {
      const response = await window.electronAPI.employees.create(employeeData)

      if (response.success) {
        await loadEmployees()
        setShowForm(false)
      } else {
        setError(response.error || 'Fehler beim Erstellen des Mitarbeiters')
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Erstellen')
      console.error(err)
    }
  }

  async function handleUpdateEmployee(id: string, updates: Partial<Employee>) {
    try {
      const response = await window.electronAPI.employees.update(id, updates)

      if (response.success) {
        await loadEmployees()
        setEditingEmployee(null)
      } else {
        setError(response.error || 'Fehler beim Aktualisieren des Mitarbeiters')
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Aktualisieren')
      console.error(err)
    }
  }

  async function handleDeleteEmployee(id: string, name: string) {
    if (!confirm(`Möchten Sie ${name} wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.`)) {
      return
    }

    try {
      const response = await window.electronAPI.employees.delete(id)

      if (response.success) {
        await loadEmployees()
      } else {
        setError(response.error || 'Fehler beim Löschen des Mitarbeiters')
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Löschen')
      console.error(err)
    }
  }

  function getUniqueValues<K extends keyof Employee>(key: K): string[] {
    const values = employees.map(emp => emp[key] as string)
    return [...new Set(values)].filter(Boolean).sort()
  }

  const departments = getUniqueValues('department')
  const contractTypes = ['fulltime', 'parttime', 'temporary']
  const contractTypeLabels = {
    fulltime: 'Vollzeit',
    parttime: 'Teilzeit',
    temporary: 'Befristet'
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="flex flex-col items-center gap-md">
          <div className="spinner" style={{ width: '40px', height: '40px' }}></div>
          <p className="text-muted">Mitarbeiter werden geladen...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="card-header">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold">Mitarbeiterverwaltung</h1>
            <p className="text-muted">{employees.length} Mitarbeiter insgesamt</p>
          </div>
          <button
            className="btn btn-primary"
            onClick={() => setShowForm(true)}
          >
            <Plus size={20} />
            Neuer Mitarbeiter
          </button>
        </div>

        {error && (
          <div className="alert alert-danger mt-md">
            {error}
          </div>
        )}

        {/* Filters */}
        <div className="grid grid-cols-4 gap-md mt-md">
          <div className="form-group">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted" size={16} />
              <input
                type="text"
                className="form-input pl-10"
                placeholder="Suchen..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>

          <div className="form-group">
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
          </div>

          <div className="form-group">
            <select
              className="form-select"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="all">Alle Status</option>
              <option value="active">Aktiv</option>
              <option value="inactive">Inaktiv</option>
            </select>
          </div>

          <div className="flex items-center gap-sm text-sm text-muted">
            <Filter size={16} />
            <span>{filteredEmployees.length} gefiltert</span>
          </div>
        </div>
      </div>

      {/* Employee List */}
      <div className="flex-1 overflow-auto">
        {filteredEmployees.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-muted">
            <User size={48} />
            <p className="mt-md">
              {employees.length === 0
                ? 'Noch keine Mitarbeiter angelegt'
                : 'Keine Mitarbeiter entsprechen den Filterkriterien'
              }
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-md p-md">
            {filteredEmployees.map((employee) => (
              <div key={employee.id} className="card">
                <div className="card-body">
                  <div className="flex items-start justify-between mb-md">
                    <div className="flex items-center gap-sm">
                      <div className="w-12 h-12 rounded-full bg-primary text-white flex items-center justify-center font-bold">
                        {employee.firstName[0]}{employee.lastName[0]}
                      </div>
                      <div>
                        <h3 className="font-bold">
                          {employee.firstName} {employee.lastName}
                        </h3>
                        <p className="text-sm text-muted">{employee.position}</p>
                      </div>
                    </div>

                    <div className="flex items-center gap-xs">
                      {employee.isActive ? (
                        <div className="badge badge-success">
                          <CheckCircle size={12} />
                          Aktiv
                        </div>
                      ) : (
                        <div className="badge badge-secondary">
                          <XCircle size={12} />
                          Inaktiv
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="space-y-2 text-sm">
                    <div className="flex items-center gap-sm text-muted">
                      <Mail size={14} />
                      <span>{employee.email}</span>
                    </div>

                    {employee.phone && (
                      <div className="flex items-center gap-sm text-muted">
                        <Phone size={14} />
                        <span>{employee.phone}</span>
                      </div>
                    )}

                    <div className="flex items-center gap-sm text-muted">
                      <MapPin size={14} />
                      <span>{employee.department}</span>
                    </div>

                    <div className="flex items-center gap-sm text-muted">
                      <Clock size={14} />
                      <span>{employee.weeklyHours}h/Woche ({contractTypeLabels[employee.contractType]})</span>
                    </div>

                    <div className="flex items-center gap-sm text-muted">
                      <Calendar size={14} />
                      <span>Seit {window.electronAPI.utils.formatDate(employee.startDate)}</span>
                    </div>
                  </div>

                  {employee.skills.length > 0 && (
                    <div className="mt-md">
                      <div className="flex flex-wrap gap-xs">
                        {employee.skills.slice(0, 3).map((skill, index) => (
                          <span key={index} className="badge badge-info text-xs">
                            {skill}
                          </span>
                        ))}
                        {employee.skills.length > 3 && (
                          <span className="badge badge-secondary text-xs">
                            +{employee.skills.length - 3}
                          </span>
                        )}
                      </div>
                    </div>
                  )}
                </div>

                <div className="card-footer flex justify-end gap-sm">
                  <button
                    className="btn btn-sm btn-secondary"
                    onClick={() => setEditingEmployee(employee)}
                  >
                    <Edit3 size={14} />
                    Bearbeiten
                  </button>
                  <button
                    className="btn btn-sm btn-danger"
                    onClick={() => handleDeleteEmployee(employee.id, `${employee.firstName} ${employee.lastName}`)}
                  >
                    <Trash2 size={14} />
                    Löschen
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Employee Form Modal */}
      {(showForm || editingEmployee) && (
        <div className="modal-overlay">
          <div className="modal" style={{ width: '600px' }}>
            <EmployeeForm
              employee={editingEmployee}
              onSave={editingEmployee
                ? (updates) => handleUpdateEmployee(editingEmployee.id, updates)
                : handleCreateEmployee
              }
              onCancel={() => {
                setShowForm(false)
                setEditingEmployee(null)
              }}
            />
          </div>
        </div>
      )}
    </div>
  )
}