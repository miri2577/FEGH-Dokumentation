import { createClient, WebDAVClient } from 'webdav'
import {
  generateKey,
  generateUUID,
  encryptData,
  decryptData,
  wrapKey,
  unwrapKey
} from './crypto'
import { EncryptedData } from '../types'

export class HiDriveManager {
  private client: WebDAVClient
  private mek: Uint8Array // Master Encryption Key
  private basePath = '/eingliederungshilfe-admin'

  constructor(url: string, username: string, password: string, mek: Uint8Array) {
    this.client = createClient(url, {
      username,
      password,
      headers: {
        'User-Agent': 'EingliederungshilfeAdmin/1.0.0'
      }
    })
    this.mek = mek
  }

  // Initialize directory structure
  async initializeDirectories(): Promise<void> {
    const dirs = [
      `${this.basePath}`,
      `${this.basePath}/employees`,
      `${this.basePath}/shifts`,
      `${this.basePath}/vacation`,
      `${this.basePath}/teams`,
      `${this.basePath}/config`,
      `${this.basePath}/backups`
    ]

    for (const dir of dirs) {
      try {
        await this.client.createDirectory(dir)
      } catch (error) {
        // Directory might already exist, ignore error
        console.log(`Directory ${dir} already exists or creation failed`)
      }
    }
  }

  // Encrypt and store data
  async storeEncrypted<T>(
    category: string,
    data: T,
    customId?: string
  ): Promise<string> {
    const id = customId || generateUUID()
    const dek = generateKey() // Data Encryption Key

    // Encrypt the actual data with DEK
    const jsonData = JSON.stringify(data)
    const { nonce, ciphertext, tag } = encryptData(
      dek,
      jsonData,
      `${category}-${id}`
    )

    // Wrap DEK with MEK
    const wrappedDek = wrapKey(this.mek, dek)

    // Create encrypted record
    const encryptedRecord: EncryptedData = {
      id,
      version: 1,
      algorithm: 'xchacha20poly1305',
      nonce,
      ciphertext,
      tag,
      metadata: {
        category,
        dekWrapped: {
          nonce: wrappedDek.nonce,
          ciphertext: wrappedDek.wrappedKey,
          tag: wrappedDek.tag
        }
      },
      createdAt: new Date().toISOString()
    }

    // Store with UUID filename
    const filePath = `${this.basePath}/${category}/${id}.enc`
    await this.atomicWrite(filePath, JSON.stringify(encryptedRecord))

    return id
  }

  // Retrieve and decrypt data
  async retrieveDecrypted<T>(category: string, id: string): Promise<T | null> {
    try {
      const filePath = `${this.basePath}/${category}/${id}.enc`
      const encryptedData = await this.client.getFileContents(filePath, {
        format: 'text'
      }) as string

      const record: EncryptedData = JSON.parse(encryptedData)

      // Unwrap DEK
      const dekMeta = record.metadata?.dekWrapped as any
      const dek = unwrapKey(
        this.mek,
        dekMeta.nonce,
        dekMeta.ciphertext,
        dekMeta.tag
      )

      // Decrypt data
      const decryptedBytes = decryptData(
        dek,
        record.nonce,
        record.ciphertext,
        record.tag,
        `${category}-${id}`
      )

      const jsonData = new TextDecoder().decode(decryptedBytes)
      return JSON.parse(jsonData) as T

    } catch (error) {
      console.error(`Failed to retrieve ${category}/${id}:`, error)
      return null
    }
  }

  // List all items in a category
  async listCategory(category: string): Promise<string[]> {
    try {
      const dirPath = `${this.basePath}/${category}`
      const contents = await this.client.getDirectoryContents(dirPath)

      return contents
        .filter(item => item.type === 'file' && item.basename?.endsWith('.enc'))
        .map(item => item.basename!.replace('.enc', ''))
    } catch (error) {
      console.error(`Failed to list ${category}:`, error)
      return []
    }
  }

  // Delete item
  async deleteItem(category: string, id: string): Promise<boolean> {
    try {
      const filePath = `${this.basePath}/${category}/${id}.enc`
      await this.client.deleteFile(filePath)
      return true
    } catch (error) {
      console.error(`Failed to delete ${category}/${id}:`, error)
      return false
    }
  }

  // Atomic write operation
  private async atomicWrite(path: string, data: string): Promise<void> {
    const tempPath = `${path}.tmp`
    try {
      // Write to temporary file
      await this.client.putFileContents(tempPath, data)
      // Move to final location (atomic on most filesystems)
      await this.client.moveFile(tempPath, path)
    } catch (error) {
      // Clean up temp file if it exists
      try {
        await this.client.deleteFile(tempPath)
      } catch {
        // Ignore cleanup errors
      }
      throw error
    }
  }

  // Backup data
  async createBackup(): Promise<string> {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
    const backupId = `backup-${timestamp}`

    const categories = ['employees', 'shifts', 'vacation', 'teams', 'config']
    const backupData: Record<string, any[]> = {}

    for (const category of categories) {
      const ids = await this.listCategory(category)
      backupData[category] = []

      for (const id of ids) {
        const data = await this.retrieveDecrypted(category, id)
        if (data) {
          backupData[category].push({ id, data })
        }
      }
    }

    await this.storeEncrypted('backups', backupData, backupId)
    return backupId
  }

  // Test connection
  async testConnection(): Promise<boolean> {
    try {
      await this.client.getDirectoryContents('/')
      return true
    } catch (error) {
      console.error('HiDrive connection test failed:', error)
      return false
    }
  }

  // Get storage statistics
  async getStorageStats(): Promise<{
    totalFiles: number
    categoryCounts: Record<string, number>
  }> {
    const categories = ['employees', 'shifts', 'vacation', 'teams', 'config']
    const categoryCounts: Record<string, number> = {}
    let totalFiles = 0

    for (const category of categories) {
      const count = (await this.listCategory(category)).length
      categoryCounts[category] = count
      totalFiles += count
    }

    return { totalFiles, categoryCounts }
  }
}