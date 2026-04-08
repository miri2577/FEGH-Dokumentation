# Electron Admin‑App (HiDrive‑only, E2E) – FIXED Scaffold (TSX transpile OK)

> **Fix für:** `SyntaxError: /index.tsx: Unexpected token (1:0)`  
> **Warum passierte das?** Dein Bundler hat die **TSX/JSX** nicht verarbeitet. Meist fehlt `"jsx": "react-jsx"` in der **tsconfig** oder der Renderer wird nicht über Vite/Electron bundlet.  
> **Was wurde geändert?** Vollständiges Setup mit **electron‑vite**, korrekter **tsconfig.json**, sauberem **Renderer‑Entry** (`src/renderer/index.tsx`) und Tests. Damit wird TSX korrekt transpiliert und der Fehler verschwindet.

**Start:** `pnpm i` → `pnpm dev`  
**Build:** `pnpm build`

---

## Projektstruktur
```
admin-app/
  package.json
  tsconfig.json
  electron.vite.config.ts
  src/
    main.ts               # Electron Main (Fenster, IPC)
    preload.ts            # sichere IPC‑Brücke (contextIsolation)
    lib/
      crypto.ts           # Sodium‑E2E (SK + per‑device wrap/unwrap)
      webdav.ts           # WebDAV Client (HiDrive)
      hidrivePaths.ts     # Pfad‑Konventionen
      models.ts           # Typen
    renderer/
      index.html
      index.tsx           # React Entry (mountet <App/>)
      App.tsx             # UI‑Root + Tabs
      components/
        Settings.tsx
        MessageComposer.tsx
        TeamManager.tsx
        VacationBoard.tsx
    __tests__/
      crypto.test.ts      # AEAD + Device‑Wrap Roundtrip
      config.test.ts      # URL‑Validierung
      renderer.smoke.test.ts # JSX/Renderer‑Smoke (neu)
  .env.example            # HIDRIVE_URL, USER, PASS (nicht committen)
```

---

## package.json (aktualisiert)
```json
{
  "name": "hidrive-admin-app",
  "version": "0.3.0",
  "private": true,
  "type": "module",
  "main": "dist/main/index.js",
  "scripts": {
    "dev": "electron-vite dev",
    "build": "electron-vite build",
    "preview": "electron-vite preview",
    "test": "vitest run"
  },
  "dependencies": {
    "electron": "^31",
    "electron-store": "^9",
    "keytar": "^7",
    "libsodium-wrappers-sumo": "^0.7.13",
    "react": "^18",
    "react-dom": "^18",
    "webdav": "^5",
    "zod": "^3"
  },
  "devDependencies": {
    "@testing-library/react": "^16",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "@vitejs/plugin-react": "^4",
    "electron-vite": "^2",
    "jsdom": "^25",
    "typescript": "^5",
    "vite": "^5",
    "vitest": "^1"
  },
  "vitest": {
    "environment": "jsdom"
  }
}
```

> **Hinweis:** `keytar` nutzt die OS‑Keychain. Für native Module in Dev ggf. `npx electron-rebuild` nutzen, falls dein System Build‑Tools benötigt. Bei den meisten aktuellen Electron‑Versionen sind Prebuilds vorhanden.

---

## tsconfig.json (wichtig für TSX)
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM"],
    "jsx": "react-jsx",
    "moduleResolution": "Bundler",
    "strict": true,
    "resolveJsonModule": true,
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "noEmit": true,
    "skipLibCheck": true,
    "baseUrl": "."
  },
  "include": ["src"]
}
```

---

## electron.vite.config.ts
```ts
import { defineConfig, externalizeDepsPlugin } from 'electron-vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  main: { plugins: [externalizeDepsPlugin()], build: { sourcemap: true } },
  preload: { plugins: [externalizeDepsPlugin()], build: { sourcemap: true } },
  renderer: { plugins: [react()], build: { sourcemap: true } }
});
```

---

## src/main.ts (Electron Main)
```ts
import { app, BrowserWindow, ipcMain } from 'electron';
import path from 'node:path';
import keytar from 'keytar';
import Store from 'electron-store';
import { makeClient, atomicWrite } from './lib/webdav';
import { initCrypto, randomKey32, encryptAEAD, wrapSKForDevice } from './lib/crypto';
import { v4 as uuidv4 } from 'uuid';
import type { CipherRecord, MessagePayload, DevicePub, VacationRequest, VacationDecision } from './lib/models';
import { Paths } from './lib/hidrivePaths';

