import crypto from 'node:crypto'
import sodium from 'libsodium-wrappers-sumo'

// libsodium wird nur noch fuer Argon2id-Passwort-Hashing verwendet (siehe unten).
export async function initCrypto(): Promise<void> {
  await sodium.ready
}

// 32-Byte-Zufallsschluessel (AES-256).
export function generateKey(): Uint8Array {
  return crypto.randomBytes(32)
}

// UUID v4 fuer Dateinamen (identisch zu Flutter _uuid.v4()).
export function generateUUID(): string {
  return crypto.randomUUID()
}

// ---------------------------------------------------------------------------
// Interop-Verschluesselung mit der Flutter-App (Paket fegh_crypto).
//
// Bit-identisch zum Dart-Wire-Format `EncryptedRecord`:
//   AES-256-GCM, IV/Nonce 12 Byte, Auth-Tag 16 Byte (getrennt vom Ciphertext),
//   Standard-Base64 MIT Padding. Zwei-Schichten-Envelope: pro Record eine
//   zufaellige 32-Byte-DEK verschluesselt die Nutzdaten (AAD = kompaktes JSON des
//   aad-Objekts), die DEK wird mit dem 32-Byte-MEK gewrappt (AAD konstant
//   {"type":"dek"}). So koennen Flutter-App und Adminapp DIESELBEN HiDrive-Daten
//   lesen/schreiben.
// ---------------------------------------------------------------------------

// Exakt die 14 UTF-8-Bytes von {"type":"dek"} (wie kDekWrapAad in Dart).
const DEK_WRAP_AAD = Buffer.from('{"type":"dek"}', 'utf8')

export interface GcmBox {
  alg: 'AES-256-GCM'
  nonce: string
  ciphertext: string
  tag: string
}

export interface EncryptedRecord {
  v: 1
  alg: 'AES-256-GCM'
  nonce: string
  aad: Record<string, unknown>
  ciphertext: string
  tag: string
  dekWrapped: GcmBox
}

function b64(b: Uint8Array): string {
  return Buffer.from(b).toString('base64')
}
function unb64(s: string): Buffer {
  return Buffer.from(s, 'base64')
}

// Kanonische AAD-Bytes = kompaktes JSON (keine Leerzeichen, Einfuegereihenfolge),
// byte-identisch zu Dart `json.encode(aad)`. JSON.stringify erzeugt dieselbe
// kompakte Ausgabe fuer die hier genutzten Schluesseltypen (String/Zahl).
function aadBytes(aad: Record<string, unknown>): Buffer {
  return Buffer.from(JSON.stringify(aad), 'utf8')
}

function gcmEncrypt(key: Uint8Array, plaintext: Uint8Array, aad: Buffer): GcmBox {
  const iv = crypto.randomBytes(12)
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv, { authTagLength: 16 })
  cipher.setAAD(aad)
  const ct = Buffer.concat([cipher.update(plaintext), cipher.final()])
  const tag = cipher.getAuthTag() // 16 Byte, getrennt gespeichert (wie Dart box.mac)
  return { alg: 'AES-256-GCM', nonce: b64(iv), ciphertext: b64(ct), tag: b64(tag) }
}

function gcmDecrypt(key: Uint8Array, box: GcmBox, aad: Buffer): Buffer {
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, unb64(box.nonce), {
    authTagLength: 16,
  })
  decipher.setAAD(aad)
  decipher.setAuthTag(unb64(box.tag))
  return Buffer.concat([decipher.update(unb64(box.ciphertext)), decipher.final()])
}

/** Verschluesselt Nutzdaten (roh) im Flutter-EncryptedRecord-Format. */
export function encryptRecord(
  mek: Uint8Array,
  plaintext: Uint8Array,
  aad: Record<string, unknown> = {},
): EncryptedRecord {
  const dek = crypto.randomBytes(32)
  const data = gcmEncrypt(dek, plaintext, aadBytes(aad))
  const wrapped = gcmEncrypt(mek, dek, DEK_WRAP_AAD)
  return {
    v: 1,
    alg: 'AES-256-GCM',
    nonce: data.nonce,
    aad,
    ciphertext: data.ciphertext,
    tag: data.tag,
    dekWrapped: wrapped,
  }
}

/** Entschluesselt ein Flutter-EncryptedRecord und liefert die Nutzdaten-Bytes. */
export function decryptRecord(mek: Uint8Array, rec: EncryptedRecord): Uint8Array {
  const dek = gcmDecrypt(mek, rec.dekWrapped, DEK_WRAP_AAD)
  return gcmDecrypt(dek, { alg: 'AES-256-GCM', nonce: rec.nonce, ciphertext: rec.ciphertext, tag: rec.tag }, aadBytes(rec.aad ?? {}))
}

/** Bequemlichkeit: JSON-Objekt verschluesseln (Plaintext = UTF-8 des kompakten JSON). */
export function encryptJson(
  mek: Uint8Array,
  obj: unknown,
  aad: Record<string, unknown> = {},
): EncryptedRecord {
  return encryptRecord(mek, Buffer.from(JSON.stringify(obj), 'utf8'), aad)
}

/** Bequemlichkeit: Record entschluesseln und als JSON parsen. */
export function decryptJson<T>(mek: Uint8Array, rec: EncryptedRecord): T {
  return JSON.parse(Buffer.from(decryptRecord(mek, rec)).toString('utf8')) as T
}

// ---------------------------------------------------------------------------
// Passwort-Hashing (Argon2id via libsodium) – unveraendert, fuer optionale
// Passwort-basierte MEK-Ableitung; initCrypto() muss vorher gelaufen sein.
// ---------------------------------------------------------------------------
export function deriveKeyFromPassword(password: string, salt: Uint8Array): Uint8Array {
  return sodium.crypto_pwhash(
    32,
    password,
    salt,
    sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE,
    sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE,
    sodium.crypto_pwhash_ALG_ARGON2ID,
  )
}

export function generateSalt(): Uint8Array {
  return sodium.randombytes_buf(sodium.crypto_pwhash_SALTBYTES)
}

export function hashPassword(password: string): { hash: string; salt: string } {
  const salt = generateSalt()
  const hash = deriveKeyFromPassword(password, salt)
  return { hash: sodium.to_base64(hash), salt: sodium.to_base64(salt) }
}

export function verifyPassword(password: string, storedHash: string, storedSalt: string): boolean {
  try {
    const salt = sodium.from_base64(storedSalt)
    const hash = deriveKeyFromPassword(password, salt)
    return sodium.memcmp(hash, sodium.from_base64(storedHash))
  } catch {
    return false
  }
}

// Speicher ueberschreiben.
export function secureZero(data: Uint8Array): void {
  data.fill(0)
}
