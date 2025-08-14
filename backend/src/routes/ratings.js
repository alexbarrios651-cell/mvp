import { Router } from 'express';
import { read, write } from '../util/db.js';
import { requireAuth } from '../middleware/auth.js';
import { nanoid } from 'nanoid';

const router = Router();
router.use(requireAuth);

router.post('/', (req, res) => {
  const { idSolicitud, toUser, puntaje, comentario } = req.body || {};
  if (!idSolicitud || !toUser || !puntaje) return res.status(400).json({ error: 'faltan campos' });
  const ratings = read('ratings');
  const r = { id: nanoid(), idSolicitud, fromUser: req.user.id, toUser, puntaje, comentario: comentario || '', createdAt: new Date().toISOString() };
  ratings.push(r);
  write('ratings', ratings);
  // actualizar reputación si es a un taller
  const talleres = read('talleres');
  const t = talleres.find(x => x.idUser === toUser);
  if (t) {
    t.reputacion = t.reputacion || { avg: 0, count: 0 };
    const all = ratings.filter(x => x.toUser === toUser);
    const avg = all.reduce((a,b)=>a + (b.puntaje||0), 0) / (all.length||1);
    t.reputacion.avg = Math.round(avg * 10)/10;
    t.reputacion.count = all.length;
    write('talleres', talleres);
  }
  res.status(201).json(r);
});

export default router;