let win: BrowserWindow | null = null;
const store = new Store<{ hidriveUrl: string }>();
const SERVICE = 'hidrive-admin-app';
const ACCOUNT = 'hidrive-basic-auth';

async function createWindow() {
  win = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      preload: path.join(__dirname, '../preload/index.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  if (process.env.ELECTRON_RENDERER_URL) {
    await win.loadURL(process.env.ELECTRON_RENDERER_URL);
  } else {
    await win.loadFile(path.join(__dirname, '../renderer/index.html'));
  }
}

app.whenReady().then(async () => {
  await initCrypto();
  // ENV → Keychain Migration (optional)
  const envUser = process.env.HIDRIVE_USER;
  const envPass = process.env.HIDRIVE_PASS;
  if (envUser && envPass) {
    await keytar.setPassword(SERVICE, ACCOUNT, JSON.stringify({ user: envUser, pass: envPass }));
  }
  await createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});

app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });

// ---- Config IPC (Keychain + electron-store) ----
ipcMain.handle('cfg:get', async () => {
  const credsJson = await keytar.getPassword(SERVICE, ACCOUNT);
  const creds = credsJson ? JSON.parse(credsJson) : null; // {user, pass}
  const url = store.get('hidriveUrl') || process.env.HIDRIVE_URL || '';
  return { url, user: creds?.user ?? '', hasSecret: Boolean(creds?.pass) };
});

ipcMain.handle('cfg:set', async (_e, { url, user, pass }: { url: string; user: string; pass?: string }) => {
  try { new URL(url); } catch { throw new Error('Ungültige URL'); }
  store.set('hidriveUrl', url);
  if (user && (pass ?? '') !== '') {
    await keytar.setPassword(SERVICE, ACCOUNT, JSON.stringify({ user, pass }));
  } else if (user && (pass ?? '') === '') {
    const old = await keytar.getPassword(SERVICE, ACCOUNT);
    const oldPass = old ? JSON.parse(old).pass : '';
    await keytar.setPassword(SERVICE, ACCOUNT, JSON.stringify({ user, pass: oldPass }));
  }
  return { ok: true };
});

ipcMain.handle('cfg:clear', async () => {
  store.delete('hidriveUrl');
  await keytar.deletePassword(SERVICE, ACCOUNT);
  return { ok: true };
});

ipcMain.handle('hidrive:check', async () => {
  const url = store.get('hidriveUrl') || '';
  const credsJson = await keytar.getPassword(SERVICE, ACCOUNT);
  if (!url || !credsJson) return { ok: false, error: 'Konfiguration unvollständig' };
  const { user, pass } = JSON.parse(credsJson);
  const c = makeClient(url, user, pass);
  try { await c.getDirectoryContents('/'); return { ok: true }; }
  catch (e: any) { return { ok: false, error: e?.message || 'Verbindung fehlgeschlagen' }; }
});

function getClientFromCfg() {
  const url = store.get('hidriveUrl') || '';
  return keytar.getPassword(SERVICE, ACCOUNT).then(json => {
    if (!json) throw new Error('Keine Credentials in Keychain');
    const { user, pass } = JSON.parse(json);
    return makeClient(url, user, pass);
  });
}

// ---- Business IPC ----
ipcMain.handle('hidrive:listDevices', async (_e, userId: string) => {
  const c = await getClientFromCfg();
  const list = await c.getDirectoryContents(Paths.devicesUser(userId));
  const devices: DevicePub[] = [];
  for (const f of list) {
    if (f.type === 'file' && f.basename.endsWith('.pub')) {
      const txt = await c.getFileContents(f.filename, { format: 'text' });
      devices.push(JSON.parse(txt as string));
    }
  }
  return devices;
});

