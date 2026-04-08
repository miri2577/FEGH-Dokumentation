import React, { useState, useEffect } from 'react'
import {
  Briefcase,
  Plus,
  Calendar,
  Clock,
  User,
  CheckCircle,
  XCircle,
  AlertCircle,
  Filter,
  Search
} from 'lucide-react'
import { VacationRequest, Employee } from '../../types'
import VacationForm from './VacationForm'
import { mockEmployees, mockVacationRequests, mockApiCall } from '../utils/mockData'
import { format, differenceInDays, parseISO } from 'date-fns'
import { de } from 'date-fns/locale'

export default function VacationManagement() {
  const [vacationRequests, setVacationRequests] = useState<VacationRequest[]>([])
  const [employees, setEmployees] = useState<Employee[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingRequest, setEditingRequest] = useState<VacationRequest | null>(null)
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [employeeFilter, setEmployeeFilter] = useState<string>('all')
  const [typeFilter, setTypeFilter] = useState<string>('all')
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    loadData()
  }, [])

  async function loadData() {
    try {
      setIsLoading(true)
      setError(null)

      // Check if we're in development mode
      const isDev = window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        // Use mock data in development mode
        const [employeeResponse, vacationResponse] = await Promise.all([
          mockApiCall(mockEmployees),
          mockApiCall(mockVacationRequests)
        ])

        if (employeeResponse.success && employeeResponse.data) {
          setEmployees(employeeResponse.data)
        }

        if (vacationResponse.success && vacationResponse.data) {
          setVacationRequests(vacationResponse.data)
        }
      } else {
        // Load employees and vacation requests in parallel
        const [employeeResponse, vacationResponse] = await Promise.all([
          window.electronAPI.employees.list(),
          window.electronAPI.vacation.list()
        ])

        if (employeeResponse.success && employeeResponse.data) {
          setEmployees(employeeResponse.data)
        }

        if (vacationResponse.success && vacationResponse.data) {
          setVacationRequests(vacationResponse.data)
        } else {
          setError(vacationResponse.error || 'Fehler beim Laden der Urlaubsanträge')
        }
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Laden der Daten')
      console.error(err)
    } finally {
      setIsLoading(false)
    }
  }

  function getEmployeeById(id: string): Employee | undefined {
    return employees.find(emp => emp.id === id)
  }

  function getFilteredRequests(): VacationRequest[] {
    let filtered = [...vacationRequests]

    // Status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter(req => req.status === statusFilter)
    }

    // Employee filter
    if (employeeFilter !== 'all') {
      filtered = filtered.filter(req => req.employeeId === employeeFilter)
    }

    // Type filter
    if (typeFilter !== 'all') {
      filtered = filtered.filter(req => req.type === typeFilter)
    }

    // Search filter
    if (searchTerm) {
      const term = searchTerm.toLowerCase()
      filtered = filtered.filter(req => {
        const employee = getEmployeeById(req.employeeId)
        const employeeName = employee ? `${employee.firstName} ${employee.lastName}`.toLowerCase() : ''
        const reason = (req.reason || '').toLowerCase()
        return employeeName.includes(term) || reason.includes(term)
      })
    }

    // Sort by request date (newest first)
    return filtered.sort((a, b) =>
      new Date(b.requestedAt).getTime() - new Date(a.requestedAt).getTime()
    )
  }

  function getStatusBadge(status: VacationRequest['status']) {
    switch (status) {
      case 'pending': return { badge: 'badge-warning', icon: AlertCircle, text: 'Ausstehend' }
      case 'approved': return { badge: 'badge-success', icon: CheckCircle, text: 'Genehmigt' }
      case 'rejected': return { badge: 'badge-danger', icon: XCircle, text: 'Abgelehnt' }
      case 'cancelled': return { badge: 'badge-secondary', icon: XCircle, text: 'Storniert' }
    }
  }

  function getTypeLabel(type: VacationRequest['type']) {
    switch (type) {
      case 'vacation': return { label: 'Urlaub', color: 'text-blue-600' }
      case 'sick': return { label: 'Krankmeldung', color: 'text-red-600' }
      case 'personal': return { label: 'Persönlicher Tag', color: 'text-purple-600' }
      case 'training': return { label: 'Fortbildung', color: 'text-green-600' }
    }
  }

  function calculateDays(startDate: string, endDate: string): number {
    return differenceInDays(parseISO(endDate), parseISO(startDate)) + 1
  }

  async function handleCreateRequest(requestData: Omit<VacationRequest, 'id' | 'requestedAt'>) {
    try {
      // Check if we're in development mode
      const isDev = window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        // Simulate API call in development mode
        const response = await mockApiCall({ success: true })
        if (response.success) {
          await loadData()
          setShowForm(false)
        }
      } else {
        const response = await window.electronAPI.vacation.create(requestData)
        if (response.success) {
          await loadData()
          setShowForm(false)
        } else {
          setError(response.error || 'Fehler beim Erstellen des Antrags')
        }
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Erstellen')
      console.error(err)
    }
  }

  async function handleUpdateRequest(id: string, updates: Partial<VacationRequest>) {
    try {
      // Check if we're in development mode
      const isDev = window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        // Simulate API call in development mode
        const response = await mockApiCall({ success: true })
        if (response.success) {
          await loadData()
          setEditingRequest(null)
        }
      } else {
        const response = await window.electronAPI.vacation.update(id, updates)
        if (response.success) {
          await loadData()
          setEditingRequest(null)
        } else {
          setError(response.error || 'Fehler beim Aktualisieren des Antrags')
        }
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Aktualisieren')
      console.error(err)
    }
  }

  async function handleDeleteRequest(id: string) {
    if (!confirm('Möchten Sie diesen Antrag wirklich löschen?')) {
      return
    }

    try {
      // Check if we're in development mode
      const isDev = window.electronAPI?.dev?.isDevMode()

      if (isDev) {
        // Simulate API call in development mode
        const response = await mockApiCall({ success: true })
        if (response.success) {
          await loadData()
        }
      } else {
        const response = await window.electronAPI.vacation.delete(id)
        if (response.success) {
          await loadData()
        } else {
          setError(response.error || 'Fehler beim Löschen des Antrags')
        }
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Löschen')
      console.error(err)
    }
  }

  async function handleStatusChange(request: VacationRequest, newStatus: VacationRequest['status']) {
    const updates: Partial<VacationRequest> = {
      status: newStatus,
      decidedAt: new Date().toISOString(),
      decidedBy: 'Admin' // In a real app, this would be the current user
    }

    await handleUpdateRequest(request.id, updates)
  }

  const filteredRequests = getFilteredRequests()
  const stats = {
    total: vacationRequests.length,
    pending: vacationRequests.filter(req => req.status === 'pending').length,
    approved: vacationRequests.filter(req => req.status === 'approved').length,
    rejected: vacationRequests.filter(req => req.status === 'rejected').length
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="flex flex-col items-center gap-md">
          <div className="spinner" style={{ width: '40px', height: '40px' }}></div>
          <p className="text-muted">Urlaubsanträge werden geladen...</p>
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
            <Briefcase size={24} />
            <div>
              <h1 className="text-xl font-bold">Urlaubsverwaltung</h1>
              <p className="text-muted">{stats.total} Anträge insgesamt</p>
            </div>
          </div>
          <button
            className="btn btn-primary"
            onClick={() => setShowForm(true)}
          >
            <Plus size={20} />
            Neuer Antrag
          </button>
        </div>

        {error && (
          <div className="alert alert-danger mt-md">
            {error}
          </div>
        )}

        {/* Statistics */}
        <div className="grid grid-cols-4 gap-md mt-md">
          <div className="card">
            <div className="card-body text-center">
              <div className="text-2xl font-bold text-primary">{stats.total}</div>
              <div className="text-sm text-muted">Gesamt</div>
            </div>
          </div>
          <div className="card">
            <div className="card-body text-center">
              <div className="text-2xl font-bold text-warning">{stats.pending}</div>
              <div className="text-sm text-muted">Ausstehend</div>
            </div>
          </div>
          <div className="card">
            <div className="card-body text-center">
              <div className="text-2xl font-bold text-success">{stats.approved}</div>
              <div className="text-sm text-muted">Genehmigt</div>
            </div>
          </div>
          <div className="card">
            <div className="card-body text-center">
              <div className="text-2xl font-bold text-danger">{stats.rejected}</div>
              <div className="text-sm text-muted">Abgelehnt</div>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="grid grid-cols-5 gap-md mt-md">
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
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="all">Alle Status</option>
              <option value="pending">Ausstehend</option>
              <option value="approved">Genehmigt</option>
              <option value="rejected">Abgelehnt</option>
              <option value="cancelled">Storniert</option>
            </select>
          </div>

          <div className="form-group">
            <select
              className="form-select"
              value={employeeFilter}
              onChange={(e) => setEmployeeFilter(e.target.value)}
            >
              <option value="all">Alle Mitarbeiter</option>
              {employees
                .sort((a, b) => `${a.lastName} ${a.firstName}`.localeCompare(`${b.lastName} ${b.firstName}`))
                .map(emp => (
                  <option key={emp.id} value={emp.id}>
                    {emp.lastName}, {emp.firstName}
                  </option>
                ))}
            </select>
          </div>

          <div className="form-group">
            <select
              className="form-select"
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
            >
              <option value="all">Alle Typen</option>
              <option value="vacation">Urlaub</option>
              <option value="sick">Krankmeldung</option>
              <option value="personal">Persönlicher Tag</option>
              <option value="training">Fortbildung</option>
            </select>
          </div>

          <div className="flex items-center gap-sm text-sm text-muted">
            <Filter size={16} />
            <span>{filteredRequests.length} gefiltert</span>
          </div>
        </div>
      </div>

      {/* Vacation Requests List */}
      <div className="flex-1 overflow-auto">
        {filteredRequests.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-muted">
            <Briefcase size={48} />
            <p className="mt-md">
              {vacationRequests.length === 0
                ? 'Noch keine Urlaubsanträge vorhanden'
                : 'Keine Anträge entsprechen den Filterkriterien'
              }
            </p>
          </div>
        ) : (
          <div className="p-md space-y-md">
            {filteredRequests.map((request) => {
              const employee = getEmployeeById(request.employeeId)
              const status = getStatusBadge(request.status)
              const type = getTypeLabel(request.type)
              const days = calculateDays(request.startDate, request.endDate)

              return (
                <div key={request.id} className="card">
                  <div className="card-body">
                    <div className="flex items-start justify-between">
                      <div className="flex items-start gap-md">
                        <div className="w-12 h-12 rounded-full bg-primary text-white flex items-center justify-center font-bold">
                          {employee ? `${employee.firstName[0]}${employee.lastName[0]}` : '??'}
                        </div>

                        <div className="flex-1">
                          <div className="flex items-center gap-sm mb-sm">
                            <h3 className="font-bold">
                              {employee ? `${employee.firstName} ${employee.lastName}` : 'Unbekannter Mitarbeiter'}
                            </h3>
                            <div className={`badge ${status.badge} flex items-center gap-xs`}>
                              <status.icon size={12} />
                              {status.text}
                            </div>
                          </div>

                          <div className="grid grid-cols-2 gap-md text-sm">
                            <div>
                              <div className="flex items-center gap-sm mb-xs">
                                <Calendar size={14} className="text-muted" />
                                <span className="font-medium">
                                  {window.electronAPI.utils.formatDate(request.startDate)} - {window.electronAPI.utils.formatDate(request.endDate)}
                                </span>
                                <span className="badge badge-info">
                                  {days} {days === 1 ? 'Tag' : 'Tage'}
                                </span>
                              </div>

                              <div className="flex items-center gap-sm">
                                <div className={`w-3 h-3 rounded-full ${type.color === 'text-blue-600' ? 'bg-blue-500' :
                                  type.color === 'text-red-600' ? 'bg-red-500' :
                                  type.color === 'text-purple-600' ? 'bg-purple-500' : 'bg-green-500'}`}></div>
                                <span className={type.color}>{type.label}</span>
                              </div>
                            </div>

                            <div>
                              <div className="flex items-center gap-sm mb-xs text-muted">
                                <Clock size={14} />
                                <span>
                                  Beantragt am {window.electronAPI.utils.formatDate(request.requestedAt)}
                                </span>
                              </div>

                              {employee && (
                                <div className="flex items-center gap-sm text-muted">
                                  <User size={14} />
                                  <span>{employee.department} • {employee.position}</span>
                                </div>
                              )}
                            </div>
                          </div>

                          {request.reason && (
                            <div className="mt-md p-sm bg-secondary rounded">
                              <div className="text-sm">
                                <span className="font-medium text-muted">Grund:</span>
                                <p className="mt-xs">{request.reason}</p>
                              </div>
                            </div>
                          )}

                          {request.notes && (
                            <div className="mt-sm p-sm bg-tertiary rounded">
                              <div className="text-sm">
                                <span className="font-medium text-muted">Anmerkungen:</span>
                                <p className="mt-xs">{request.notes}</p>
                              </div>
                            </div>
                          )}

                          {request.decidedAt && request.decidedBy && (
                            <div className="mt-sm text-xs text-muted">
                              Entschieden von {request.decidedBy} am {window.electronAPI.utils.formatDate(request.decidedAt)}
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="flex flex-col gap-sm">
                        {request.status === 'pending' && (
                          <>
                            <button
                              className="btn btn-sm btn-success"
                              onClick={() => handleStatusChange(request, 'approved')}
                            >
                              <CheckCircle size={14} />
                              Genehmigen
                            </button>
                            <button
                              className="btn btn-sm btn-danger"
                              onClick={() => handleStatusChange(request, 'rejected')}
                            >
                              <XCircle size={14} />
                              Ablehnen
                            </button>
                          </>
                        )}

                        <button
                          className="btn btn-sm btn-secondary"
                          onClick={() => setEditingRequest(request)}
                        >
                          Bearbeiten
                        </button>

                        <button
                          className="btn btn-sm btn-danger"
                          onClick={() => handleDeleteRequest(request.id)}
                        >
                          Löschen
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>

      {/* Vacation Form Modal */}
      {(showForm || editingRequest) && (
        <div className="modal-overlay">
          <div className="modal" style={{ width: '600px' }}>
            <VacationForm
              request={editingRequest}
              employees={employees}
              onSave={editingRequest
                ? (updates) => handleUpdateRequest(editingRequest.id, updates)
                : handleCreateRequest
              }
              onCancel={() => {
                setShowForm(false)
                setEditingRequest(null)
              }}
            />
          </div>
        </div>
      )}
    </div>
  )
}