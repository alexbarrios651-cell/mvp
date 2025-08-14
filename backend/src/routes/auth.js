import { Router } from 'express';
import { read, write } from '../util/db.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { nanoid } from 'nanoid';

const router = Router();

router.post('/register', async (req, res) => {
  const { nombre, email, password, rol } = req.body || {};
  if (!email || !password || !rol) return res.status(400).json({ error: 'email, password y rol requeridos' });
  const users = read('users');
  if (users.find(u => u.email === email)) return res.status(409).json({ error: 'Email ya existe' });
  const hash = await bcrypt.hash(password, 10);
  const user = { id: nanoid(), nombre: nombre || '', email, password: hash, rol, telefono: '', fotoUrl: '', direccion: '', geo: null };
  users.push(user);
  write('users', users);
  const token = jwt.sign({ id: user.id, email, rol }, process.env.JWT_SECRET || 'supersecreto', { expiresIn: '7d' });
  res.status(201).json({ token, user: { ...user, password: undefined } });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body || {};
  const users = read('users');
  const user = users.find(u => u.email === email);
  if (!user) return res.status(401).json({ error: 'Credenciales' });
  const ok = await bcrypt.compare(password, user.password);
  if (!ok) return res.status(401).json({ error: 'Credenciales' });
  const token = jwt.sign({ id: user.id, email: user.email, rol: user.rol }, process.env.JWT_SECRET || 'supersecreto', { expiresIn: '7d' });
  res.json({ token, user: { ...user, password: undefined } });
});

router.get('/me', (req, res) => {
  // This endpoint requires token in Authorization header; we decode directly for MVP
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'No token' });
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'supersecreto');
    const users = read('users');
    const user = users.find(u => u.id === payload.id);
    res.json({ ...user, password: undefined });
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
});

export default router;