ipcMain.handle('hidrive:sendMessage', async (_e, params: { targets: { userId: string }[]; payload: MessagePayload; devices: Record<string, DevicePub[]> }) => {
  const c = await getClientFromCfg();
  const sk = randomKey32();
  const aad = new TextEncoder().encode(JSON.stringify({ type: 'message', v: 1 }));
  const pt = new TextEncoder().encode(JSON.stringify(params.payload));
  const { nonce, ct } = encryptAEAD(sk, pt, aad);
  const perDevice: CipherRecord['perDevice'] = [];

  for (const t of params.targets) {
    for (const d of (params.devices[t.userId] || [])) {
      perDevice.push({ deviceId: d.deviceId, userId: t.userId, wrapped: wrapSKForDevice(d.pub, sk) });
    }
  }

  const rec: CipherRecord = {
    id: params.payload.id || uuidv4(), v: 1, alg: 'xchacha20poly1305',
    nonce: Buffer.from(nonce).toString('base64'),
    ciphertext: Buffer.from(ct).toString('base64'),
    perDevice, aad: { type: 'message', v: 1 }
  };

  for (const t of params.targets) {
    const p = `${Paths.userInbox(t.userId)}${rec.id}.msg`;
    await atomicWrite(c, p, Buffer.from(JSON.stringify(rec)));
  }
  return { ok: true, id: rec.id };
});

ipcMain.handle('hidrive:createVacationRequest', async (_e, req: VacationRequest) => {
  const c = await getClientFromCfg();
  const id = req.id || uuidv4();
  const p = `${Paths.vacationRequests()}${id}.json`;
  await atomicWrite(c, p, Buffer.from(JSON.stringify({ ...req, id })));
  return { ok: true, id };
});

ipcMain.handle('hidrive:decideVacation', async (_e, dec: VacationDecision) => {
  const c = await getClientFromCfg();
  const id = dec.id || uuidv4();
  const p = `${Paths.vacationDecisions()}${id}.json`;
  await atomicWrite(c, p, Buffer.from(JSON.stringify({ ...dec, id })));
  return { ok: true, id };
});
```

---

## src/preload.ts (IPC‑Brücke)
```ts
import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('api', {
  // Config
  configGet: () => ipcRenderer.invoke('cfg:get'),
  configSet: (payload: { url: string; user: string; pass?: string }) => ipcRenderer.invoke('cfg:set', payload),
  configClear: () => ipcRenderer.invoke('cfg:clear'),
  hidriveCheck: () => ipcRenderer.invoke('hidrive:check'),
  // Business
  listDevices: (userId: string) => ipcRenderer.invoke('hidrive:listDevices', userId),
  sendMessage: (params: any) => ipcRenderer.invoke('hidrive:sendMessage', params),
  createVacationRequest: (req: any) => ipcRenderer.invoke('hidrive:createVacationRequest', req),
  decideVacation: (dec: any) => ipcRenderer.invoke('hidrive:decideVacation', dec)
});
```

---

## src/lib/hidrivePaths.ts
```ts
export const Paths = {
  devicesUser: (userId: string) => `/app/devices/${userId}/`,
  devicePub: (userId: string, deviceId: string) => `/app/devices/${userId}/${deviceId}.pub`,
  userInbox: (userId: string) => `/app/msg/users/${userId}/inbox/`,
  userArchive: (userId: string) => `/app/msg/users/${userId}/archive/`,
  userAck: (userId: string) => `/app/msg/users/${userId}/ack/`,
  groupInbox: (groupId: string) => `/app/msg/groups/${groupId}/inbox/`,
  teamRoot: () => `/app/team/`,
  vacationRequests: () => `/app/vacation/requests/`,
  vacationDecisions: () => `/app/vacation/decisions/`
};
```

---

## src/lib/webdav.ts
```ts
import { createClient, WebDAVClient } from 'webdav';

export function makeClient(url: string, username: string, password: string): WebDAVClient {
  return createClient(url, { username, password });
}

export async function atomicWrite(client: WebDAVClient, path: string, data: Buffer | string) {
  const tmp = path + '.tmp';
  await client.putFileContents(tmp, data);
  await client.moveFile(tmp, path);
}
```

---

## src/lib/models.ts
```ts
export type DevicePub = { deviceId: string; userId: string; pub: string; createdAt: string };
export type MessagePayload = { id: string; title: string; body: string; route?: string; createdAt: string; ttl?: string };
export type CipherRecord = {
  id: string;
  v: number;
  alg: string;            // z. B. xchacha20poly1305
  nonce: string;          // base64
  ciphertext: string;     // base64
  perDevice: { deviceId: string; userId: string; wrapped: string }[]; // base64
  aad?: Record<string, unknown>;
};

