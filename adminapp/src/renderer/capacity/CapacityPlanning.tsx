import React, { useState, useMemo, useEffect } from 'react'
import { Calculator, Settings, Users, TrendingUp } from 'lucide-react'
import { computeTeam, distributeSubstitution, BERLIN_DEFAULT, type Staff, type BerlinPreset } from './calc'
import { CapacityCards } from './Cards'
import { mockEmployees } from '../utils/mockData'

export default function CapacityPlanning() {
  // Konfigurierbare Parameter
  const [preset, setPreset] = useState<BerlinPreset>(BERLIN_DEFAULT)
  const [weeklyClientHours, setWeeklyClientHours] = useState(52)
  const [showAdvanced, setShowAdvanced] = useState(false)

  // Vertretung
  const [absentEmployeeId, setAbsentEmployeeId] = useState('')
  const [absentWeeklyHours, setAbsentWeeklyHours] = useState(12)
  const [rep1Id, setRep1Id] = useState('')
  const [rep2Id, setRep2Id] = useState('')

  // Mock-Daten verwenden (später aus echten Mitarbeiterdaten)
  const [staff, setStaff] = useState<Staff[]>([])

  useEffect(() => {
    // Konvertiere Mock-Mitarbeiter zu Staff-Format
    const mockStaff: Staff[] = mockEmployees.map(emp => ({
      id: emp.id,
      name: `${emp.firstName} ${emp.lastName}`,
      contractHoursPerWeek: emp.weeklyHours,
      absenceRate: 0.08, // 8% durchschnittliche Abwesenheit
      assignedClientHoursPerWeek: Math.round(emp.weeklyHours * 0.6) // 60% der Arbeitszeit für Klienten
    }))
    setStaff(mockStaff)

    // Setze Default-Vertreter
    if (mockStaff.length >= 2) {
      setRep1Id(mockStaff[1].id)
      setRep2Id(mockStaff[2]?.id || mockStaff[0].id)
      setAbsentEmployeeId(mockStaff[0].id)
    }
  }, [])

  // Berechnungen
  const team = useMemo(() => {
    return computeTeam({ staff, weeklyClientHours, preset })
  }, [staff, weeklyClientHours, preset])

  const substitution = useMemo(() => {
    if (!absentEmployeeId || !rep1Id || !rep2Id) return undefined

    const absentMonthly = absentWeeklyHours * preset.weeklyToMonthlyFactor
    return distributeSubstitution(team.members, {
      absentMonthlyHours: absentMonthly,
      rep1Id,
      rep2Id
    })
  }, [team.members, absentEmployeeId, absentWeeklyHours, rep1Id, rep2Id, preset.weeklyToMonthlyFactor])

  const handlePresetChange = (field: keyof BerlinPreset, value: number) => {
    setPreset(prev => ({
      ...prev,
      [field]: value
    }))
  }

  const handleStaffChange = (staffId: string, field: keyof Staff, value: number) => {
    setStaff(prev => prev.map(s =>
      s.id === staffId
        ? { ...s, [field]: value }
        : s
    ))
  }

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="card-header">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-md">
            <Calculator size={24} />
            <div>
              <h1 className="text-xl font-bold">Kapazitätsplanung</h1>
              <p className="text-muted">Berlin-Spezifik: FLS inkl. QS-Anteile</p>
            </div>
          </div>
          <button
            className="btn btn-secondary"
            onClick={() => setShowAdvanced(!showAdvanced)}
          >
            <Settings size={16} />
            {showAdvanced ? 'Basis' : 'Erweitert'}
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-auto">
        <div className="p-md space-y-lg">
          {/* Parameter-Einstellungen */}
          <div className="card">
            <div className="card-header">
              <h2 className="font-bold flex items-center gap-sm">
                <Settings size={20} />
                Parameter
              </h2>
            </div>
            <div className="card-body">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-md">
                {/* Wochen-Monat-Faktor */}
                <div className="form-group">
                  <label className="form-label">
                    Wochen→Monat Faktor
                    <span className="text-xs text-muted block">Standard: 4,33 (52/12)</span>
                  </label>
                  <input
                    type="number"
                    className="form-input"
                    value={preset.weeklyToMonthlyFactor}
                    onChange={(e) => handlePresetChange('weeklyToMonthlyFactor', parseFloat(e.target.value) || 4.33)}
                    step="0.01"
                    min="4.0"
                    max="5.0"
                  />
                </div>

                {/* Direktanteil */}
                <div className="form-group">
                  <label className="form-label">
                    Direktanteil (%)
                    <span className="text-xs text-muted block">Planbare Klientenstunden</span>
                  </label>
                  <input
                    type="number"
                    className="form-input"
                    value={Math.round(preset.planningDirectShare * 100)}
                    onChange={(e) => handlePresetChange('planningDirectShare', (parseFloat(e.target.value) || 75) / 100)}
                    min="50"
                    max="100"
                  />
                </div>

                {/* Betreuungsschlüssel */}
                <div className="form-group">
                  <label className="form-label">
                    Klientenstunden/Woche
                    <span className="text-xs text-muted block">Gesamtbedarf Team</span>
                  </label>
                  <input
                    type="number"
                    className="form-input"
                    value={weeklyClientHours}
                    onChange={(e) => setWeeklyClientHours(parseFloat(e.target.value) || 0)}
                    min="0"
                  />
                </div>

                {/* Ampelgrenzen */}
                {showAdvanced && (
                  <div className="form-group">
                    <label className="form-label">
                      Auslastungsgrenze (%)
                      <span className="text-xs text-muted block">Grün bis / Gelb bis</span>
                    </label>
                    <div className="flex gap-xs">
                      <input
                        type="number"
                        className="form-input"
                        value={Math.round(preset.bands.green * 100)}
                        onChange={(e) => handlePresetChange('bands', {
                          ...preset.bands,
                          green: (parseFloat(e.target.value) || 85) / 100
                        })}
                        min="50"
                        max="100"
                        placeholder="85"
                      />
                      <input
                        type="number"
                        className="form-input"
                        value={Math.round(preset.bands.yellow * 100)}
                        onChange={(e) => handlePresetChange('bands', {
                          ...preset.bands,
                          yellow: (parseFloat(e.target.value) || 100) / 100
                        })}
                        min="80"
                        max="120"
                        placeholder="100"
                      />
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Vertretungsplanung */}
          <div className="card">
            <div className="card-header">
              <h2 className="font-bold flex items-center gap-sm">
                <Users size={20} />
                Vertretungsplanung
              </h2>
            </div>
            <div className="card-body">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-md">
                <div className="form-group">
                  <label className="form-label">Ausfallende Person</label>
                  <select
                    className="form-select"
                    value={absentEmployeeId}
                    onChange={(e) => setAbsentEmployeeId(e.target.value)}
                  >
                    <option value="">Keine Auswahl</option>
                    {staff.map(s => (
                      <option key={s.id} value={s.id}>{s.name}</option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Ausfall (h/Woche)</label>
                  <input
                    type="number"
                    className="form-input"
                    value={absentWeeklyHours}
                    onChange={(e) => setAbsentWeeklyHours(parseFloat(e.target.value) || 0)}
                    min="0"
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Vertreter 1</label>
                  <select
                    className="form-select"
                    value={rep1Id}
                    onChange={(e) => setRep1Id(e.target.value)}
                  >
                    <option value="">Keine Auswahl</option>
                    {staff.filter(s => s.id !== absentEmployeeId).map(s => (
                      <option key={s.id} value={s.id}>{s.name}</option>
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
                    <option value="">Keine Auswahl</option>
                    {staff.filter(s => s.id !== absentEmployeeId && s.id !== rep1Id).map(s => (
                      <option key={s.id} value={s.id}>{s.name}</option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          </div>

          {/* Mitarbeiter-Anpassungen */}
          {showAdvanced && (
            <div className="card">
              <div className="card-header">
                <h2 className="font-bold flex items-center gap-sm">
                  <TrendingUp size={20} />
                  Mitarbeiter-Anpassungen
                </h2>
              </div>
              <div className="card-body">
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left p-sm">Name</th>
                        <th className="text-center p-sm">Vertragsstunden/Woche</th>
                        <th className="text-center p-sm">Abwesenheitsrate (%)</th>
                        <th className="text-center p-sm">Zugewiesene Klientenstunden/Woche</th>
                      </tr>
                    </thead>
                    <tbody>
                      {staff.map(member => (
                        <tr key={member.id} className="border-b">
                          <td className="p-sm font-medium">{member.name}</td>
                          <td className="p-sm">
                            <input
                              type="number"
                              className="form-input text-center"
                              style={{ width: '80px' }}
                              value={member.contractHoursPerWeek}
                              onChange={(e) => handleStaffChange(member.id, 'contractHoursPerWeek', parseFloat(e.target.value) || 0)}
                              min="0"
                              max="40"
                            />
                          </td>
                          <td className="p-sm">
                            <input
                              type="number"
                              className="form-input text-center"
                              style={{ width: '80px' }}
                              value={Math.round(member.absenceRate * 100)}
                              onChange={(e) => handleStaffChange(member.id, 'absenceRate', (parseFloat(e.target.value) || 0) / 100)}
                              min="0"
                              max="50"
                            />
                          </td>
                          <td className="p-sm">
                            <input
                              type="number"
                              className="form-input text-center"
                              style={{ width: '80px' }}
                              value={member.assignedClientHoursPerWeek || 0}
                              onChange={(e) => handleStaffChange(member.id, 'assignedClientHoursPerWeek', parseFloat(e.target.value) || 0)}
                              min="0"
                            />
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* Ergebnisse */}
          <CapacityCards team={team} subst={substitution} />
        </div>
      </div>
    </div>
  )
}