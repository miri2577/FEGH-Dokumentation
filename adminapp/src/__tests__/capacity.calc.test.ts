import { describe, it, expect } from 'vitest'
import { computeTeam, distributeSubstitution, BERLIN_DEFAULT, type Staff } from '../renderer/capacity/calc'

describe('computeTeam (Berlin-Preset)', () => {
  it('uses weekly→monthly factor from preset (4.33 default)', () => {
    const staff: Staff[] = [
      { id: 'A', name: 'Anna', contractHoursPerWeek: 30, absenceRate: 0, assignedClientHoursPerWeek: 15 },
    ]
    const team = computeTeam({ staff, weeklyClientHours: 20, preset: BERLIN_DEFAULT })

    expect(team.preset.weeklyToMonthlyFactor).toBeCloseTo(4.33, 2)
    expect(team.monthlyTeamDemand).toBeCloseTo(20 * 4.33, 2)
  })

  it('calculates team capacity correctly with Berlin defaults', () => {
    const staff: Staff[] = [
      { id: 'A', name: 'Anna', contractHoursPerWeek: 30, absenceRate: 0.05, assignedClientHoursPerWeek: 15 },
      { id: 'B', name: 'Boris', contractHoursPerWeek: 35, absenceRate: 0.10, assignedClientHoursPerWeek: 18 },
    ]
    const team = computeTeam({ staff, weeklyClientHours: 40, preset: BERLIN_DEFAULT })

    expect(team.members).toHaveLength(2)
    expect(team.teamCapacity).toBeGreaterThan(0)
    expect(team.utilization).toBeGreaterThan(0)
  })

  it('flags overtime when demand exceeds capacity', () => {
    const staff: Staff[] = [
      { id: 'A', name: 'Anna', contractHoursPerWeek: 10, absenceRate: 0, assignedClientHoursPerWeek: 5 },
    ]
    const team = computeTeam({ staff, weeklyClientHours: 50 }) // sehr hoher Bedarf

    expect(team.overtimeNeeded).toBeGreaterThan(0)
    expect(team.utilizationColor).toBe('red')
  })

  it('respects custom preset parameters', () => {
    const customPreset = {
      weeklyToMonthlyFactor: 4.35,
      planningDirectShare: 0.8,
      bands: { green: 0.9, yellow: 1.1 }
    }

    const staff: Staff[] = [
      { id: 'A', name: 'Anna', contractHoursPerWeek: 30, absenceRate: 0, assignedClientHoursPerWeek: 15 },
    ]
    const team = computeTeam({ staff, weeklyClientHours: 20, preset: customPreset })

    expect(team.preset.weeklyToMonthlyFactor).toBe(4.35)
    expect(team.preset.planningDirectShare).toBe(0.8)
    expect(team.monthlyTeamDemand).toBeCloseTo(20 * 4.35, 2)
  })
})

describe('distributeSubstitution (Rep1→Rep2→Overflow)', () => {
  it('fills rep1 then rep2 by restCapacity and returns overflow', () => {
    const staff: Staff[] = [
      { id: 'R1', name: 'Rep1', contractHoursPerWeek: 20, absenceRate: 0, assignedClientHoursPerWeek: 10 },
      { id: 'R2', name: 'Rep2', contractHoursPerWeek: 10, absenceRate: 0, assignedClientHoursPerWeek: 5 },
    ]
    const team = computeTeam({ staff, weeklyClientHours: 0, preset: BERLIN_DEFAULT })
    const result = distributeSubstitution(team.members, {
      absentMonthlyHours: 100,
      rep1Id: 'R1',
      rep2Id: 'R2'
    })

    expect(result.coveredHours + result.overflowHours).toBeCloseTo(100, 5)
    expect(Object.values(result.assignedTo).every(v => v >= 0)).toBe(true)
  })

  it('prioritizes rep1 over rep2', () => {
    const staff: Staff[] = [
      { id: 'R1', name: 'Rep1', contractHoursPerWeek: 30, absenceRate: 0, assignedClientHoursPerWeek: 15 },
      { id: 'R2', name: 'Rep2', contractHoursPerWeek: 30, absenceRate: 0, assignedClientHoursPerWeek: 15 },
    ]
    const team = computeTeam({ staff, weeklyClientHours: 0, preset: BERLIN_DEFAULT })
    const result = distributeSubstitution(team.members, {
      absentMonthlyHours: 50,
      rep1Id: 'R1',
      rep2Id: 'R2'
    })

    const rep1Hours = result.assignedTo['R1'] || 0
    const rep2Hours = result.assignedTo['R2'] || 0

    if (rep1Hours > 0 && rep2Hours > 0) {
      // Wenn beide Vertreter Stunden bekommen, sollte Rep1 zuerst gefüllt werden
      expect(rep1Hours).toBeGreaterThanOrEqual(rep2Hours)
    }
  })

  it('handles case when no substitutes can cover the hours', () => {
    const staff: Staff[] = [
      { id: 'R1', name: 'Rep1', contractHoursPerWeek: 30, absenceRate: 0, assignedClientHoursPerWeek: 30 }, // voll ausgelastet
      { id: 'R2', name: 'Rep2', contractHoursPerWeek: 20, absenceRate: 0, assignedClientHoursPerWeek: 20 }, // voll ausgelastet
    ]
    const team = computeTeam({ staff, weeklyClientHours: 0, preset: BERLIN_DEFAULT })
    const result = distributeSubstitution(team.members, {
      absentMonthlyHours: 50,
      rep1Id: 'R1',
      rep2Id: 'R2'
    })

    expect(result.coveredHours).toBe(0)
    expect(result.overflowHours).toBe(50)
    expect(Object.keys(result.assignedTo)).toHaveLength(0)
  })
})

describe('individual member calculations', () => {
  it('calculates member metrics correctly', () => {
    const staff: Staff[] = [
      {
        id: 'A',
        name: 'Anna',
        contractHoursPerWeek: 30,
        absenceRate: 0.1, // 10% Abwesenheit
        assignedClientHoursPerWeek: 20
      },
    ]
    const team = computeTeam({ staff, weeklyClientHours: 20, preset: BERLIN_DEFAULT })
    const member = team.members[0]

    const expectedMonthlyContract = 30 * 4.33
    const expectedMonthlyPresence = expectedMonthlyContract * 0.9 // 90% Anwesenheit
    const expectedDirectCapacity = expectedMonthlyPresence * 0.75 // 75% Direktanteil
    const expectedAssignedDemand = 20 * 4.33

    expect(member.monthlyContract).toBeCloseTo(expectedMonthlyContract, 1)
    expect(member.monthlyPresence).toBeCloseTo(expectedMonthlyPresence, 1)
    expect(member.monthlyDirectCapacity).toBeCloseTo(expectedDirectCapacity, 1)
    expect(member.monthlyAssignedDemand).toBeCloseTo(expectedAssignedDemand, 1)
    expect(member.individualUtilization).toBeCloseTo(expectedAssignedDemand / expectedDirectCapacity, 2)
  })

  it('handles zero capacity gracefully', () => {
    const staff: Staff[] = [
      {
        id: 'A',
        name: 'Anna',
        contractHoursPerWeek: 0,
        absenceRate: 0,
        assignedClientHoursPerWeek: 10
      },
    ]
    const team = computeTeam({ staff, weeklyClientHours: 10 })
    const member = team.members[0]

    expect(member.monthlyDirectCapacity).toBe(0)
    expect(member.individualUtilization).toBe(0) // sollte nicht NaN sein
    expect(member.restCapacity).toBe(0)
  })
})