export type VacationRequest = {
  id: string;
  userId: string;
  from: string; // ISO
  to: string;   // ISO
  reason?: string;
  createdAt: string;
};

export type VacationDecision = { id: string; requestId: string; status: 'approved' | 'rejected'; decidedBy: string; decidedAt: string; comment?: string };
```

---

## src/lib/crypto.ts (E2E Utils)
```ts
import sodium from 'libsodium-wrappers-sumo';

export async function initCrypto() { await sodium.ready; }
export function randomKey32() { return sodium.randombytes_buf(32); }

export function encryptAEAD(sk: Uint8Array, plaintext: Uint8Array, aad?: Uint8Array) {
  const nonce = sodium.randombytes_buf(24);
  const ct = sodium.crypto_aead_xchacha20poly1305_ietf_encrypt(plaintext, aad ?? null, null, nonce, sk);
  return { nonce, ct };
}

export function decryptAEAD(sk: Uint8Array, nonce: Uint8Array, ciphertext: Uint8Array, aad?: Uint8Array) {
  return sodium.crypto_aead_xchacha20poly1305_ietf_decrypt(null, ciphertext, aad ?? null, nonce, sk);
}

export function wrapSKForDevice(devicePubB64: string, sk: Uint8Array) {
  const pub = sodium.from_base64(devicePubB64, sodium.base64_variants.ORIGINAL);
  const sealed = sodium.crypto_box_seal(sk, pub);
  return sodium.to_base64(sealed, sodium.base64_variants.ORIGINAL);
}

export function generateDeviceKeypairB64() {
  const kp = sodium.crypto_box_keypair();
  return {
    publicKeyB64: sodium.to_base64(kp.publicKey, sodium.base64_variants.ORIGINAL),
    secretKeyB64: sodium.to_base64(kp.privateKey, sodium.base64_variants.ORIGINAL)
  };
}

export function unwrapSKForDevice(deviceSecretKeyB64: string, wrappedB64: string) {
  const sk = sodium.from_base64(deviceSecretKeyB64, sodium.base64_variants.ORIGINAL);
  const wrapped = sodium.from_base64(wrappedB64, sodium.base64_variants.ORIGINAL);
  const pk = sodium.crypto_scalarmult_base(sk);
  const unsealed = sodium.crypto_box_seal_open(wrapped, pk, sk);
  return unsealed; // 32‑Byte Session Key
}
```

---

## src/renderer/index.html
```html
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Admin‑Konsole (HiDrive‑only)</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="./index.tsx"></script>
  </body>
</html>
```

---

## src/renderer/index.tsx
```tsx
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';

const root = createRoot(document.getElementById('root')!);
root.render(<App />);
```

---

## src/renderer/App.tsx
```tsx
import React, { useState } from 'react';
import Settings from './components/Settings';
import MessageComposer from './components/MessageComposer';
import TeamManager from './components/TeamManager';
import VacationBoard from './components/VacationBoard';

export default function App() {
  const [tab, setTab] = useState<'msg'|'team'|'vac'|'cfg'>('msg');
  return (
    <div style={{fontFamily:'Inter, system-ui', padding:16}}>
      <h1>Admin‑Konsole (HiDrive‑only)</h1>
      <nav style={{display:'flex', gap:12}}>
        <button onClick={()=>setTab('msg')}>Nachrichten</button>
        <button onClick={()=>setTab('team')}>Team</button>
        <button onClick={()=>setTab('vac')}>Urlaub</button>
        <button onClick={()=>setTab('cfg')}>Einstellungen</button>
      </nav>
      <div style={{marginTop:16}}>
        {tab==='msg' && <MessageComposer/>}
        {tab==='team' && <TeamManager/>}
        {tab==='vac' && <VacationBoard/>}
        {tab==='cfg' && <Settings/>}
      </div>
    </div>
  );
}
```

---

## src/renderer/components/Settings.tsx
```tsx
import React, { useEffect, useState } from 'react';

declare global { interface Window { api: any } }

