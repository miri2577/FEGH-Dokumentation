import React, { useState, useRef } from 'react'
import { Upload, Download, FileText, AlertCircle, CheckCircle, Database, RefreshCw } from 'lucide-react'
import { importFlutterBackup, validateFlutterBackup } from '../../utils/flutterImport'
import type { FlutterBackupData, ImportResult, ImportStats } from '../../types/flutter'

export default function FlutterImport() {
  const [importResult, setImportResult] = useState<ImportResult | null>(null)
  const [isImporting, setIsImporting] = useState(false)
  const [dragOver, setDragOver] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileSelect = async (file: File) => {
    setIsImporting(true)
    setImportResult(null)

    try {
      const text = await file.text()
      const data = JSON.parse(text)

      if (!validateFlutterBackup(data)) {
        setImportResult({
          success: false,
          stats: {
            clients: 0,
            appointments: 0,
            arbeitszeiten: 0,
            totalTimeHours: 0,
            errors: ['Ungültiges Flutter-Backup-Format']
          },
          error: 'Die Datei entspricht nicht dem erwarteten Flutter-Backup-Format'
        })
        return
      }

      const result = await importFlutterBackup(data as FlutterBackupData)
      setImportResult(result)

      if (result.success) {
        // Import erfolgreich - Daten sind jetzt in window._importedData verfügbar
        console.log('🎉 Import completed successfully! Switch to Clients tab to see imported data.')
      }
    } catch (error) {
      setImportResult({
        success: false,
        stats: {
          clients: 0,
          appointments: 0,
          arbeitszeiten: 0,
          totalTimeHours: 0,
          errors: [error instanceof Error ? error.message : 'Unbekannter Fehler']
        },
        error: 'Fehler beim Verarbeiten der Datei'
      })
    } finally {
      setIsImporting(false)
    }
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setDragOver(false)

    const files = Array.from(e.dataTransfer.files)
    const jsonFile = files.find(file => file.name.endsWith('.json'))

    if (jsonFile) {
      handleFileSelect(jsonFile)
    }
  }

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      handleFileSelect(file)
    }
  }

  const createSampleBackup = () => {
    const sampleBackup: FlutterBackupData = {
      metadata: {
        backupId: Date.now().toString(),
        createdAt: new Date().toISOString(),
        deviceName: 'Electron Dev Import',
        appVersion: '2.1.0',
        dataVersion: '1.0.0'
      },
      version: '2.1.0',
      emailTargets: ['admin@beispiel.de'],
      settings: {
        theme: 'light',
        notifications: true,
        autoBackup: false,
        companyName: 'Beispiel Eingliederungshilfe gGmbH'
      },
      clients: [
        {
          id: 'client-1',
          name: 'Max Mustermann',
          vorname: 'Max',
          nachname: 'Mustermann',
          berufsgruppe: 'Sozialarbeiter',
          eingliederung: 'SGB IX',
          createdAt: new Date().toISOString(),
          geburtsdatum: '1985-05-15',
          betreuungSeit: '2024-01-01',
          kostenuebernahme: 'Bezirk Mitte',
          kostenuebernahmeVon: '2024-01-01',
          kostenuebernahmeBis: '2024-12-31',
          fachleistungsstunden: 20,
          fachleistungsIntervall: 'monatlich',
          hilfeTyp: 'eingliederungshilfe',
          icfBereiche: ['Lernen und Wissensanwendung', 'Allgemeine Aufgaben und Anforderungen'],
          verbrauchteStunden: 12
        },
        {
          id: 'client-2',
          name: 'Anna Schmidt',
          vorname: 'Anna',
          nachname: 'Schmidt',
          berufsgruppe: 'Heilerzieher',
          eingliederung: 'SGB VIII',
          createdAt: new Date().toISOString(),
          geburtsdatum: '1990-09-22',
          betreuungSeit: '2024-02-01',
          kostenuebernahme: 'Jugendamt Charlottenburg',
          kostenuebernahmeVon: '2024-02-01',
          kostenuebernahmeBis: '2025-01-31',
          fachleistungsstunden: 15,
          fachleistungsIntervall: 'monatlich',
          hilfeTyp: 'familienhilfe',
          icfBereiche: ['Kommunikation', 'Interpersonelle Interaktionen'],
          verbrauchteStunden: 8
        }
      ],
      appointments: [
        {
          id: 'appointment-1',
          clientId: 'client-1',
          clientName: 'Max Mustermann',
          date: '2024-09-17',
          startTime: '2024-09-17T10:00:00.000Z',
          endTime: '2024-09-17T11:30:00.000Z',
          notes: 'Beratungsgespräch zu Arbeitsplatzintegration',
          recordedText: 'Herr Mustermann zeigte große Motivation bei der Suche nach einem geeigneten Arbeitsplatz.',
          berufsgruppe: 'Sozialarbeiter',
          eingliederung: 'SGB IX',
          createdAt: new Date().toISOString(),
          icfBereiche: ['Arbeit und Beschäftigung'],
          fachleistungsstunden: 1.5,
          familienhilfeKategorien: []
        },
        {
          id: 'appointment-2',
          clientId: 'client-2',
          clientName: 'Anna Schmidt',
          date: '2024-09-16',
          startTime: '2024-09-16T14:00:00.000Z',
          endTime: '2024-09-16T15:00:00.000Z',
          notes: 'Hausbesuch und Familienberatung',
          recordedText: 'Familientreffen verlief positiv. Kommunikation zwischen den Familienmitgliedern hat sich verbessert.',
          berufsgruppe: 'Heilerzieher',
          eingliederung: 'SGB VIII',
          createdAt: new Date().toISOString(),
          icfBereiche: ['Interpersonelle Interaktionen', 'Familienleben'],
          fachleistungsstunden: 1.0,
          familienhilfeKategorien: ['Familienberatung', 'Hausbesuch']
        }
      ],
      arbeitszeiten: [
        {
          id: 'arbeitszeit-1',
          datum: '2024-09-17',
          startzeit: '2024-09-17T08:00:00.000Z',
          endzeit: '2024-09-17T12:00:00.000Z',
          taetigkeit: 'Dokumentation und Verwaltung',
          notizen: 'Monatsabrechnung und Terminplanung',
          createdAt: new Date().toISOString(),
          typ: 'verwaltung'
        }
      ]
    }

    const blob = new Blob([JSON.stringify(sampleBackup, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'sample-flutter-backup.json'
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="card-header">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-md">
            <Database size={24} />
            <div>
              <h1 className="text-xl font-bold">Flutter-App Datenimport</h1>
              <p className="text-muted">Import von unverschlüsselten JSON-Backups der Flutter-App</p>
            </div>
          </div>
          <div className="flex gap-sm">
            <button
              className="btn btn-secondary"
              onClick={createSampleBackup}
            >
              <Download size={16} />
              Sample-Backup
            </button>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-auto p-md">
        <div className="max-w-4xl mx-auto space-y-lg">
          {/* Upload Area */}
          <div className="card">
            <div className="card-header">
              <h2 className="font-bold flex items-center gap-sm">
                <Upload size={20} />
                Backup-Datei importieren
              </h2>
            </div>
            <div className="card-body">
              <div
                className={`
                  border-2 border-dashed rounded-lg p-lg text-center transition-colors
                  ${dragOver ? 'border-primary bg-primary bg-opacity-5' : 'border-border-color'}
                  ${isImporting ? 'opacity-50 pointer-events-none' : 'cursor-pointer hover:border-primary'}
                `}
                onDrop={handleDrop}
                onDragOver={(e) => { e.preventDefault(); setDragOver(true) }}
                onDragLeave={() => setDragOver(false)}
                onClick={() => fileInputRef.current?.click()}
              >
                {isImporting ? (
                  <div className="flex flex-col items-center gap-sm">
                    <RefreshCw size={48} className="animate-spin text-primary" />
                    <p className="text-lg font-medium">Import läuft...</p>
                    <p className="text-muted">Daten werden verarbeitet und konvertiert</p>
                  </div>
                ) : (
                  <div className="flex flex-col items-center gap-sm">
                    <FileText size={48} className="text-muted" />
                    <p className="text-lg font-medium">Flutter-Backup hier ablegen oder klicken</p>
                    <p className="text-muted">Unterstützte Formate: .json (unverschlüsselt)</p>
                  </div>
                )}

                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".json"
                  onChange={handleFileInput}
                  className="hidden"
                />
              </div>

              <div className="mt-md p-sm bg-secondary rounded">
                <h3 className="font-medium mb-xs">Hinweise zum Import:</h3>
                <ul className="text-sm text-muted space-y-xs">
                  <li>• Nur unverschlüsselte JSON-Backups werden unterstützt</li>
                  <li>• Klienten werden als Klienten importiert (im Klienten-Tab)</li>
                  <li>• Zusätzlich als "Mitarbeiter" für Kapazitätsplanung</li>
                  <li>• Termine werden als echte Termine erfasst</li>
                  <li>• Zusätzlich als "Schichten" für Dienstplanung</li>
                  <li>• Sample-Urlaubsanträge werden automatisch generiert</li>
                  <li>• Der Import überschreibt die aktuellen Mock-Daten</li>
                </ul>
              </div>
            </div>
          </div>

          {/* Import Result */}
          {importResult && (
            <div className="card">
              <div className="card-header">
                <h2 className="font-bold flex items-center gap-sm">
                  {importResult.success ? (
                    <CheckCircle size={20} className="text-success" />
                  ) : (
                    <AlertCircle size={20} className="text-danger" />
                  )}
                  Import-Ergebnis
                </h2>
              </div>
              <div className="card-body">
                {importResult.success ? (
                  <div className="space-y-md">
                    <div className="p-md bg-success bg-opacity-10 border border-success rounded">
                      <p className="text-success font-medium">Import erfolgreich!</p>
                      <p className="text-sm text-muted mt-xs">
                        Die Daten wurden erfolgreich importiert und konvertiert.
                      </p>
                    </div>

                    <ImportStatsDisplay stats={importResult.stats} />
                  </div>
                ) : (
                  <div className="space-y-md">
                    <div className="p-md bg-danger bg-opacity-10 border border-danger rounded">
                      <p className="text-danger font-medium">Import fehlgeschlagen</p>
                      <p className="text-sm text-muted mt-xs">{importResult.error}</p>
                    </div>

                    {importResult.stats.errors.length > 0 && (
                      <div>
                        <h3 className="font-medium mb-sm">Fehlerdetails:</h3>
                        <div className="space-y-xs">
                          {importResult.stats.errors.map((error, index) => (
                            <div key={index} className="text-sm text-danger bg-danger bg-opacity-5 p-sm rounded">
                              {error}
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

interface ImportStatsDisplayProps {
  stats: ImportStats
}

function ImportStatsDisplay({ stats }: ImportStatsDisplayProps) {
  return (
    <div>
      <h3 className="font-medium mb-sm">Import-Statistiken:</h3>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-md">
        <div className="text-center p-md bg-secondary rounded">
          <div className="text-2xl font-bold text-primary">{stats.clients}</div>
          <div className="text-sm text-muted">Klienten</div>
        </div>
        <div className="text-center p-md bg-secondary rounded">
          <div className="text-2xl font-bold text-success">{stats.appointments}</div>
          <div className="text-sm text-muted">Termine</div>
        </div>
        <div className="text-center p-md bg-secondary rounded">
          <div className="text-2xl font-bold text-warning">{stats.arbeitszeiten}</div>
          <div className="text-sm text-muted">Arbeitszeiten</div>
        </div>
        <div className="text-center p-md bg-secondary rounded">
          <div className="text-2xl font-bold text-info">{Math.round(stats.totalTimeHours)}</div>
          <div className="text-sm text-muted">Gesamtstunden</div>
        </div>
      </div>

      {stats.errors.length > 0 && (
        <div className="mt-md">
          <h4 className="font-medium text-warning mb-sm">Warnungen:</h4>
          <div className="space-y-xs">
            {stats.errors.map((error, index) => (
              <div key={index} className="text-sm text-warning bg-warning bg-opacity-5 p-sm rounded">
                {error}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}