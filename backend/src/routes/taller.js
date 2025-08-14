import { Router } from 'express';
import { read, upsert } from '../util/db.js';
import { requireAuth } from '../middleware/auth.js';
import { nanoid } from 'nanoid';

const router = Router();
router.use(requireAuth);

router.get('/', (req, res) => {
  const talleres = read('talleres');
  const t = talleres.find(x => x.idUser === req.user.id);
  res.json(t || null);
});

router.put('/', (req, res) => {
  if (req.user.rol !== 'proveedor') return res.status(403).json({ error: 'solo proveedor' });
  const talleres = read('talleres');
  let t = talleres.find(x => x.idUser === req.user.id) || { id: nanoid(), idUser: req.user.id };
  t = { ...t, ...req.body, especialidades: req.body.especialidades || [], reputacion: t.reputacion || { avg: 0, count: 0 } };
  upsert('talleres', t, 'id');
  res.json(t);
});

export default router;