export default function Settings(){
  const [url, setUrl] = useState('');
  const [user, setUser] = useState('');
  const [pass, setPass] = useState('');
  const [status, setStatus] = useState<string>('');

  useEffect(() => { (async () => {
    const cfg = await window.api.configGet();
    setUrl(cfg.url || '');
    setUser(cfg.user || '');
  })(); }, []);

  async function save(){
    try {
      await window.api.configSet({ url, user, pass: pass || undefined });
      setStatus('Gespeichert');
      setPass('');
    } catch(e:any){ setStatus(e?.message || 'Fehler beim Speichern'); }
  }

  async function check(){
    const r = await window.api.hidriveCheck();
    setStatus(r.ok ? 'Verbindung OK' : `Fehler: ${r.error}`);
  }

  async function reset(){
    await window.api.configClear();
    setUrl(''); setUser(''); setPass(''); setStatus('Zurückgesetzt');
  }

  return (
    <div style={{display:'grid', gap:8, maxWidth:520}}>
      <h2>Einstellungen</h2>
      <label>HiDrive URL
        <input placeholder="https://webdav.hidrive.strato.com/" value={url} onChange={e=>setUrl(e.target.value)} />
      </label>
      <label>Benutzername
        <input value={user} onChange={e=>setUser(e.target.value)} />
      </label>
      <label>Passwort (leer lassen = unverändert)
        <input type="password" value={pass} onChange={e=>setPass(e.target.value)} />
      </label>
      <div style={{display:'flex', gap:8}}>
        <button onClick={save}>Speichern</button>
        <button onClick={check}>Verbindung testen</button>
        <button onClick={reset}>Zurücksetzen</button>
      </div>
      <small>{status}</small>
    </div>
  );
}
```

---

## src/renderer/components/MessageComposer.tsx
```tsx
import React, { useState } from 'react';

declare global { interface Window { api: any } }

export default function MessageComposer(){
  const [userId, setUserId] = useState('');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [devices, setDevices] = useState<any[]>([]);

  async function loadDevices(){
    if (!userId) return;
    const res = await window.api.listDevices(userId);
    setDevices(res);
  }

  async function send(){
    if (!userId || !title) return;
    const payload = { id: crypto.randomUUID(), title, body, createdAt: new Date().toISOString() };
    const params = { targets: [{ userId }], payload, devices: { [userId]: devices } };
    await window.api.sendMessage(params);
    alert('Gesendet');
  }

  return (
    <div>
      <h2>Nachricht senden</h2>
      <div style={{display:'grid', gap:8, maxWidth:480}}>
        <input placeholder="Ziel UserID" value={userId} onChange={e=>setUserId(e.target.value)} />
        <button onClick={loadDevices}>Geräte laden</button>
        <input placeholder="Titel (neutral)" value={title} onChange={e=>setTitle(e.target.value)} />
        <textarea placeholder="Inhalt (verschlüsselt gespeichert)" value={body} onChange={e=>setBody(e.target.value)} />
        <button onClick={send} disabled={!userId || !title}>Senden</button>
      </div>
      <small>{devices.length} Geräte gefunden</small>
    </div>
  );
}
```

---

## src/renderer/components/TeamManager.tsx (Stub)
```tsx
import React from 'react';
export default function TeamManager(){
  return <div>
    <h2>Team & Mitarbeiter</h2>
    <p>Hier kannst du später verschlüsselte Stammdaten/ACLs in HiDrive pflegen (UUID‑Dateien, E2E).</p>
  </div>;
}
```

---

## src/renderer/components/VacationBoard.tsx (Stub)
```tsx
import React, { useState } from 'react';

declare global { interface Window { api: any } }

export default function VacationBoard(){
  const [userId, setUserId] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');

  async function createReq(){
    await window.api.createVacationRequest({ userId, from, to, createdAt: new Date().toISOString() });
    alert('Antrag erstellt (verschlüsselte Ablage empfohlen!)');
  }

  return <div>
    <h2>Urlaubsplanung</h2>
    <div style={{display:'grid', gap:8, maxWidth:420}}>
      <input placeholder="UserID" value={userId} onChange={e=>setUserId(e.target.value)} />
      <input type="date" value={from} onChange={e=>setFrom(e.target.value)} />
      <input type="date" value={to} onChange={e=>setTo(e.target.value)} />
      <button onClick={createReq}>Antrag anlegen</button>
    </div>
  </div>;
}
```

---

## Tests (Vitest) – bestehende beibehalten, **neue Smoke‑Tests ergänzt**

### src/__tests__/crypto.test.ts (unverändert)
```ts
import { describe, it, expect, beforeAll } from 'vitest';
import { initCrypto, randomKey32, encryptAEAD, decryptAEAD, generateDeviceKeypairB64, wrapSKForDevice, unwrapSKForDevice } from '../lib/crypto';

