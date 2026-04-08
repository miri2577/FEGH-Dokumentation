import { app, BrowserWindow, ipcMain, dialog, shell } from 'electron'
import { join } from 'path'
import Store from 'electron-store'
import keytar from 'keytar'
import { HiDriveManager } from '../lib/hidrive'
import { initCrypto, generateKey, hashPassword, verifyPassword } from '../lib/crypto'
import {
  Employee,
  Shift,
  VacationRequest,
  Team,
  AppConfig,
  ApiResponse
} from '../types'

// Store for app configuration
const store = new Store<{
  hidriveUrl?: string
  username?: string
  companyName?: string
  windowBounds?: { width: number; height: number; x?: number; y?: number }
}>()

// Constants
const SERVICE_NAME = 'eingliederungshilfe-admin'
const ACCOUNT_HIDRIVE = 'hidrive-credentials'
const ACCOUNT_MEK = 'master-encryption-key'

let mainWindow: BrowserWindow | null = null
let hidriveManager: HiDriveManager | null = null

// Initialize crypto on startup
initCrypto().catch(console.error)

function createWindow(): void {
  const bounds = store.get('windowBounds', { width: 1400, height: 900 })

  mainWindow = new BrowserWindow({
    ...bounds,
    minWidth: 1200,
    minHeight: 800,
    show: false,
    autoHideMenuBar: true,
    webPreferences: {
      preload: join(__dirname, '../preload/index.mjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    },
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    icon: process.platform === 'linux' ? join(__dirname, '../../resources/icon.png') : undefined
  })

  mainWindow.on('ready-to-show', () => {
    mainWindow?.show()
  })

  mainWindow.on('resize', () => {
    if (mainWindow) {
      store.set('windowBounds', mainWindow.getBounds())
    }
  })

  mainWindow.webContents.setWindowOpenHandler((details) => {
    shell.openExternal(details.url)
    return { action: 'deny' }
  })

  // Load the renderer
  if (process.env.NODE_ENV === 'development' && process.env.ELECTRON_RENDERER_URL) {
    mainWindow.loadURL(process.env.ELECTRON_RENDERER_URL)
    mainWindow.webContents.openDevTools()
  } else {
    mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
  }
}

// App event handlers
app.whenReady().then(() => {
  app.setAppUserModelId('com.eingliederungshilfe.admin')

  createWindow()

  app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

// Helper functions
async function getHiDriveCredentials(): Promise<{ username: string; password: string } | null> {
  try {
    const credentials = await keytar.getPassword(SERVICE_NAME, ACCOUNT_HIDRIVE)
    return credentials ? JSON.parse(credentials) : null
  } catch {
    return null
  }
}

async function getMasterKey(): Promise<Uint8Array | null> {
  try {
    const mekBase64 = await keytar.getPassword(SERVICE_NAME, ACCOUNT_MEK)
    return mekBase64 ? Buffer.from(mekBase64, 'base64') : null
  } catch {
    return null
  }
}

async function initializeHiDriveManager(): Promise<boolean> {
  try {
    const config = store.get('hidriveUrl')
    const credentials = await getHiDriveCredentials()
    const mek = await getMasterKey()

    if (!config || !credentials || !mek) {
      return false
    }

    hidriveManager = new HiDriveManager(config, credentials.username, credentials.password, mek)
    await hidriveManager.testConnection()
    await hidriveManager.initializeDirectories()
    return true
  } catch (error) {
    console.error('Failed to initialize HiDrive manager:', error)
    return false
  }
}

// IPC Handlers

// Configuration
ipcMain.handle('config:get', async (): Promise<ApiResponse<AppConfig>> => {
  try {
    const config = {
      hidriveUrl: store.get('hidriveUrl', ''),
      username: store.get('username', ''),
      companyName: store.get('companyName', ''),
      businessHours: { start: '08:00', end: '17:00' },
      overtimeRules: { dailyThreshold: 8, weeklyThreshold: 40, rate: 1.5 }
    }

    return {
      success: true,
      data: config,
      timestamp: new Date().toISOString()
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    }
  }
})

ipcMain.handle('config:set', async (_, config: Partial<AppConfig>): Promise<ApiResponse> => {
  try {
    if (config.hidriveUrl) store.set('hidriveUrl', config.hidriveUrl)
    if (config.username) store.set('username', config.username)
    if (config.companyName) store.set('companyName', config.companyName)

    return {
      success: true,
      timestamp: new Date().toISOString()
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    }
  }
})

// Authentication
ipcMain.handle('auth:setup', async (_, { username, password, hidriveUrl }: {
  username: string
  password: string
  hidriveUrl: string
}): Promise<ApiResponse<{ mekGenerated: boolean }>> => {
  try {
    // Store HiDrive credentials
    await keytar.setPassword(SERVICE_NAME, ACCOUNT_HIDRIVE, JSON.stringify({
      username,
      password
    }))

    // Generate and store master encryption key
    const mek = generateKey()
    await keytar.setPassword(SERVICE_NAME, ACCOUNT_MEK, Buffer.from(mek).toString('base64'))

    // Store configuration
    store.set('hidriveUrl', hidriveUrl)
    store.set('username', username)

    // Initialize HiDrive manager
    const initialized = await initializeHiDriveManager()

    return {
      success: initialized,
      data: { mekGenerated: true },
      timestamp: new Date().toISOString()
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Setup failed',
      timestamp: new Date().toISOString()
    }
  }
})

ipcMain.handle('auth:test-connection', async (): Promise<ApiResponse<{ connected: boolean }>> => {
  try {
    const connected = await initializeHiDriveManager()
    return {
      success: true,
      data: { connected },
      timestamp: new Date().toISOString()
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Connection test failed',
      timestamp: new Date().toISOString()
    }
  }
})

// Employee Management
ipcMain.handle('employees:list', async (): Promise<ApiResponse<Employee[]>> => {
  try {
    if (!hidriveManager) {
      await initializeHiDriveManager()
    }

    if (!hidriveManager) {
      throw new Error('HiDrive not configured')
    }

    const employeeIds = await hidriveManager.listCategory('employees')
    const employees: Employee[] = []

    for (const id of employeeIds) {
      const employee = await hidriveManager.retrieveDecrypted<Employee>('employees', id)
      if (employee) {
        employees.push(employee)
      }
    }

    return {
      success: true,
      data: employees.sort((a, b) => a.lastName.localeCompare(b.lastName)),
      timestamp: new Date().toISOString()
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to list employees',
      timestamp: new Date().toISOString()
    }
  }
})

ipcMain.handle('employees:create', async (_, employee: Omit<Employee, 'id' | 'createdAt' | 'updatedAt'>): Promise<ApiResponse<{ id: string }>> => {
  try {
    if (!hidriveManager) {
      throw new Error('HiDrive not configured')
    }

    const now = new Date().toISOString()
    const newEmployee: Employee = {
      ...employee,
      id: crypto.randomUUID(),
      createdAt: now,
      updatedAt: now
    }

    const id = await hidriveManager.storeEncrypted('employees', newEmployee, newEmployee.id)

    return {
      success: true,
      data: { id },
      timestamp: new Date().toISOString()
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to create employee',
      timestamp: new Date().toISOString()
    }
  }
})

ipcMain.handle('employees:update', async (_, id: string, updates: Partial<Employee>): Promise<ApiResponse> => {
  try {
    if (!hidriveManager) {
      throw new Error('HiDrive not configured')
    }

    const existing = await hidriveManager.retrieveDecrypted<Employee>('employees', id)
    if (!existing) {
      throw new Error('Employee not found')
    }

    const updated: Employee = {
      ...existing,
      ...updates,
      id,
      updatedAt: new Date().toISOString()
    }

    await hidriveManager.storeEncrypted('employees', updated, id)

    return {
      success: true,
      timestamp: new Date().toISOString()
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to update employee',
      timestamp: new Date().toISOString()
    }
  }
})

ipcMain.handle('employees:delete', async (_, id: string): Promise<ApiResponse> => {
  try {
    if (!hidriveManager) {
      throw new Error('HiDrive not configured')
    }

    const deleted = await hidriveManager.deleteItem('employees', id)

    return {
      success: deleted,
      error: deleted ? undefined : 'Failed to delete employee',
      timestamp: new Date().toISOString()
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to delete employee',
      timestamp: new Date().toISOString()
    }
  }
})

// System
ipcMain.handle('system:backup', async (): Promise<ApiResponse<{ backupId: string }>> => {
  try {
    if (!hidriveManager) {
      throw new Error('HiDrive not configured')
    }

    const backupId = await hidriveManager.createBackup()

    return {
      success: true,
      data: { backupId },
      timestamp: new Date().toISOString()
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Backup failed',
      timestamp: new Date().toISOString()
    }
  }
})

ipcMain.handle('system:stats', async (): Promise<ApiResponse<any>> => {
  try {
    if (!hidriveManager) {
      throw new Error('HiDrive not configured')
    }

    const stats = await hidriveManager.getStorageStats()

    return {
      success: true,
      data: stats,
      timestamp: new Date().toISOString()
    }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to get stats',
      timestamp: new Date().toISOString()
    }
  }
})

// Development mode
ipcMain.handle('dev:is-dev-mode', async (): Promise<boolean> => {
  return process.env.NODE_ENV === 'development'
})

// File dialogs
ipcMain.handle('dialog:open-file', async () => {
  const result = await dialog.showOpenDialog(mainWindow!, {
    properties: ['openFile'],
    filters: [
      { name: 'JSON Files', extensions: ['json'] },
      { name: 'All Files', extensions: ['*'] }
    ]
  })
  return result
})

ipcMain.handle('dialog:save-file', async () => {
  const result = await dialog.showSaveDialog(mainWindow!, {
    filters: [
      { name: 'JSON Files', extensions: ['json'] },
      { name: 'All Files', extensions: ['*'] }
    ]
  })
  return result
})