import fs from 'fs';
import path from 'path';
const DATA_DIR = path.resolve(process.cwd(), 'backend', 'data');

const files = {
  users: 'users.json',
  talleres: 'talleres.json',
  vehiculos: 'vehiculos.json',
  solicitudes: 'solicitudes.json',
  ofertas: 'ofertas.json',
  mensajes: 'mensajes.json',
  ratings: 'ratings.json',
  specialties: 'specialties.json'
};

export function ensureDataFiles() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  for (const f of Object.values(files)) {
    const p = path.join(DATA_DIR, f);
    if (!fs.existsSync(p)) fs.writeFileSync(p, '[]', 'utf-8');
  }
}

export function read(name) {
  const p = path.join(DATA_DIR, files[name]);
  return JSON.parse(fs.readFileSync(p, 'utf-8') || '[]');
}

export function write(name, data) {
  const p = path.join(DATA_DIR, files[name]);
  fs.writeFileSync(p, JSON.stringify(data, null, 2));
}

export function upsert(name, obj, key='id') {
  const arr = read(name);
  const idx = arr.findIndex(x => x[key] === obj[key]);
  if (idx >= 0) { arr[idx] = obj; } else { arr.push(obj); }
  write(name, arr);
  return obj;
}
