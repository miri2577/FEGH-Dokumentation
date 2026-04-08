import React, { useState, useEffect } from 'react'
import {
  Plus,
  Search,
  Edit3,
  Trash2,
  Users,
  Calendar,
  Clock,
  Heart,
  FileText,
  Filter,
  User
} from 'lucide-react'
import { Client } from '../../types'

export default function ClientManagement() {
  const [clients, setClients] = useState<Client[]>([])
  const [filteredClients, setFilteredClients] = useState<Client[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [hilfeTypFilter, setHilfeTypFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [showForm, setShowForm] = useState(false)
  const [editingClient, setEditingClient] = useState<Client | null>(null)

  useEffect(() => {
    loadClients()
  }, [])

  useEffect(() => {
    filterClients()
  }, [clients, searchTerm, hilfeTypFilter, statusFilter])

  async function loadClients() {
    try {
      setIsLoading(true)
      setError(null)

      // Check if we're in development mode
      const isDev = await window.electronAPI?.dev?.isDevMode()
      console.log('🔧 ClientManagement Dev mode:', isDev)

      if (isDev) {
        // Use imported or mock client data
        const importedClients = window._importedData?.clients || []
        console.log('👥 Loading clients from imported data:', importedClients.length)
        setClients(importedClients)
      } else {
        // Load from real API when implemented
        // const response = await window.electronAPI.clients.list()
        // if (response.success && response.data) {
        //   setClients(response.data)
        // }
        setClients([]) // Placeholder
      }
    } catch (err) {
      setError('Fehler beim Laden der Klienten')
      console.error(err)
    } finally {
      setIsLoading(false)
    }
  }

  function filterClients() {
    let filtered = [...clients]

    // Search filter
    if (searchTerm) {
      const term = searchTerm.toLowerCase()
      filtered = filtered.filter(client => {
        const fullName = `${client.firstName || ''} ${client.lastName || ''} ${client.name}`.toLowerCase()
        return fullName.includes(term) ||
               (client.kostenuebernahme?.toLowerCase().includes(term)) ||
               (client.berufsgruppe?.toLowerCase().includes(term))
      })
    }

    // Hilfe-Typ filter
    if (hilfeTypFilter !== 'all') {
      filtered = filtered.filter(client => client.hilfeTyp === hilfeTypFilter)
    }

    // Status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter(client =>
        statusFilter === 'active' ? client.isActive : !client.isActive
      )
    }

    setFilteredClients(filtered)
  }

  function getHilfeTypBadge(hilfeTyp?: string) {
    switch (hilfeTyp) {
      case 'familienhilfe':
        return 'badge-info'
      case 'eingliederungshilfe':
        return 'badge-success'
      default:
        return 'badge-secondary'
    }
  }

  function getHilfeTypLabel(hilfeTyp?: string) {
    switch (hilfeTyp) {
      case 'familienhilfe':
        return 'Familienhilfe'
      case 'eingliederungshilfe':
        return 'Eingliederungshilfe'
      default:
        return 'Unbekannt'
    }
  }

  function calculateProgress(verbraucht: number, gesamt?: number): number {
    if (!gesamt || gesamt === 0) return 0
    return Math.min((verbraucht / gesamt) * 100, 100)
  }

  function formatDate(dateString?: string): string {
    if (!dateString) return '-'
    return new Date(dateString).toLocaleDateString('de-DE')
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="flex flex-col items-center gap-md">
          <div className="spinner" style={{ width: '40px', height: '40px' }}></div>
          <p className="text-muted">Klienten werden geladen...</p>
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
            <h1 className="text-xl font-bold">Klientenverwaltung</h1>
            <p className="text-muted">{clients.length} Klienten insgesamt</p>
          </div>
          <button
            className="btn btn-primary"
            onClick={() => setShowForm(true)}
          >
            <Plus size={20} />
            Neuer Klient
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
              value={hilfeTypFilter}
              onChange={(e) => setHilfeTypFilter(e.target.value)}
            >
              <option value="all">Alle Hilfearten</option>
              <option value="familienhilfe">Familienhilfe</option>
              <option value="eingliederungshilfe">Eingliederungshilfe</option>
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
            <span>{filteredClients.length} gefiltert</span>
          </div>
        </div>
      </div>

      {/* Client List */}
      <div className="flex-1 overflow-auto">
        {filteredClients.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-muted">
            <Users size={48} />
            <p className="mt-md">
              {clients.length === 0
                ? 'Noch keine Klienten angelegt'
                : 'Keine Klienten entsprechen den Filterkriterien'
              }
            </p>
            {clients.length === 0 && (
              <p className="text-sm mt-xs">
                Importieren Sie Klientendaten über den "Import"-Tab
              </p>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-md p-md">
            {filteredClients.map((client) => {
              const fullName = client.firstName && client.lastName
                ? `${client.firstName} ${client.lastName}`
                : client.name
              const progress = calculateProgress(client.verbrauchteStunden, client.fachleistungsstunden)

              return (
                <div key={client.id} className="card">
                  <div className="card-body">
                    <div className="flex items-start justify-between mb-md">
                      <div className="flex items-center gap-sm">
                        <div className="w-12 h-12 rounded-full bg-info text-white flex items-center justify-center font-bold">
                          {fullName.split(' ').map(n => n[0]).join('').slice(0, 2)}
                        </div>
                        <div>
                          <h3 className="font-bold">{fullName}</h3>
                          {client.geburtsdatum && (
                            <p className="text-sm text-muted">
                              *{formatDate(client.geburtsdatum)}
                            </p>
                          )}
                        </div>
                      </div>

                      <div className="flex flex-col items-end gap-xs">
                        {client.isActive ? (
                          <div className="badge badge-success">
                            <Heart size={12} />
                            Aktiv
                          </div>
                        ) : (
                          <div className="badge badge-secondary">
                            Inaktiv
                          </div>
                        )}

                        {client.hilfeTyp && (
                          <div className={`badge ${getHilfeTypBadge(client.hilfeTyp)}`}>
                            {getHilfeTypLabel(client.hilfeTyp)}
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="space-y-2 text-sm">
                      {client.kostenuebernahme && (
                        <div className="flex items-center gap-sm text-muted">
                          <FileText size={14} />
                          <span>{client.kostenuebernahme}</span>
                        </div>
                      )}

                      {client.betreuungSeit && (
                        <div className="flex items-center gap-sm text-muted">
                          <Calendar size={14} />
                          <span>Seit {formatDate(client.betreuungSeit)}</span>
                        </div>
                      )}

                      {client.fachleistungsstunden && (
                        <div>
                          <div className="flex items-center justify-between text-muted mb-xs">
                            <div className="flex items-center gap-sm">
                              <Clock size={14} />
                              <span>Fachleistungsstunden</span>
                            </div>
                            <span className="text-xs">
                              {client.verbrauchteStunden}h / {client.fachleistungsstunden}h
                            </span>
                          </div>
                          <div className="w-full bg-secondary rounded-full h-2">
                            <div
                              className={`h-2 rounded-full transition-all duration-300 ${
                                progress > 90 ? 'bg-danger' :
                                progress > 75 ? 'bg-warning' : 'bg-success'
                              }`}
                              style={{ width: `${progress}%` }}
                            />
                          </div>
                          <div className="text-xs text-muted mt-xs">
                            {progress.toFixed(1)}% verbraucht
                            {client.fachleistungsIntervall && (
                              <span> ({client.fachleistungsIntervall})</span>
                            )}
                          </div>
                        </div>
                      )}
                    </div>

                    {client.icfBereiche && client.icfBereiche.length > 0 && (
                      <div className="mt-md">
                        <div className="flex flex-wrap gap-xs">
                          {client.icfBereiche.slice(0, 2).map((bereich, index) => (
                            <span key={index} className="badge badge-info text-xs">
                              {bereich}
                            </span>
                          ))}
                          {client.icfBereiche.length > 2 && (
                            <span className="badge badge-secondary text-xs">
                              +{client.icfBereiche.length - 2}
                            </span>
                          )}
                        </div>
                      </div>
                    )}
                  </div>

                  <div className="card-footer flex justify-end gap-sm">
                    <button
                      className="btn btn-sm btn-secondary"
                      onClick={() => setEditingClient(client)}
                    >
                      <Edit3 size={14} />
                      Bearbeiten
                    </button>
                    <button
                      className="btn btn-sm btn-danger"
                      onClick={() => {
                        if (confirm(`Möchten Sie ${fullName} wirklich löschen?`)) {
                          // Handle delete
                        }
                      }}
                    >
                      <Trash2 size={14} />
                      Löschen
                    </button>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>

      {/* TODO: Client Form Modal */}
      {(showForm || editingClient) && (
        <div className="modal-overlay">
          <div className="modal" style={{ width: '600px' }}>
            <div className="card">
              <div className="card-header">
                <h3 className="font-bold">
                  {editingClient ? 'Klient bearbeiten' : 'Neuer Klient'}
                </h3>
              </div>
              <div className="card-body">
                <p className="text-muted">
                  Klientenformular wird implementiert...
                </p>
              </div>
              <div className="card-footer flex justify-end gap-sm">
                <button
                  className="btn btn-secondary"
                  onClick={() => {
                    setShowForm(false)
                    setEditingClient(null)
                  }}
                >
                  Abbrechen
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}