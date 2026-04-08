import React from 'react'
import type { TeamCalc, SubstitutionResult } from './calc'

interface CapacityCardsProps {
  team: TeamCalc
  subst?: SubstitutionResult
}

export function CapacityCards({ team, subst }: CapacityCardsProps) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-md">
      <Card title={`Teamstatus (Berlin-Preset)`}>
        <div className="space-y-sm">
          <div className="grid grid-cols-2 gap-sm text-sm">
            <div>
              <span className="text-muted">Faktor:</span>
              <span className="font-medium ml-xs">{team.preset.weeklyToMonthlyFactor.toFixed(2)}</span>
            </div>
            <div>
              <span className="text-muted">Direktanteil:</span>
              <span className="font-medium ml-xs">{(team.preset.planningDirectShare*100).toFixed(0)}%</span>
            </div>
          </div>

          <div className="border-t pt-sm">
            <div className="grid grid-cols-2 gap-sm">
              <div>
                <div className="text-sm text-muted">Bedarf (Monat)</div>
                <div className="text-lg font-bold text-primary">{team.monthlyTeamDemand.toFixed(1)} h</div>
              </div>
              <div>
                <div className="text-sm text-muted">Kapazität (Monat)</div>
                <div className="text-lg font-bold text-success">{team.teamCapacity.toFixed(1)} h</div>
              </div>
            </div>
          </div>

          <div>
            <div className="text-sm text-muted mb-xs">Auslastung</div>
            <Progress value={Math.min(1, team.utilization)} color={team.utilizationColor}/>
            <div className="flex justify-between items-center mt-xs">
              <span className="text-lg font-bold">{(team.utilization*100).toFixed(1)}%</span>
              <span className={`badge ${
                team.utilizationColor === 'green' ? 'badge-success' :
                team.utilizationColor === 'yellow' ? 'badge-warning' : 'badge-danger'
              }`}>
                {team.utilizationColor === 'green' ? 'OK' :
                 team.utilizationColor === 'yellow' ? 'Eng' : 'Kritisch'}
              </span>
            </div>
          </div>

          {team.overtimeNeeded > 0 && (
            <div className="p-sm bg-danger rounded text-white">
              <div className="text-sm">Überstundenbedarf</div>
              <div className="text-lg font-bold">{team.overtimeNeeded.toFixed(1)} h</div>
            </div>
          )}
        </div>
      </Card>

      {subst && (
        <Card title="Vertretung (Krank/Urlaub)">
          <div className="space-y-sm">
            <div className="grid grid-cols-2 gap-sm">
              <div>
                <div className="text-sm text-muted">Abgedeckt</div>
                <div className="text-lg font-bold text-success">{subst.coveredHours.toFixed(1)} h</div>
              </div>
              <div>
                <div className="text-sm text-muted">Überlauf</div>
                <div className="text-lg font-bold text-danger">{subst.overflowHours.toFixed(1)} h</div>
              </div>
            </div>

            {Object.keys(subst.assignedTo).length > 0 && (
              <div>
                <div className="text-sm text-muted mb-xs">Verteilung</div>
                <div className="space-y-xs">
                  {Object.entries(subst.assignedTo).map(([id, hours]) => (
                    <div key={id} className="flex justify-between items-center p-xs bg-secondary rounded">
                      <span className="text-sm">{id}</span>
                      <span className="font-medium">+{hours.toFixed(1)} h</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </Card>
      )}

      <Card title="Mitarbeiter Details" className="lg:col-span-2">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b">
                <th className="text-left p-xs">Name</th>
                <th className="text-right p-xs">Vertrag</th>
                <th className="text-right p-xs">Anwesend</th>
                <th className="text-right p-xs">Direkt</th>
                <th className="text-right p-xs">Zugewiesen</th>
                <th className="text-right p-xs">Auslastung</th>
                <th className="text-right p-xs">Rest</th>
              </tr>
            </thead>
            <tbody>
              {team.members.map(member => (
                <tr key={member.id} className="border-b">
                  <td className="p-xs font-medium">{member.name}</td>
                  <td className="p-xs text-right">{member.monthlyContract.toFixed(1)}h</td>
                  <td className="p-xs text-right">{member.monthlyPresence.toFixed(1)}h</td>
                  <td className="p-xs text-right">{member.monthlyDirectCapacity.toFixed(1)}h</td>
                  <td className="p-xs text-right">{member.monthlyAssignedDemand.toFixed(1)}h</td>
                  <td className="p-xs text-right">
                    <span className={`font-medium ${
                      member.individualUtilization > 1 ? 'text-danger' :
                      member.individualUtilization > 0.9 ? 'text-warning' : 'text-success'
                    }`}>
                      {(member.individualUtilization * 100).toFixed(1)}%
                    </span>
                  </td>
                  <td className="p-xs text-right text-muted">{member.restCapacity.toFixed(1)}h</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      <Card title="Hinweise" className="lg:col-span-2">
        <Hints utilization={team.utilization} membersOver95={team.members.filter(m=>m.individualUtilization>0.95).length} />
      </Card>
    </div>
  )
}

interface CardProps {
  title: string
  children: React.ReactNode
  className?: string
}

function Card({ title, children, className = '' }: CardProps) {
  return (
    <div className={`card ${className}`}>
      <div className="card-header">
        <h3 className="font-bold">{title}</h3>
      </div>
      <div className="card-body">
        {children}
      </div>
    </div>
  )
}

interface ProgressProps {
  value: number
  color: 'green' | 'yellow' | 'red'
}

function Progress({ value, color }: ProgressProps) {
  const colorClasses = {
    green: 'bg-success',
    yellow: 'bg-warning',
    red: 'bg-danger'
  }

  return (
    <div className="w-full bg-secondary rounded-full h-2">
      <div
        className={`h-2 rounded-full transition-all duration-300 ${colorClasses[color]}`}
        style={{ width: `${Math.max(0, Math.min(100, value * 100))}%` }}
      />
    </div>
  )
}

interface HintsProps {
  utilization: number
  membersOver95: number
}

function Hints({ utilization, membersOver95 }: HintsProps) {
  const items: string[] = []

  if (utilization > 1.0) {
    items.push('🔴 Kritisch: Bedarf über Kapazität. Überstunden oder Leistungsreduktion nötig.')
  } else if (utilization > 0.9) {
    items.push('🟡 Eng: Kaum Puffer für Ausfälle. Vertretungsplan prüfen.')
  } else {
    items.push('🟢 OK: Ausreichend Puffer vorhanden.')
  }

  if (membersOver95 > 0) {
    items.push(`⚠️ ${membersOver95} Mitarbeitende sind über 95% verplant.`)
  }

  items.push('ℹ️ Berlin: FLS = 60 Minuten; QS‑Anteile sind in der FLS enthalten (Abrechnung).')

  return (
    <div className="space-y-xs">
      {items.map((item, index) => (
        <div key={index} className="text-sm p-xs rounded bg-tertiary">
          {item}
        </div>
      ))}
    </div>
  )
}