import { createClient, WebDAVClient } from 'webdav'
import { generateUUID, encryptJson, decryptJson, EncryptedRecord } from './crypto'

/**
 * WebDAV-Speicher im **gemeinsamen Format der Flutter-App** (Paket fegh_crypto /
 * fegh_cloud). Provider-neutral über den generischen `webdav`-Client – funktioniert
 * mit **jedem WebDAV-Anbieter** (STRATO HiDrive, Nextcloud, ownCloud, generisches
 * WebDAV); nur die Basis-URL unterscheidet sich. Records werden als
 * AES-256-GCM-Envelope (siehe crypto.ts) als `<id>.bin` (UTF-8-JSON) im
 * hierarchischen FeghPaths-Layout abgelegt:
 *
 *   <root>/organizations/<orgId>/employees/<id>.bin
 *   <root>/organizations/<orgId>/administration/{teams,shifts,vacation,backups}/<id>.bin
 *
 * So lesen/schreiben Adminapp und Flutter-App dieselben Cloud-Daten.
 */
export class WebDavStorage {
  private client: WebDAVClient
  private mek: Uint8Array
  private root: string
  private orgId: string

  constructor(
    url: string,
    username: string,
    password: string,
    mek: Uint8Array,
    orgId: string,
    root = 'eingliederungshilfe',
  ) {
    this.client = createClient(url, {
      username,
      password,
      headers: { 'User-Agent': 'EingliederungshilfeAdmin/1.0.0' },
    })
    this.mek = mek
    this.orgId = orgId
    this.root = root
  }

  private orgRoot(): string {
    return `/${this.root}/organizations/${this.orgId}`
  }

  /** Ablage-Verzeichnis + Flutter-Schema je Kategorie (bindet die AAD). */
  private layout(category: string): { dir: string; schema: string } {
    const admin = `${this.orgRoot()}/administration`
    switch (category) {
      case 'employees':
        return { dir: `${this.orgRoot()}/employees`, schema: 'mitarbeiter' }
      case 'vacation':
        return { dir: `${admin}/vacation`, schema: 'freizeit_antrag' }
      case 'shifts':
        return { dir: `${admin}/shifts`, schema: 'shift' }
      case 'teams':
        return { dir: `${admin}/teams`, schema: 'team' }
      case 'config':
        return { dir: admin, schema: 'settings' }
      case 'backups':
        return { dir: `${admin}/backups`, schema: 'backup' }
      default:
        return { dir: `${admin}/${category}`, schema: category }
    }
  }

  private recordPath(category: string, id: string): string {
    return `${this.layout(category).dir}/${id}.bin`
  }

  async initializeDirectories(): Promise<void> {
    const admin = `${this.orgRoot()}/administration`
    const dirs = [
      `/${this.root}`,
      `/${this.root}/organizations`,
      this.orgRoot(),
      `${this.orgRoot()}/employees`,
      `${this.orgRoot()}/teams`,
      admin,
      `${admin}/teams`,
      `${admin}/shifts`,
      `${admin}/vacation`,
      `${admin}/backups`,
    ]
    for (const dir of dirs) {
      try {
        await this.client.createDirectory(dir)
      } catch {
        // existiert bereits – ignorieren
      }
    }
  }

  /** Verschluesselt und legt einen Record im Flutter-Format ab. */
  async storeEncrypted<T>(category: string, data: T, customId?: string): Promise<string> {
    const id = customId || generateUUID()
    const { dir, schema } = this.layout(category)
    // AAD exakt wie die Flutter-App: {schema, ts, version:1} in dieser Reihenfolge.
    const aad = { schema, ts: new Date().toISOString(), version: 1 }
    const record = encryptJson(this.mek, data, aad)
    await this.atomicWrite(`${dir}/${id}.bin`, JSON.stringify(record))
    return id
  }

  async retrieveDecrypted<T>(category: string, id: string): Promise<T | null> {
    try {
      const content = (await this.client.getFileContents(this.recordPath(category, id), {
        format: 'text',
      })) as string
      const record = JSON.parse(content) as EncryptedRecord
      return decryptJson<T>(this.mek, record)
    } catch (error) {
      console.error(`Failed to retrieve ${category}/${id}:`, error)
      return null
    }
  }

  async listCategory(category: string): Promise<string[]> {
    try {
      const contents = await this.client.getDirectoryContents(this.layout(category).dir)
      return (Array.isArray(contents) ? contents : [])
        .filter((item) => item.type === 'file' && item.basename?.endsWith('.bin'))
        .map((item) => item.basename!.replace(/\.bin$/, ''))
    } catch (error) {
      console.error(`Failed to list ${category}:`, error)
      return []
    }
  }

  async deleteItem(category: string, id: string): Promise<boolean> {
    try {
      await this.client.deleteFile(this.recordPath(category, id))
      return true
    } catch (error) {
      console.error(`Failed to delete ${category}/${id}:`, error)
      return false
    }
  }

  private async atomicWrite(path: string, data: string): Promise<void> {
    const tempPath = `${path}.tmp`
    try {
      await this.client.putFileContents(tempPath, data)
      await this.client.moveFile(tempPath, path)
    } catch (error) {
      try {
        await this.client.deleteFile(tempPath)
      } catch {
        // Cleanup-Fehler ignorieren
      }
      throw error
    }
  }

  async createBackup(): Promise<string> {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
    const backupId = `backup-${timestamp}`
    const categories = ['employees', 'shifts', 'vacation', 'teams', 'config']
    const backupData: Record<string, Array<{ id: string; data: unknown }>> = {}
    for (const category of categories) {
      backupData[category] = []
      for (const id of await this.listCategory(category)) {
        const data = await this.retrieveDecrypted(category, id)
        if (data) backupData[category].push({ id, data })
      }
    }
    await this.storeEncrypted('backups', backupData, backupId)
    return backupId
  }

  async testConnection(): Promise<boolean> {
    try {
      await this.client.getDirectoryContents('/')
      return true
    } catch (error) {
      console.error('WebDAV connection test failed:', error)
      return false
    }
  }

  async getStorageStats(): Promise<{ totalFiles: number; categoryCounts: Record<string, number> }> {
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
