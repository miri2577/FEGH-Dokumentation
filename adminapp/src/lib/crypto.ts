import sodium from 'libsodium-wrappers-sumo'

// Initialize libsodium
export async function initCrypto(): Promise<void> {
  await sodium.ready
}

// Generate a random 32-byte key
export function generateKey(): Uint8Array {
  return sodium.randombytes_buf(32)
}

// Generate a random UUID for filenames
export function generateUUID(): string {
  const bytes = sodium.randombytes_buf(16)
  const hex = sodium.to_hex(bytes)
  return [
    hex.slice(0, 8),
    hex.slice(8, 12),
    hex.slice(12, 16),
    hex.slice(16, 20),
    hex.slice(20, 32)
  ].join('-')
}

// Encrypt data with AES-256-GCM equivalent (XChaCha20-Poly1305)
export function encryptData(
  key: Uint8Array,
  plaintext: string | Uint8Array,
  additionalData?: string
): {
  nonce: string
  ciphertext: string
  tag: string
} {
  const nonce = sodium.randombytes_buf(24) // XChaCha20 nonce size
  const data = typeof plaintext === 'string' ?
    new TextEncoder().encode(plaintext) : plaintext

  const aad = additionalData ?
    new TextEncoder().encode(additionalData) : null

  const encrypted = sodium.crypto_aead_xchacha20poly1305_ietf_encrypt(
    data,
    aad,
    null,
    nonce,
    key
  )

  // Split tag from ciphertext (last 16 bytes are the tag)
  const ciphertext = encrypted.slice(0, -16)
  const tag = encrypted.slice(-16)

  return {
    nonce: sodium.to_base64(nonce),
    ciphertext: sodium.to_base64(ciphertext),
    tag: sodium.to_base64(tag)
  }
}

// Decrypt data
export function decryptData(
  key: Uint8Array,
  nonce: string,
  ciphertext: string,
  tag: string,
  additionalData?: string
): Uint8Array {
  const nonceBytes = sodium.from_base64(nonce)
  const ciphertextBytes = sodium.from_base64(ciphertext)
  const tagBytes = sodium.from_base64(tag)

  // Combine ciphertext and tag for libsodium
  const encrypted = new Uint8Array(ciphertextBytes.length + tagBytes.length)
  encrypted.set(ciphertextBytes)
  encrypted.set(tagBytes, ciphertextBytes.length)

  const aad = additionalData ?
    new TextEncoder().encode(additionalData) : null

  return sodium.crypto_aead_xchacha20poly1305_ietf_decrypt(
    null,
    encrypted,
    aad,
    nonceBytes,
    key
  )
}

// Wrap/unwrap keys using master encryption key (MEK)
export function wrapKey(mek: Uint8Array, dek: Uint8Array): {
  nonce: string
  wrappedKey: string
  tag: string
} {
  return encryptData(mek, dek, 'DEK-WRAP-v1')
}

export function unwrapKey(
  mek: Uint8Array,
  nonce: string,
  wrappedKey: string,
  tag: string
): Uint8Array {
  return decryptData(mek, nonce, wrappedKey, tag, 'DEK-WRAP-v1')
}

// Key derivation from password (ARGON2)
export function deriveKeyFromPassword(
  password: string,
  salt: Uint8Array
): Uint8Array {
  return sodium.crypto_pwhash(
    32, // key length
    password,
    salt,
    sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE,
    sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE,
    sodium.crypto_pwhash_ALG_ARGON2ID
  )
}

// Generate salt for password hashing
export function generateSalt(): Uint8Array {
  return sodium.randombytes_buf(sodium.crypto_pwhash_SALTBYTES)
}

// Hash password for storage
export function hashPassword(password: string): {
  hash: string
  salt: string
} {
  const salt = generateSalt()
  const hash = deriveKeyFromPassword(password, salt)

  return {
    hash: sodium.to_base64(hash),
    salt: sodium.to_base64(salt)
  }
}

// Verify password
export function verifyPassword(
  password: string,
  storedHash: string,
  storedSalt: string
): boolean {
  try {
    const salt = sodium.from_base64(storedSalt)
    const hash = deriveKeyFromPassword(password, salt)
    const expectedHash = sodium.from_base64(storedHash)

    return sodium.memcmp(hash, expectedHash)
  } catch {
    return false
  }
}

// Secure memory clearing
export function secureZero(data: Uint8Array): void {
  sodium.memzero(data)
}