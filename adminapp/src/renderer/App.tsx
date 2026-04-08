import React, { useState, useEffect } from 'react'
import { Users, Calendar, Briefcase, Settings, Database, Shield, Calculator, Upload, User } from 'lucide-react'
import EmployeeManagement from './components/EmployeeManagement'
import ClientManagement from './components/ClientManagement'
import ProfessionalShiftPlanning from './components/ProfessionalShiftPlanning'
import VacationManagement from './components/VacationManagement'
import ProfessionalCapacityPlanning from './capacity/ProfessionalCapacityPlanning'
import FlutterImport from './components/FlutterImport'
import SettingsPage from './components/SettingsPage'
import SetupWizard from './components/SetupWizard'
import { AppConfig } from '../types'

declare global {
  interface Window {
    electronAPI: typeof import('../preload').ElectronAPI
    versions: {
      node(): string
      chrome(): string
      electron(): string
      app(): string
    }
    _devMode?: boolean
    _importedData?: {
      employees: import('../types').Employee[]
      clients: import('../types').Client[]
      shifts: import('../types').Shift[]
      vacationRequests: import('../types').VacationRequest[]
      originalBackup: import('../types/flutter').FlutterBackupData
    }
  }
}

type TabKey = 'employees' | 'clients' | 'shifts' | 'vacation' | 'capacity' | 'import' | 'settings'

interface Tab {
  key: TabKey
  label: string
  icon: React.ComponentType<{ size?: number }>
  component: React.ComponentType
}

const tabs: Tab[] = [
  {
    key: 'employees',
    label: 'Mitarbeiter',
    icon: Users,
    component: EmployeeManagement
  },
  {
    key: 'clients',
    label: 'Klienten',
    icon: User,
    component: ClientManagement
  },
  {
    key: 'shifts',
    label: 'Dienstplanung',
    icon: Calendar,
    component: ProfessionalShiftPlanning
  },
  {
    key: 'vacation',
    label: 'Urlaub',
    icon: Briefcase,
    component: VacationManagement
  },
  {
    key: 'capacity',
    label: 'Kapazität',
    icon: Calculator,
    component: ProfessionalCapacityPlanning
  },
  {
    key: 'import',
    label: 'Import',
    icon: Upload,
    component: FlutterImport
  },
  {
    key: 'settings',
    label: 'Einstellungen',
    icon: Settings,
    component: SettingsPage
  }
]

export default function App() {
  const [activeTab, setActiveTab] = useState<TabKey>('employees')
  const [isConfigured, setIsConfigured] = useState<boolean | null>(null)
  const [config, setConfig] = useState<AppConfig | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [devMode, setDevMode] = useState(false)

  useEffect(() => {
    // Check if we're in development mode
    const isDev = process.env.NODE_ENV === 'development'
    if (isDev) {
      console.log('🔧 Development Mode: Press Ctrl+D to toggle dev mode')

      // Start in dev mode by default in development
      setDevMode(true)
      window._devMode = true
      setIsConfigured(true)
      setIsLoading(false)

      // Listen for keyboard shortcuts in dev mode
      const handleKeyDown = (e: KeyboardEvent) => {
        if (e.ctrlKey && e.key === 'd') {
          e.preventDefault()
          setDevMode(prev => {
            const newMode = !prev
            console.log(`🔧 Dev Mode ${newMode ? 'ON' : 'OFF'} - Setup wizard ${newMode ? 'bypassed' : 'active'}`)
            // Store dev mode state globally so components can access it
            window._devMode = newMode
            setIsConfigured(newMode)
            return newMode
          })
        }
        if (e.ctrlKey && e.key === 's') {
          e.preventDefault()
          console.log('🔧 Showing setup wizard for testing')
          setIsConfigured(false)
          setDevMode(false)
          window._devMode = false
        }
      }

      window.addEventListener('keydown', handleKeyDown)
      return () => window.removeEventListener('keydown', handleKeyDown)
    } else {
      checkConfiguration()
    }
  }, [])

  async function checkConfiguration() {
    try {
      setIsLoading(true)

      // Get current configuration
      const configResponse = await window.electronAPI.config.get()

      if (configResponse.success && configResponse.data) {
        setConfig(configResponse.data)

        // Test connection to see if we're fully configured
        const connectionResponse = await window.electronAPI.auth.testConnection()
        setIsConfigured(connectionResponse.success && connectionResponse.data?.connected)
      } else {
        setIsConfigured(false)
      }
    } catch (error) {
      console.error('Failed to check configuration:', error)
      setIsConfigured(false)
    } finally {
      setIsLoading(false)
    }
  }

  function handleSetupComplete() {
    setIsConfigured(true)
    checkConfiguration()
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="flex flex-col items-center gap-md">
          <div className="spinner" style={{ width: '40px', height: '40px' }}></div>
          <p className="text-muted">Anwendung wird initialisiert...</p>
        </div>
      </div>
    )
  }

  if (isConfigured === false && !devMode) {
    return <SetupWizard onComplete={handleSetupComplete} />
  }

  const ActiveComponent = tabs.find(tab => tab.key === activeTab)?.component || EmployeeManagement

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <header className="card-header flex items-center justify-between">
        <div className="flex items-center gap-md">
          <Shield size={24} className="text-primary" />
          <div>
            <h1 className="text-xl font-bold">Eingliederungshilfe Admin</h1>
            {config?.companyName && (
              <p className="text-sm text-muted">{config.companyName}</p>
            )}
          </div>
        </div>

        <div className="flex items-center gap-sm">
          {devMode ? (
            <div className="flex items-center gap-xs">
              <div className="badge badge-warning">Dev Mode</div>
              <span className="text-xs text-muted">Ctrl+S für Setup</span>
            </div>
          ) : (
            <>
              <div className="flex items-center gap-xs text-sm text-muted">
                <Database size={16} />
                <span>HiDrive verbunden</span>
              </div>
              <div className="badge badge-success">Online</div>
            </>
          )}
        </div>
      </header>

      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar Navigation */}
        <nav className="card-body" style={{ width: '240px', borderRight: '1px solid var(--border-color)' }}>
          <div className="flex flex-col gap-xs">
            {tabs.map((tab) => {
              const Icon = tab.icon
              const isActive = activeTab === tab.key

              return (
                <button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key)}
                  className={`
                    flex items-center gap-sm p-sm rounded
                    transition-colors text-left w-full
                    ${isActive
                      ? 'bg-primary text-white'
                      : 'hover:bg-secondary text-primary hover:text-white'
                    }
                  `}
                >
                  <Icon size={20} />
                  <span className="font-medium">{tab.label}</span>
                </button>
              )
            })}
          </div>

          {/* Footer info */}
          <div className="mt-auto pt-lg border-t border-border-color">
            <div className="text-xs text-muted">
              <p>Version {window.versions?.app()}</p>
              <p>Electron {window.versions?.electron()}</p>
            </div>
          </div>
        </nav>

        {/* Main Content */}
        <main className="flex-1 overflow-auto">
          <div className="h-full">
            <ActiveComponent />
          </div>
        </main>
      </div>
    </div>
  )
}