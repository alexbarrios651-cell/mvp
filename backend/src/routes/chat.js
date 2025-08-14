import { Router } from 'express';
import { read, write } from '../util/db.js';
import { requireAuth } from '../middleware/auth.js';
import { nanoid } from 'nanoid';

const router = Router();
router.use(requireAuth);

router.get('/:idSolicitud', (req, res) => {
  const mensajes = read('mensajes').filter(m => m.idSolicitud === req.params.idSolicitud);
  res.json(mensajes);
});

router.post('/:idSolicitud', (req, res) => {
  const { texto, archivoUrl } = req.body || {};
  if (!texto && !archivoUrl) return res.status(400).json({ error: 'texto o archivoUrl requerido' });
  const m = { id: nanoid(), idSolicitud: req.params.idSolicitud, from: req.user.rol, texto: texto||'', archivoUrl: archivoUrl||'', createdAt: new Date().toISOString() };
  const mensajes = read('mensajes');
  mensajes.push(m);
  write('mensajes', mensajes);
  res.status(201).json(m);
});

export default router;
