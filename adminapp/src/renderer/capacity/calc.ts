// Rechenkern für Fachleistungsstunden / Vertretung (Renderer‑Kontext)
export type BerlinPreset = {
  weeklyToMonthlyFactor: number;   // z. B. 4.33 (Berlin‑üblich) oder 4.35
  planningDirectShare: number;     // interner Direktanteil für leistbare Stunden (z. B. 0.75)
  bands: { green: number; yellow: number }; // Ampelgrenzen
};

export const BERLIN_DEFAULT: BerlinPreset = {
  weeklyToMonthlyFactor: 4.33,      // 52 Wochen / 12 Monate
  planningDirectShare: 0.75,        // interner Puffer (Wege/Vor‑Nachbereitung)
  bands: { green: 0.85, yellow: 1.0 }
};

export type Staff = {
  id: string;
  name: string;
  contractHoursPerWeek: number;        // z. B. 30
  absenceRate: number;                 // 0..1 Anteil im Monat (Urlaub+Krank)
  directShareOverride?: number;        // optional: überschreibt Preset
  assignedClientHoursPerWeek?: number; // Summe Klientenstunden/Woche
};

export type TeamInput = {
  staff: Staff[];
  weeklyClientHours: number;          // Σ Klientenstunden/Woche (FLS‑Bedarf)
  preset?: BerlinPreset;              // optional; default BERLIN_DEFAULT
};

export type MemberCalc = {
  id: string;
  name: string;
  monthlyContract: number;      // h
  monthlyPresence: number;      // h (abzgl. Abwesenheit)
  monthlyDirectCapacity: number;// h (× Direktanteil)
  monthlyAssignedDemand: number;// h (zugewiesene Klienten)
  individualUtilization: number;// demand/capacity (0..∞)
  restCapacity: number;         // h
};

export type TeamCalc = {
  members: MemberCalc[];
  monthlyTeamDemand: number;
  teamCapacity: number;
  utilization: number;          // team demand / capacity
  overtimeNeeded: number;       // h (max(0, demand - capacity))
  utilizationColor: 'green'|'yellow'|'red';
  preset: BerlinPreset;
};

export function computeTeam(input: TeamInput): TeamCalc {
  const preset = input.preset ?? BERLIN_DEFAULT;
  const f = preset.weeklyToMonthlyFactor;

  const members: MemberCalc[] = input.staff.map(m => {
    const direct = m.directShareOverride ?? preset.planningDirectShare;
    const monthlyContract = m.contractHoursPerWeek * f;
    const monthlyPresence = monthlyContract * (1 - m.absenceRate);
    const monthlyDirectCapacity = monthlyPresence * direct;
    const monthlyAssignedDemand = (m.assignedClientHoursPerWeek ?? 0) * f;
    const individualUtilization = monthlyDirectCapacity > 0 ? (monthlyAssignedDemand / monthlyDirectCapacity) : 0;
    const restCapacity = Math.max(0, monthlyDirectCapacity - monthlyAssignedDemand);
    return { id: m.id, name: m.name, monthlyContract, monthlyPresence, monthlyDirectCapacity, monthlyAssignedDemand, individualUtilization, restCapacity };
  });

  const monthlyTeamDemand = input.weeklyClientHours * f; // FLS‑Bedarf/Monat
  const teamCapacity = members.reduce((a, m) => a + m.monthlyDirectCapacity, 0);
  const utilization = teamCapacity > 0 ? (monthlyTeamDemand / teamCapacity) : 0;
  const overtimeNeeded = Math.max(0, monthlyTeamDemand - teamCapacity);
  const color: TeamCalc['utilizationColor'] = utilization <= preset.bands.green ? 'green' : (utilization <= preset.bands.yellow ? 'yellow' : 'red');

  return { members, monthlyTeamDemand, teamCapacity, utilization, overtimeNeeded, utilizationColor: color, preset };
}

export type SubstitutionInput = {
  absentMonthlyHours: number; // Ausfall an Klientenstunden (Monat) einer Person
  rep1Id: string;             // Vertreter 1
  rep2Id: string;             // Vertreter 2
};

export type SubstitutionResult = {
  coveredHours: number;
  overflowHours: number; // nicht abdeckbar → Überstunden/Leistungsausfall
  assignedTo: Record<string, number>; // staffId -> zugeteilte Stunden (Monat)
};

export function distributeSubstitution(members: MemberCalc[], s: SubstitutionInput): SubstitutionResult {
  let remaining = s.absentMonthlyHours;
  const map: Record<string, number> = {};
  const byId = Object.fromEntries(members.map(m => [m.id, m]));

  function take(repId: string) {
    if (remaining <= 0) return;
    const m = byId[repId];
    if (!m) return;
    const r = m.restCapacity;
    if (r <= 0) return;
    const takeH = Math.min(remaining, r);
    map[repId] = (map[repId] ?? 0) + takeH;
    remaining -= takeH;
  }

  take(s.rep1Id);
  take(s.rep2Id);

  return { coveredHours: s.absentMonthlyHours - remaining, overflowHours: Math.max(0, remaining), assignedTo: map };
}