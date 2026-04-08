import React, { useState } from 'react'
import { Shield, Server, Key, CheckCircle, AlertCircle } from 'lucide-react'

interface SetupWizardProps {
  onComplete: () => void
}

interface SetupData {
  hidriveUrl: string
  username: string
  password: string
  companyName: string
}

export default function SetupWizard({ onComplete }: SetupWizardProps) {
  const [currentStep, setCurrentStep] = useState(1)
  const [setupData, setSetupData] = useState<SetupData>({
    hidriveUrl: 'https://webdav.hidrive.strato.com/',
    username: '',
    password: '',
    companyName: ''
  })
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [testResult, setTestResult] = useState<'success' | 'error' | null>(null)

  const steps = [
    {
      title: 'Willkommen',
      description: 'Einrichtung der Eingliederungshilfe Administration',
      icon: Shield
    },
    {
      title: 'HiDrive Konfiguration',
      description: 'Verbindung zu Ihrem HiDrive Business Account',
      icon: Server
    },
    {
      title: 'Verschlüsselung',
      description: 'Generierung der Verschlüsselungsschlüssel',
      icon: Key
    },
    {
      title: 'Abschluss',
      description: 'Setup erfolgreich abgeschlossen',
      icon: CheckCircle
    }
  ]

  async function testConnection() {
    if (!setupData.hidriveUrl || !setupData.username || !setupData.password) {
      setError('Bitte füllen Sie alle Felder aus')
      return false
    }

    setIsLoading(true)
    setError(null)
    setTestResult(null)

    try {
      const response = await window.electronAPI.auth.setup({
        hidriveUrl: setupData.hidriveUrl,
        username: setupData.username,
        password: setupData.password
      })

      if (response.success) {
        setTestResult('success')
        return true
      } else {
        setError(response.error || 'Verbindung fehlgeschlagen')
        setTestResult('error')
        return false
      }
    } catch (err) {
      setError('Unerwarteter Fehler bei der Verbindung')
      setTestResult('error')
      return false
    } finally {
      setIsLoading(false)
    }
  }

  async function completeSetup() {
    setIsLoading(true)
    setError(null)

    try {
      // Save company configuration
      await window.electronAPI.config.set({
        companyName: setupData.companyName,
        hidriveUrl: setupData.hidriveUrl,
        username: setupData.username
      })

      setCurrentStep(4)

      // Complete setup after a short delay
      setTimeout(() => {
        onComplete()
      }, 2000)

    } catch (err) {
      setError('Fehler beim Abschließen der Einrichtung')
    } finally {
      setIsLoading(false)
    }
  }

  function handleNext() {
    if (currentStep === 2) {
      testConnection().then(success => {
        if (success) {
          setCurrentStep(3)
        }
      })
    } else if (currentStep === 3) {
      completeSetup()
    } else {
      setCurrentStep(currentStep + 1)
    }
  }

  function handleBack() {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1)
      setError(null)
      setTestResult(null)
    }
  }

  const currentStepData = steps[currentStep - 1]
  const Icon = currentStepData.icon

  return (
    <div className="min-h-screen flex items-center justify-center p-md" style={{ backgroundColor: 'var(--background-secondary)' }}>
      <div className="card" style={{ width: '600px', maxWidth: '90vw' }}>
        {/* Progress Steps */}
        <div className="card-header">
          <div className="flex items-center justify-between mb-lg">
            {steps.map((step, index) => (
              <div key={index} className="flex items-center">
                <div className={`
                  flex items-center justify-center w-8 h-8 rounded-full text-sm font-bold
                  ${index + 1 <= currentStep
                    ? 'bg-primary text-white'
                    : 'bg-secondary text-muted'
                  }
                `}>
                  {index + 1}
                </div>
                {index < steps.length - 1 && (
                  <div className={`
                    w-16 h-1 mx-2
                    ${index + 1 < currentStep ? 'bg-primary' : 'bg-secondary'}
                  `} />
                )}
              </div>
            ))}
          </div>

          <div className="text-center">
            <Icon size={48} className="text-primary mx-auto mb-md" />
            <h1 className="text-xl font-bold mb-sm">{currentStepData.title}</h1>
            <p className="text-muted">{currentStepData.description}</p>
          </div>
        </div>

        <div className="card-body">
          {error && (
            <div className="alert alert-danger flex items-center gap-sm mb-md">
              <AlertCircle size={20} />
              {error}
            </div>
          )}

          {/* Step 1: Welcome */}
          {currentStep === 1 && (
            <div className="text-center">
              <p className="mb-md">
                Willkommen bei der Eingliederungshilfe Administration!
                Diese Anwendung hilft Ihnen bei der Verwaltung von Mitarbeitern,
                Dienstplänen und Urlaubsanträgen.
              </p>
              <div className="card" style={{ backgroundColor: 'var(--background-secondary)' }}>
                <div className="card-body">
                  <h3 className="font-bold mb-sm">Wichtige Hinweise:</h3>
                  <ul className="text-sm text-left space-y-1">
                    <li>• Alle Daten werden verschlüsselt in Ihrem HiDrive gespeichert</li>
                    <li>• Sie benötigen einen HiDrive Business Account</li>
                    <li>• Kein externer Server erforderlich</li>
                    <li>• DSGVO-konforme Datenhaltung in Deutschland</li>
                  </ul>
                </div>
              </div>
            </div>
          )}

          {/* Step 2: HiDrive Configuration */}
          {currentStep === 2 && (
            <div>
              <div className="form-group">
                <label className="form-label">HiDrive WebDAV URL</label>
                <input
                  type="url"
                  className="form-input"
                  value={setupData.hidriveUrl}
                  onChange={(e) => setSetupData({ ...setupData, hidriveUrl: e.target.value })}
                  placeholder="https://webdav.hidrive.strato.com/"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Benutzername</label>
                <input
                  type="text"
                  className="form-input"
                  value={setupData.username}
                  onChange={(e) => setSetupData({ ...setupData, username: e.target.value })}
                  placeholder="Ihr HiDrive Benutzername"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Passwort</label>
                <input
                  type="password"
                  className="form-input"
                  value={setupData.password}
                  onChange={(e) => setSetupData({ ...setupData, password: e.target.value })}
                  placeholder="Ihr HiDrive Passwort"
                />
              </div>

              {testResult === 'success' && (
                <div className="alert alert-success flex items-center gap-sm">
                  <CheckCircle size={20} />
                  Verbindung erfolgreich! HiDrive ist bereit.
                </div>
              )}
            </div>
          )}

          {/* Step 3: Encryption Setup */}
          {currentStep === 3 && (
            <div className="text-center">
              <div className="form-group">
                <label className="form-label">Firmenname (optional)</label>
                <input
                  type="text"
                  className="form-input"
                  value={setupData.companyName}
                  onChange={(e) => setSetupData({ ...setupData, companyName: e.target.value })}
                  placeholder="Name Ihrer Einrichtung"
                />
              </div>

              <div className="card" style={{ backgroundColor: 'var(--background-secondary)' }}>
                <div className="card-body">
                  <Key size={32} className="text-primary mx-auto mb-sm" />
                  <h3 className="font-bold mb-sm">Verschlüsselung wird eingerichtet</h3>
                  <p className="text-sm text-muted">
                    Ein Master-Verschlüsselungsschlüssel wird generiert und sicher in der
                    Systemkeychain gespeichert. Alle Ihre Daten werden vor dem Upload
                    verschlüsselt.
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Step 4: Completion */}
          {currentStep === 4 && (
            <div className="text-center">
              <CheckCircle size={64} className="text-success mx-auto mb-md" />
              <h2 className="font-bold mb-sm">Setup abgeschlossen!</h2>
              <p className="text-muted mb-md">
                Die Eingliederungshilfe Administration ist jetzt einsatzbereit.
                Sie werden in Kürze zur Hauptanwendung weitergeleitet.
              </p>
              <div className="spinner mx-auto"></div>
            </div>
          )}
        </div>

        {currentStep < 4 && (
          <div className="card-footer flex justify-between">
            <button
              className="btn btn-secondary"
              onClick={handleBack}
              disabled={currentStep === 1 || isLoading}
            >
              Zurück
            </button>

            <button
              className="btn btn-primary"
              onClick={handleNext}
              disabled={isLoading || (currentStep === 2 && testResult !== 'success')}
            >
              {isLoading ? (
                <div className="flex items-center gap-sm">
                  <div className="spinner"></div>
                  {currentStep === 2 ? 'Teste Verbindung...' : 'Wird eingerichtet...'}
                </div>
              ) : currentStep === 2 ? 'Verbindung testen' : currentStep === 3 ? 'Einrichtung abschließen' : 'Weiter'}
            </button>
          </div>
        )}
      </div>
    </div>
  )
}