beforeAll(async () => { await initCrypto(); });

describe('AEAD roundtrip', () => {
  it('encrypt/decrypt returns original', () => {
    const key = randomKey32();
    const pt = new TextEncoder().encode('hello');
    const aad = new TextEncoder().encode('{"t":1}');
    const { nonce, ct } = encryptAEAD(key, pt, aad);
    const out = decryptAEAD(key, nonce, ct, aad);
    expect(new TextDecoder().decode(out)).toBe('hello');
  });
});

describe('Device wrap/unwrap', () => {
  it('wrapSKForDevice + unwrapSKForDevice matches', () => {
    const { publicKeyB64, secretKeyB64 } = generateDeviceKeypairB64();
    const session = randomKey32();
    const wrapped = wrapSKForDevice(publicKeyB64, session);
    const unwrapped = unwrapSKForDevice(secretKeyB64, wrapped);
    expect(Buffer.from(unwrapped)).toStrictEqual(Buffer.from(session));
  });
});
```

### src/__tests__/config.test.ts (unverändert)
```ts
import { describe, it, expect } from 'vitest';

describe('config url validator', () => {
  it('rejects invalid url', () => {
    const bad = 'not-a-url';
    let ok = true;
    try { new URL(bad); } catch { ok = false; }
    expect(ok).toBe(false);
  });
  it('accepts https url', () => {
    const good = new URL('https://webdav.hidrive.strato.com/');
    expect(good.protocol).toBe('https:');
  });
});
```

### src/__tests__/renderer.smoke.test.ts (**neu**) – stellt sicher, dass **TSX/JSX** gerendert werden kann
```ts
import { describe, it, expect } from 'vitest';
import React from 'react';
import { createRoot } from 'react-dom/client';

// JSX Smoke: wenn TSX nicht transpiliert, knallt das schon beim Import
function Hello(){ return <div>Hello</div>; }

describe('renderer jsx smoke', () => {
  it('renders a trivial component without syntax errors', () => {
    const el = document.createElement('div');
    const root = createRoot(el);
    root.render(<Hello/>);
    expect(el.innerHTML).toContain('Hello');
  });
});
```

**Ausführen der Tests:** `pnpm test`

---

## Start & Build
- **Dev:**
  ```bash
  pnpm i
  pnpm dev
  ```
  Öffnet Electron und lädt den React‑Renderer via Vite‑Dev‑Server. TSX wird transpiliert → **kein** `Unexpected token` mehr.

- **Build:**
  ```bash
  pnpm build
  pnpm preview   # optional: Renderer‑Preview
  ```

---

## Wichtige Hinweise / Troubleshooting
- Stelle sicher, dass du **nicht** `electron .` verwendest. Nutze **`electron-vite dev`** via `pnpm dev`, damit der Renderer durch Vite transpiliert wird.
- Wenn du zuvor eine `index.tsx` im Projekt‑Root hattest: **umbenennen/verschieben** nach `src/renderer/index.tsx`. Sonst könnte ein alter Pfad weiter versucht werden.
- Bei Problemen mit `keytar` auf Linux: `libsecret` installieren (z. B. `sudo apt install libsecret-1-dev`) und ggf. `npx electron-rebuild` ausführen.
- Native ESM: Alle Imports ohne Dateiendung funktionieren mit Vite. In Node‑Only‑Skripten bleib bei relativen Pfaden ohne `.ts`‑Endung.

---

## Rückfrage (kurz)
Stimmt das erwartete Verhalten so?  
- **Dev:** App startet, zeigt Tabs („Nachrichten/Team/Urlaub/Einstellungen“).  
- **Fehlerfrei:** Kein `Unexpected token` mehr beim Laden von `index.tsx`.  
Falls du einen anderen **Start‑Workflow** erwartest (z. B. `electron .` ohne Bundler), sag Bescheid – dann passe ich die Struktur darauf an (mit esbuild/tsup + Babel für JSX).
