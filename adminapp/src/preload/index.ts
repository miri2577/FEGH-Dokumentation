import { contextBridge, ipcRenderer } from 'electron'
import { Employee, Shift, VacationRequest, Team, AppConfig, ApiResponse } from '../types'

// Check if we're in development mode
const isDev = process.env.NODE_ENV === 'development'

// Define the API interface
export interface ElectronAPI {
  // Configuration
  config: {
    get(): Promise<ApiResponse<AppConfig>>
    set(config: Partial<AppConfig>): Promise<ApiResponse>
  }

  // Authentication
  auth: {
    setup(credentials: { username: string; password: string; hidriveUrl: string }): Promise<ApiResponse<{ mekGenerated: boolean }>>
    testConnection(): Promise<ApiResponse<{ connected: boolean }>>
  }

  // Employee Management
  employees: {
    list(): Promise<ApiResponse<Employee[]>>
    create(employee: Omit<Employee, 'id' | 'createdAt' | 'updatedAt'>): Promise<ApiResponse<{ id: string }>>
    update(id: string, updates: Partial<Employee>): Promise<ApiResponse>
    delete(id: string): Promise<ApiResponse>
  }

  // Shift Management
  shifts: {
    list(startDate?: string, endDate?: string): Promise<ApiResponse<Shift[]>>
    create(shift: Omit<Shift, 'id' | 'createdAt' | 'updatedAt'>): Promise<ApiResponse<{ id: string }>>
    update(id: string, updates: Partial<Shift>): Promise<ApiResponse>
    delete(id: string): Promise<ApiResponse>
  }

  // Vacation Management
  vacation: {
    list(): Promise<ApiResponse<VacationRequest[]>>
    create(request: Omit<VacationRequest, 'id' | 'requestedAt'>): Promise<ApiResponse<{ id: string }>>
    update(id: string, updates: Partial<VacationRequest>): Promise<ApiResponse>
    delete(id: string): Promise<ApiResponse>
  }

  // Team Management
  teams: {
    list(): Promise<ApiResponse<Team[]>>
    create(team: Omit<Team, 'id' | 'createdAt' | 'updatedAt'>): Promise<ApiResponse<{ id: string }>>
    update(id: string, updates: Partial<Team>): Promise<ApiResponse>
    delete(id: string): Promise<ApiResponse>
  }

  // System
  system: {
    backup(): Promise<ApiResponse<{ backupId: string }>>
    stats(): Promise<ApiResponse<any>>
  }

  // Dialogs
  dialog: {
    openFile(): Promise<Electron.OpenDialogReturnValue>
    saveFile(): Promise<Electron.SaveDialogReturnValue>
  }

  // Utilities
  utils: {
    generateId(): string
    formatDate(date: string): string
    formatTime(time: string): string
  }

  // Development Mode
  dev: {
    isDevMode(): Promise<boolean>
    toggleMockMode(): void
    getMockEmployees(): Employee[]
    getMockShifts(): Shift[]
    getMockVacationRequests(): VacationRequest[]
  }
}

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
const electronAPI: ElectronAPI = {
  config: {
    get: () => ipcRenderer.invoke('config:get'),
    set: (config) => ipcRenderer.invoke('config:set', config)
  },

  auth: {
    setup: (credentials) => ipcRenderer.invoke('auth:setup', credentials),
    testConnection: () => ipcRenderer.invoke('auth:test-connection')
  },

  employees: {
    list: () => ipcRenderer.invoke('employees:list'),
    create: (employee) => ipcRenderer.invoke('employees:create', employee),
    update: (id, updates) => ipcRenderer.invoke('employees:update', id, updates),
    delete: (id) => ipcRenderer.invoke('employees:delete', id)
  },

  shifts: {
    list: (startDate, endDate) => ipcRenderer.invoke('shifts:list', startDate, endDate),
    create: (shift) => ipcRenderer.invoke('shifts:create', shift),
    update: (id, updates) => ipcRenderer.invoke('shifts:update', id, updates),
    delete: (id) => ipcRenderer.invoke('shifts:delete', id)
  },

  vacation: {
    list: () => ipcRenderer.invoke('vacation:list'),
    create: (request) => ipcRenderer.invoke('vacation:create', request),
    update: (id, updates) => ipcRenderer.invoke('vacation:update', id, updates),
    delete: (id) => ipcRenderer.invoke('vacation:delete', id)
  },

  teams: {
    list: () => ipcRenderer.invoke('teams:list'),
    create: (team) => ipcRenderer.invoke('teams:create', team),
    update: (id, updates) => ipcRenderer.invoke('teams:update', id, updates),
    delete: (id) => ipcRenderer.invoke('teams:delete', id)
  },

  system: {
    backup: () => ipcRenderer.invoke('system:backup'),
    stats: () => ipcRenderer.invoke('system:stats')
  },

  dialog: {
    openFile: () => ipcRenderer.invoke('dialog:open-file'),
    saveFile: () => ipcRenderer.invoke('dialog:save-file')
  },

  utils: {
    generateId: () => crypto.randomUUID(),
    formatDate: (date: string) => new Date(date).toLocaleDateString('de-DE'),
    formatTime: (time: string) => new Date(`2000-01-01T${time}`).toLocaleTimeString('de-DE', {
      hour: '2-digit',
      minute: '2-digit'
    })
  },

  dev: {
    isDevMode: () => ipcRenderer.invoke('dev:is-dev-mode'),
    toggleMockMode: () => {
      if (isDev) {
        console.log('🔧 Mock mode toggled')
      }
    },
    getMockEmployees: () => {
      if (isDev) {
        // Import mock data dynamically in renderer
        return []
      }
      return []
    },
    getMockShifts: () => {
      if (isDev) {
        return []
      }
      return []
    },
    getMockVacationRequests: () => {
      if (isDev) {
        return []
      }
      return []
    }
  }
}

// Use `contextBridge` APIs to expose Electron APIs to
// renderer only if context isolation is enabled, otherwise
// just add to the DOM global.
if (process.contextIsolated) {
  try {
    contextBridge.exposeInMainWorld('electronAPI', electronAPI)
  } catch (error) {
    console.error('Failed to expose electronAPI:', error)
  }
} else {
  // @ts-ignore (define in dts)
  window.electronAPI = electronAPI
}

// Expose version information
contextBridge.exposeInMainWorld('versions', {
  node: () => process.versions.node,
  chrome: () => process.versions.chrome,
  electron: () => process.versions.electron,
  app: () => process.env.npm_package_version || '1.0.0'
})

export type { ElectronAPI }