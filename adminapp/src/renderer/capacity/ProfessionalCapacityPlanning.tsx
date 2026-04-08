import React, { useState, useMemo, useEffect } from 'react'
import {
  Calculator,
  Settings,
  Users,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Clock,
  Calendar,
  BarChart3,
  Eye,
  EyeOff,
  Filter,
  Download,
  RefreshCw,
  Minus,
  Plus,
  Target
} from 'lucide-react'
import { computeTeam, distributeSubstitution, BERLIN_DEFAULT, type Staff, type BerlinPreset } from './calc'
import { CapacityCards } from './Cards'
import { mockEmployees } from '../utils/mockData'
import {
  getEmployeeColor,
  calculateCapacityStatus,
  type EmployeeColor,
  type CapacityStatus
} from '../../utils/employeeColors'

type ViewMode = 'overview' | 'detailed' | 'analytics'
type AlertLevel = 'all' | 'critical' | 'warning' | 'info'

interface CapacityAlert {
  id: string
  type: 'understaffed' | 'overstaffed' | 'overtime_risk' | 'efficiency_low' | 'availability_issue'
  severity: 'critical' | 'high' | 'medium' | 'low'
  employee?: string
  department?: string
  message: string
  recommendation: string
  value?: number
  threshold?: number
}

export default function ProfessionalCapacityPlanning() {
  // View Controls
  const [viewMode, setViewMode] = useState<ViewMode>('overview')
  const [alertFilter, setAlertFilter] = useState<AlertLevel>('all')
  const [showAdvanced, setShowAdvanced] = useState(false)
  const [showAlerts, setShowAlerts] = useState(true)
  const [autoRefresh, setAutoRefresh] = useState(true)

  // Configuration
  const [preset, setPreset] = useState<BerlinPreset>(BERLIN_DEFAULT)
  const [weeklyClientHours, setWeeklyClientHours] = useState(52)

  // Substitution Configuration
  const [absentEmployeeId, setAbsentEmployeeId] = useState('')
  const [absentWeeklyHours, setAbsentWeeklyHours] = useState(12)
  const [rep1Id, setRep1Id] = useState('')
  const [rep2Id, setRep2Id] = useState('')

  // Data State
  const [staff, setStaff] = useState<Staff[]>([])
  const [capacityAlerts, setCapacityAlerts] = useState<CapacityAlert[]>([])
  const [lastUpdate, setLastUpdate] = useState(new Date())

  useEffect(() => {
    loadStaffData()
  }, [])

  useEffect(() => {
    analyzeCapacityIssues()
  }, [staff, weeklyClientHours, preset])

  useEffect(() => {
    if (autoRefresh) {
      const interval = setInterval(() => {
        setLastUpdate(new Date())
        analyzeCapacityIssues()
      }, 30000) // Refresh every 30 seconds
      return () => clearInterval(interval)
    }
  }, [autoRefresh, staff, weeklyClientHours, preset])

  function loadStaffData() {
    const mockStaff: Staff[] = mockEmployees.map(emp => ({
      id: emp.id,
      name: `${emp.firstName} ${emp.lastName}`,
      contractHoursPerWeek: emp.weeklyHours,
      absenceRate: Math.random() * 0.15 + 0.05, // 5-20% absence rate
      assignedClientHoursPerWeek: Math.round(emp.weeklyHours * (0.5 + Math.random() * 0.3)) // 50-80% utilization
    }))

    setStaff(mockStaff)

    // Set default representatives
    if (mockStaff.length >= 3) {
      setAbsentEmployeeId(mockStaff[0].id)
      setRep1Id(mockStaff[1].id)
      setRep2Id(mockStaff[2].id)
    }
  }

  function analyzeCapacityIssues() {
    const alerts: CapacityAlert[] = []

    staff.forEach(member => {
      const utilizationRate = member.assignedClientHoursPerWeek / member.contractHoursPerWeek
      const availableHours = member.contractHoursPerWeek * (1 - member.absenceRate)
      const workload = member.assignedClientHoursPerWeek / availableHours

      // Understaffing alerts
      if (utilizationRate > 0.9) {
        alerts.push({
          id: `overstaffed-${member.id}`,
          type: 'overstaffed',
          severity: utilizationRate > 0.95 ? 'critical' : 'high',
          employee: member.name,
          message: `${member.name}: Überlastung (${(utilizationRate * 100).toFixed(1)}%)`,
          recommendation: 'Arbeitsbelastung reduzieren oder zusätzliche Unterstützung',
          value: utilizationRate * 100,
          threshold: 90
        })
      }

      // Low utilization alerts
      if (utilizationRate < 0.6) {
        alerts.push({
          id: `underutilized-${member.id}`,
          type: 'efficiency_low',
          severity: utilizationRate < 0.4 ? 'high' : 'medium',
          employee: member.name,
          message: `${member.name}: Niedrige Auslastung (${(utilizationRate * 100).toFixed(1)}%)`,
          recommendation: 'Zusätzliche Klienten zuweisen oder Stunden anpassen',
          value: utilizationRate * 100,
          threshold: 60
        })
      }

      // High absence rate alerts
      if (member.absenceRate > 0.12) {
        alerts.push({
          id: `absence-${member.id}`,
          type: 'availability_issue',
          severity: member.absenceRate > 0.18 ? 'critical' : 'high',
          employee: member.name,
          message: `${member.name}: Hohe Abwesenheitsrate (${(member.absenceRate * 100).toFixed(1)}%)`,
          recommendation: 'Ursachen analysieren und Maßnahmen einleiten',
          value: member.absenceRate * 100,
          threshold: 12
        })
      }

      // Overtime risk
      if (workload > 1.1) {
        alerts.push({
          id: `overtime-${member.id}`,
          type: 'overtime_risk',
          severity: workload > 1.2 ? 'critical' : 'high',
          employee: member.name,
          message: `${member.name}: Überstunden-Risiko (${(workload * 100).toFixed(1)}% verfügbare Zeit)`,
          recommendation: 'Arbeitsverteilung überprüfen oder Entlastung schaffen',
          value: workload * 100,
          threshold: 110
        })
      }
    })

    // Team-wide capacity analysis
    const totalCapacity = staff.reduce((sum, member) =>
      sum + (member.contractHoursPerWeek * (1 - member.absenceRate)), 0)
    const totalDemand = staff.reduce((sum, member) =>
      sum + member.assignedClientHoursPerWeek, 0)
    const teamUtilization = totalDemand / totalCapacity

    if (teamUtilization > 0.95) {
      alerts.push({
        id: 'team-capacity-critical',
        type: 'understaffed',
        severity: 'critical',
        department: 'Team',
        message: `Team-Kapazität kritisch: ${(teamUtilization * 100).toFixed(1)}% Auslastung`,
        recommendation: 'Zusätzliches Personal einstellen oder Arbeitsverteilung optimieren',
        value: teamUtilization * 100,
        threshold: 95
      })
    } else if (teamUtilization < 0.7) {
      alerts.push({
        id: 'team-capacity-low',
        type: 'efficiency_low',
        severity: 'medium',
        department: 'Team',
        message: `Team-Kapazität niedrig: ${(teamUtilization * 100).toFixed(1)}% Auslastung`,
        recommendation: 'Mehr Klienten aufnehmen oder Arbeitszeiten anpassen',
        value: teamUtilization * 100,
        threshold: 70
      })
    }

    setCapacityAlerts(alerts)
  }

  // Calculations
  const team = useMemo(() => {
    return computeTeam({ staff, weeklyClientHours, preset })
  }, [staff, weeklyClientHours, preset])

  const substitution = useMemo(() => {
    if (!absentEmployeeId || !rep1Id || !rep2Id) return undefined

    const absentMonthly = absentWeeklyHours * preset.weeklyToMonthlyFactor
    return distributeSubstitution(team.members, {
      absentEmployeeId,
      absentMonthlyClientHours: absentMonthly,
      rep1Id,
      rep2Id
    })
  }, [team.members, absentEmployeeId, absentWeeklyHours, preset, rep1Id, rep2Id])

  // Filter alerts based on current filter
  const filteredAlerts = useMemo(() => {
    if (alertFilter === 'all') return capacityAlerts

    const severityMap = {
      'critical': ['critical'],
      'warning': ['critical', 'high'],
      'info': ['critical', 'high', 'medium']
    }

    return capacityAlerts.filter(alert =>
      severityMap[alertFilter]?.includes(alert.severity)
    )
  }, [capacityAlerts, alertFilter])

  function getAlertColor(severity: string): string {
    switch (severity) {
      case 'critical': return 'text-red-600 bg-red-50 border-red-200'
      case 'high': return 'text-orange-600 bg-orange-50 border-orange-200'
      case 'medium': return 'text-yellow-600 bg-yellow-50 border-yellow-200'
      case 'low': return 'text-blue-600 bg-blue-50 border-blue-200'
      default: return 'text-gray-600 bg-gray-50 border-gray-200'
    }
  }

  function getAlertIcon(type: string) {
    switch (type) {
      case 'understaffed': return <Users className="text-red-500" size={16} />
      case 'overstaffed': return <TrendingUp className="text-orange-500" size={16} />
      case 'overtime_risk': return <Clock className="text-red-500" size={16} />
      case 'efficiency_low': return <TrendingDown className="text-yellow-500" size={16} />
      case 'availability_issue': return <AlertTriangle className="text-orange-500" size={16} />
      default: return <AlertTriangle className="text-gray-500" size={16} />
    }
  }

  function getCapacityBarColor(utilization: number): string {
    if (utilization >= 95) return 'bg-red-500'
    if (utilization >= 85) return 'bg-orange-500'
    if (utilization >= 70) return 'bg-green-500'
    if (utilization >= 50) return 'bg-blue-500'
    return 'bg-gray-400'
  }

  const criticalAlerts = capacityAlerts.filter(a => a.severity === 'critical').length
  const highAlerts = capacityAlerts.filter(a => a.severity === 'high').length

  return (
    <div className="h-full flex flex-col">
      {/* Professional Header */}
      <div className="card-header">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-md">
            <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
              <Calculator className="text-white" size={24} />
            </div>
            <div>
              <h1 className="text-xl font-bold">Professionelle Kapazitätsplanung</h1>
              <p className="text-sm text-muted">
                {staff.length} Mitarbeiter • {team.totalClientHours}h Klientenstunden •
                Letzte Aktualisierung: {lastUpdate.toLocaleTimeString('de-DE')}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-sm">
            {/* Alert Summary */}
            {(criticalAlerts > 0 || highAlerts > 0) && (
              <div className="flex items-center gap-xs">
                {criticalAlerts > 0 && (
                  <div className="badge badge-danger flex items-center gap-xs">
                    <AlertTriangle size={12} />
                    {criticalAlerts} Kritisch
                  </div>
                )}
                {highAlerts > 0 && (
                  <div className="badge badge-warning flex items-center gap-xs">
                    <AlertTriangle size={12} />
                    {highAlerts} Hoch
                  </div>
                )}
              </div>
            )}

            {/* Auto Refresh Toggle */}
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`btn btn-sm ${autoRefresh ? 'btn-primary' : 'btn-secondary'}`}
            >
              <RefreshCw size={14} className={autoRefresh ? 'animate-spin' : ''} />
              Auto-Update
            </button>

            {/* View Mode Toggle */}
            <div className="flex rounded-lg overflow-hidden border border-border-color">
              {(['overview', 'detailed', 'analytics'] as ViewMode[]).map((mode) => (
                <button
                  key={mode}
                  onClick={() => setViewMode(mode)}
                  className={`px-3 py-1 text-sm transition-colors ${
                    viewMode === mode
                      ? 'bg-primary text-white'
                      : 'bg-white text-primary hover:bg-secondary'
                  }`}
                >
                  {mode === 'overview' && <BarChart3 size={14} />}
                  {mode === 'detailed' && <Eye size={14} />}
                  {mode === 'analytics' && <TrendingUp size={14} />}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Alert Panel */}
        {showAlerts && filteredAlerts.length > 0 && (
          <div className="mt-md">
            <div className="flex items-center justify-between mb-sm">
              <h3 className="font-semibold flex items-center gap-sm">
                <AlertTriangle className="text-orange-500" size={16} />
                Kapazitäts-Warnungen ({filteredAlerts.length})
              </h3>

              <div className="flex items-center gap-sm">
                <select
                  value={alertFilter}
                  onChange={(e) => setAlertFilter(e.target.value as AlertLevel)}
                  className="form-select text-sm"
                >
                  <option value="all">Alle Meldungen</option>
                  <option value="critical">Nur Kritisch</option>
                  <option value="warning">Kritisch + Hoch</option>
                  <option value="info">Alle wichtigen</option>
                </select>

                <button
                  onClick={() => setShowAlerts(false)}
                  className="btn btn-sm btn-secondary"
                >
                  <EyeOff size={14} />
                  Ausblenden
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-sm">
              {filteredAlerts.slice(0, 4).map((alert) => (
                <div
                  key={alert.id}
                  className={`p-3 rounded-lg border ${getAlertColor(alert.severity)}`}
                >
                  <div className="flex items-start gap-sm">
                    {getAlertIcon(alert.type)}
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-sm">{alert.message}</div>
                      <div className="text-xs mt-1 opacity-75">{alert.recommendation}</div>
                      {alert.value && alert.threshold && (
                        <div className="mt-2">
                          <div className="flex justify-between text-xs mb-1">
                            <span>Aktuell: {alert.value.toFixed(1)}%</span>
                            <span>Grenze: {alert.threshold}%</span>
                          </div>
                          <div className="w-full bg-white rounded-full h-1.5">
                            <div
                              className={`h-1.5 rounded-full transition-all ${
                                alert.value > alert.threshold
                                  ? 'bg-red-500'
                                  : alert.value > alert.threshold * 0.9
                                  ? 'bg-orange-500'
                                  : 'bg-green-500'
                              }`}
                              style={{ width: `${Math.min(alert.value, 100)}%` }}
                            />
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {filteredAlerts.length > 4 && (
              <div className="text-center mt-sm">
                <span className="text-sm text-muted">
                  +{filteredAlerts.length - 4} weitere Warnungen
                </span>
              </div>
            )}
          </div>
        )}

        {!showAlerts && capacityAlerts.length > 0 && (
          <button
            onClick={() => setShowAlerts(true)}
            className="mt-md btn btn-sm btn-warning flex items-center gap-sm"
          >
            <Eye size={14} />
            {capacityAlerts.length} Warnungen anzeigen
          </button>
        )}
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        {viewMode === 'overview' && (
          <div className="p-md space-y-lg">
            {/* Team Capacity Overview */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-md">
              <div className="card">
                <div className="card-body">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-semibold text-muted">Team-Kapazität</h3>
                      <div className="text-2xl font-bold">
                        {((team.totalClientHours / (staff.reduce((sum, s) => sum + s.contractHoursPerWeek, 0))) * 100).toFixed(1)}%
                      </div>
                    </div>
                    <div className={`w-12 h-12 rounded-full flex items-center justify-center ${
                      team.totalClientHours / (staff.reduce((sum, s) => sum + s.contractHoursPerWeek, 0)) > 0.9
                        ? 'bg-red-100 text-red-600'
                        : 'bg-green-100 text-green-600'
                    }`}>
                      <TrendingUp size={20} />
                    </div>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="card-body">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-semibold text-muted">Verfügbare Stunden</h3>
                      <div className="text-2xl font-bold">
                        {staff.reduce((sum, s) => sum + (s.contractHoursPerWeek * (1 - s.absenceRate)), 0).toFixed(0)}h
                      </div>
                    </div>
                    <div className="w-12 h-12 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center">
                      <Clock size={20} />
                    </div>
                  </div>
                </div>
              </div>

              <div className="card">
                <div className="card-body">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-semibold text-muted">Kritische Warnungen</h3>
                      <div className="text-2xl font-bold text-red-600">{criticalAlerts}</div>
                    </div>
                    <div className="w-12 h-12 rounded-full bg-red-100 text-red-600 flex items-center justify-center">
                      <AlertTriangle size={20} />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Individual Staff Capacity */}
            <div className="card">
              <div className="card-header">
                <h3 className="font-semibold">Mitarbeiter-Kapazitäten</h3>
              </div>
              <div className="card-body">
                <div className="space-y-md">
                  {staff.map((member) => {
                    const colors = getEmployeeColor(mockEmployees.find(e => e.id === member.id)?.position || 'Mitarbeiter', member.id)
                    const utilization = (member.assignedClientHoursPerWeek / member.contractHoursPerWeek) * 100
                    const availableHours = member.contractHoursPerWeek * (1 - member.absenceRate)
                    const workload = (member.assignedClientHoursPerWeek / availableHours) * 100

                    return (
                      <div key={member.id} className="flex items-center gap-md p-3 rounded-lg border border-border-color">
                        <div
                          className="w-12 h-12 rounded-full flex items-center justify-center text-white font-bold"
                          style={{ backgroundColor: colors.primary }}
                        >
                          {member.name.split(' ').map(n => n[0]).join('')}
                        </div>

                        <div className="flex-1">
                          <div className="flex items-center justify-between mb-2">
                            <div>
                              <h4 className="font-medium">{member.name}</h4>
                              <p className="text-sm text-muted">
                                {member.assignedClientHoursPerWeek}h / {member.contractHoursPerWeek}h
                                ({member.absenceRate > 0.1 ? '⚠️ ' : ''}{(member.absenceRate * 100).toFixed(1)}% Ausfall)
                              </p>
                            </div>
                            <div className="text-right">
                              <div className={`font-bold ${
                                utilization > 90 ? 'text-red-600' :
                                utilization > 75 ? 'text-orange-600' :
                                utilization > 60 ? 'text-green-600' : 'text-blue-600'
                              }`}>
                                {utilization.toFixed(1)}%
                              </div>
                              <div className="text-xs text-muted">Auslastung</div>
                            </div>
                          </div>

                          <div className="w-full bg-gray-200 rounded-full h-2">
                            <div
                              className={`h-2 rounded-full transition-all ${getCapacityBarColor(utilization)}`}
                              style={{ width: `${Math.min(utilization, 100)}%` }}
                            />
                          </div>

                          {workload > 110 && (
                            <div className="mt-1 text-xs text-red-600 flex items-center gap-1">
                              <AlertTriangle size={12} />
                              Überstunden-Risiko: {workload.toFixed(1)}% verfügbare Zeit
                            </div>
                          )}
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            </div>
          </div>
        )}

        {viewMode === 'detailed' && (
          <div className="p-md">
            <CapacityCards
              team={team}
              substitution={substitution}
              preset={preset}
              weeklyClientHours={weeklyClientHours}
              staff={staff}
            />
          </div>
        )}

        {viewMode === 'analytics' && (
          <div className="p-md">
            <div className="text-center py-20 text-muted">
              <BarChart3 size={48} />
              <p className="mt-md">Analytik-Ansicht wird implementiert...</p>
              <p className="text-sm">Hier werden detaillierte Auswertungen und Trends angezeigt</p>
            </div>
          </div>
        )}
      </div>

      {/* Advanced Configuration Panel */}
      {showAdvanced && (
        <div className="card-footer border-t">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-md">
            <div className="form-group">
              <label className="form-label">Wöchentliche Klientenstunden</label>
              <input
                type="number"
                className="form-input"
                value={weeklyClientHours}
                onChange={(e) => setWeeklyClientHours(Number(e.target.value))}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Abwesender Mitarbeiter</label>
              <select
                className="form-select"
                value={absentEmployeeId}
                onChange={(e) => setAbsentEmployeeId(e.target.value)}
              >
                <option value="">Auswählen...</option>
                {staff.map(member => (
                  <option key={member.id} value={member.id}>{member.name}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Vertreter 1</label>
              <select
                className="form-select"
                value={rep1Id}
                onChange={(e) => setRep1Id(e.target.value)}
              >
                <option value="">Auswählen...</option>
                {staff.filter(s => s.id !== absentEmployeeId).map(member => (
                  <option key={member.id} value={member.id}>{member.name}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Vertreter 2</label>
              <select
                className="form-select"
                value={rep2Id}
                onChange={(e) => setRep2Id(e.target.value)}
              >
                <option value="">Auswählen...</option>
                {staff.filter(s => s.id !== absentEmployeeId && s.id !== rep1Id).map(member => (
                  <option key={member.id} value={member.id}>{member.name}</option>
                ))}
              </select>
            </div>
          </div>
        </div>
      )}

      {/* Footer Controls */}
      <div className="card-footer flex items-center justify-between">
        <button
          onClick={() => setShowAdvanced(!showAdvanced)}
          className="btn btn-secondary flex items-center gap-sm"
        >
          <Settings size={16} />
          {showAdvanced ? 'Erweitert ausblenden' : 'Erweiterte Einstellungen'}
        </button>

        <div className="flex items-center gap-sm">
          <button onClick={() => analyzeCapacityIssues()} className="btn btn-secondary">
            <RefreshCw size={16} />
            Aktualisieren
          </button>

          <button className="btn btn-primary">
            <Download size={16} />
            Export
          </button>
        </div>
      </div>
    </div>
  )
}