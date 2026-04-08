import React, { useState, useEffect } from 'react'
import {
  Settings,
  Server,
  Shield,
  Database,
  Download,
  Upload,
  RotateCw,
  Trash2,
  AlertCircle,
  CheckCircle,
  Key,
  Globe,
  Clock,
  Users
} from 'lucide-react'
import { AppConfig } from '../../types'

export default function SettingsPage() {
  const [config, setConfig] = useState<AppConfig | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [connectionStatus, setConnectionStatus] = useState<'checking' | 'connected' | 'disconnected'>('checking')
  const [stats, setStats] = useState<any>(null)

  const [formData, setFormData] = useState({
    companyName: '',
    hidriveUrl: '',
    username: '',
    businessHours: {
      start: '08:00',
      end: '17:00'
    },
    overtimeRules: {
      dailyThreshold: 8,
      weeklyThreshold: 40,
      rate: 1.5
    }
  })

  useEffect(() => {
    loadSettings()
    checkConnection()
    loadStats()
  }, [])

  async function loadSettings() {
    try {
      setIsLoading(true)
      setError(null)

      const response = await window.electronAPI.config.get()

      if (response.success && response.data) {
        setConfig(response.data)
        setFormData({
          companyName: response.data.companyName || '',
          hidriveUrl: response.data.hidriveUrl || '',
          username: response.data.username || '',
          businessHours: response.data.businessHours || {
            start: '08:00',
            end: '17:00'
          },
          overtimeRules: response.data.overtimeRules || {
            dailyThreshold: 8,
            weeklyThreshold: 40,
            rate: 1.5
          }
        })
      } else {
        setError('Fehler beim Laden der Einstellungen')
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Laden der Einstellungen')
      console.error(err)
    } finally {
      setIsLoading(false)
    }
  }

  async function checkConnection() {
    try {
      setConnectionStatus('checking')
      const response = await window.electronAPI.auth.testConnection()

      setConnectionStatus(response.success && response.data?.connected ? 'connected' : 'disconnected')
    } catch (err) {
      setConnectionStatus('disconnected')
      console.error('Connection test failed:', err)
    }
  }

  async function loadStats() {
    try {
      const response = await window.electronAPI.system.stats()

      if (response.success && response.data) {
        setStats(response.data)
      }
    } catch (err) {
      console.error('Failed to load stats:', err)
    }
  }

  async function saveSettings() {
    try {
      setIsSaving(true)
      setError(null)
      setSuccessMessage(null)

      const response = await window.electronAPI.config.set(formData)

      if (response.success) {
        setSuccessMessage('Einstellungen erfolgreich gespeichert')
        await loadSettings()
      } else {
        setError(response.error || 'Fehler beim Speichern der Einstellungen')
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Speichern')
      console.error(err)
    } finally {
      setIsSaving(false)
    }
  }

  async function createBackup() {
    try {
      setError(null)
      setSuccessMessage(null)

      const response = await window.electronAPI.system.backup()

      if (response.success && response.data) {
        setSuccessMessage(`Backup erfolgreich erstellt: ${response.data.backupId}`)
        await loadStats()
      } else {
        setError(response.error || 'Fehler beim Erstellen des Backups')
      }
    } catch (err) {
      setError('Unerwarteter Fehler beim Backup')
      console.error(err)
    }
  }

  function handleInputChange(field: string, value: any) {
    if (field.includes('.')) {
      const [parent, child] = field.split('.')
      setFormData(prev => ({
        ...prev,
        [parent]: {
          ...prev[parent as keyof typeof prev] as any,
          [child]: value
        }
      }))
    } else {
      setFormData(prev => ({ ...prev, [field]: value }))
    }
  }

  function getConnectionStatusIcon() {
    switch (connectionStatus) {
      case 'checking':
        return <div className="spinner w-4 h-4" />
      case 'connected':
        return <CheckCircle size={16} className="text-success" />
      case 'disconnected':
        return <AlertCircle size={16} className="text-danger" />
    }
  }

  function getConnectionStatusText() {
    switch (connectionStatus) {
      case 'checking':
        return 'Verbindung wird geprüft...'
      case 'connected':
        return 'Verbunden mit HiDrive'
      case 'disconnected':
        return 'Keine Verbindung zu HiDrive'
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="flex flex-col items-center gap-md">
          <div className="spinner" style={{ width: '40px', height: '40px' }}></div>
          <p className="text-muted">Einstellungen werden geladen...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="h-full overflow-auto">
      <div className="p-md max-w-4xl mx-auto">
        {/* Header */}
        <div className="flex items-center gap-md mb-lg">
          <Settings size={32} />
          <div>
            <h1 className="text-2xl font-bold">Einstellungen</h1>
            <p className="text-muted">Konfiguration der Eingliederungshilfe Administration</p>
          </div>
        </div>

        {/* Messages */}
        {error && (
          <div className="alert alert-danger mb-md">
            <AlertCircle size={16} />
            {error}
          </div>
        )}

        {successMessage && (
          <div className="alert alert-success mb-md">
            <CheckCircle size={16} />
            {successMessage}
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-lg">
          {/* Connection Status */}
          <div className="card">
            <div className="card-header">
              <h2 className="font-bold flex items-center gap-sm">
                <Server size={20} />
                Verbindungsstatus
              </h2>
            </div>
            <div className="card-body">
              <div className="flex items-center justify-between mb-md">
                <div className="flex items-center gap-sm">
                  {getConnectionStatusIcon()}
                  <span className="font-medium">{getConnectionStatusText()}</span>
                </div>
                <button
                  className="btn btn-sm btn-secondary"
                  onClick={checkConnection}
                  disabled={connectionStatus === 'checking'}
                >
                  <RotateCw size={14} />
                  Prüfen
                </button>
              </div>

              {config && (
                <div className="space-y-sm text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted">HiDrive URL:</span>
                    <span className="font-mono">{config.hidriveUrl}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted">Benutzername:</span>
                    <span>{config.username}</span>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Storage Statistics */}
          <div className="card">
            <div className="card-header">
              <h2 className="font-bold flex items-center gap-sm">
                <Database size={20} />
                Speicher-Statistiken
              </h2>
            </div>
            <div className="card-body">
              {stats ? (
                <div className="grid grid-cols-2 gap-md">
                  <div className="text-center">
                    <div className="text-2xl font-bold text-primary">{stats.totalFiles}</div>
                    <div className="text-sm text-muted">Dateien gesamt</div>
                  </div>
                  <div className="text-center">
                    <div className="text-2xl font-bold text-info">{stats.categoryCounts.employees || 0}</div>
                    <div className="text-sm text-muted">Mitarbeiter</div>
                  </div>
                  <div className="text-center">
                    <div className="text-2xl font-bold text-success">{stats.categoryCounts.shifts || 0}</div>
                    <div className="text-sm text-muted">Schichten</div>
                  </div>
                  <div className="text-center">
                    <div className="text-2xl font-bold text-warning">{stats.categoryCounts.vacation || 0}</div>
                    <div className="text-sm text-muted">Urlaubsanträge</div>
                  </div>
                </div>
              ) : (
                <div className="text-center text-muted">
                  <Database size={32} className="mx-auto mb-sm opacity-50" />
                  <p>Statistiken werden geladen...</p>
                </div>
              )}
            </div>
          </div>

          {/* Company Settings */}
          <div className="card">
            <div className="card-header">
              <h2 className="font-bold flex items-center gap-sm">
                <Globe size={20} />
                Unternehmenseinstellungen
              </h2>
            </div>
            <div className="card-body space-y-md">
              <div className="form-group">
                <label className="form-label">Firmenname</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.companyName}
                  onChange={(e) => handleInputChange('companyName', e.target.value)}
                  placeholder="Name Ihrer Einrichtung"
                />
              </div>

              <div className="form-group">
                <label className="form-label">HiDrive URL</label>
                <input
                  type="url"
                  className="form-input"
                  value={formData.hidriveUrl}
                  onChange={(e) => handleInputChange('hidriveUrl', e.target.value)}
                  placeholder="https://webdav.hidrive.strato.com/"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Benutzername</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.username}
                  onChange={(e) => handleInputChange('username', e.target.value)}
                  placeholder="HiDrive Benutzername"
                />
              </div>
            </div>
          </div>

          {/* Work Time Settings */}
          <div className="card">
            <div className="card-header">
              <h2 className="font-bold flex items-center gap-sm">
                <Clock size={20} />
                Arbeitszeit-Einstellungen
              </h2>
            </div>
            <div className="card-body space-y-md">
              <div className="grid grid-cols-2 gap-md">
                <div className="form-group">
                  <label className="form-label">Arbeitsbeginn</label>
                  <input
                    type="time"
                    className="form-input"
                    value={formData.businessHours.start}
                    onChange={(e) => handleInputChange('businessHours.start', e.target.value)}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Arbeitsende</label>
                  <input
                    type="time"
                    className="form-input"
                    value={formData.businessHours.end}
                    onChange={(e) => handleInputChange('businessHours.end', e.target.value)}
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-md">
                <div className="form-group">
                  <label className="form-label">Überstunden ab (Stunden/Tag)</label>
                  <input
                    type="number"
                    min="1"
                    max="24"
                    step="0.5"
                    className="form-input"
                    value={formData.overtimeRules.dailyThreshold}
                    onChange={(e) => handleInputChange('overtimeRules.dailyThreshold', parseFloat(e.target.value) || 8)}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Überstunden ab (Stunden/Woche)</label>
                  <input
                    type="number"
                    min="1"
                    max="168"
                    step="0.5"
                    className="form-input"
                    value={formData.overtimeRules.weeklyThreshold}
                    onChange={(e) => handleInputChange('overtimeRules.weeklyThreshold', parseFloat(e.target.value) || 40)}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Überstunden-Zuschlag (Faktor)</label>
                <input
                  type="number"
                  min="1"
                  max="3"
                  step="0.1"
                  className="form-input"
                  value={formData.overtimeRules.rate}
                  onChange={(e) => handleInputChange('overtimeRules.rate', parseFloat(e.target.value) || 1.5)}
                />
                <div className="text-sm text-muted mt-xs">
                  1.5 = 150% des Grundlohns für Überstunden
                </div>
              </div>
            </div>
          </div>

          {/* Data Management */}
          <div className="card">
            <div className="card-header">
              <h2 className="font-bold flex items-center gap-sm">
                <Shield size={20} />
                Datenverwaltung
              </h2>
            </div>
            <div className="card-body space-y-md">
              <div className="flex items-center justify-between p-sm bg-secondary rounded">
                <div className="flex items-center gap-sm">
                  <Key size={16} />
                  <div>
                    <div className="font-medium">Verschlüsselung</div>
                    <div className="text-sm text-muted">AES-256 + libsodium</div>
                  </div>
                </div>
                <div className="badge badge-success">Aktiv</div>
              </div>

              <div className="grid grid-cols-2 gap-sm">
                <button
                  className="btn btn-secondary flex items-center gap-sm"
                  onClick={createBackup}
                >
                  <Download size={16} />
                  Backup erstellen
                </button>

                <button
                  className="btn btn-secondary flex items-center gap-sm"
                  onClick={() => window.electronAPI.dialog.openFile()}
                >
                  <Upload size={16} />
                  Backup wiederherstellen
                </button>
              </div>

              <div className="text-xs text-muted">
                Alle Daten werden verschlüsselt in Ihrem HiDrive Business Account gespeichert.
                Backups enthalten alle Mitarbeiter-, Schicht- und Urlaubsdaten.
              </div>
            </div>
          </div>

          {/* Application Info */}
          <div className="card">
            <div className="card-header">
              <h2 className="font-bold flex items-center gap-sm">
                <Users size={20} />
                Anwendungsinformationen
              </h2>
            </div>
            <div className="card-body">
              <div className="space-y-sm text-sm">
                <div className="flex justify-between">
                  <span className="text-muted">Version:</span>
                  <span className="font-mono">{window.versions?.app()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted">Electron:</span>
                  <span className="font-mono">{window.versions?.electron()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted">Node.js:</span>
                  <span className="font-mono">{window.versions?.node()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted">Chrome:</span>
                  <span className="font-mono">{window.versions?.chrome()}</span>
                </div>
              </div>

              <div className="mt-md pt-md border-t border-border-color">
                <div className="text-xs text-muted">
                  Eingliederungshilfe Administration - Eine sichere, dezentrale Lösung
                  für die Verwaltung von Mitarbeitern und Dienstplänen in sozialen Einrichtungen.
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Save Button */}
        <div className="mt-lg flex justify-end">
          <button
            className="btn btn-primary btn-lg"
            onClick={saveSettings}
            disabled={isSaving}
          >
            {isSaving ? (
              <div className="flex items-center gap-sm">
                <div className="spinner"></div>
                Speichern...
              </div>
            ) : (
              <div className="flex items-center gap-sm">
                <Settings size={20} />
                Einstellungen speichern
              </div>
            )}
          </button>
        </div>
      </div>
    </div>
  )
}