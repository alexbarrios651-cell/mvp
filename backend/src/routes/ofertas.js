import { Router } from 'express';
import { read, write } from '../util/db.js';
import { requireAuth } from '../middleware/auth.js';
import { nanoid } from 'nanoid';

const router = Router();
router.use(requireAuth);

router.post('/', (req, res) => {
  if (req.user.rol !== 'proveedor') return res.status(403).json({ error: 'solo proveedor' });
  const { idSolicitud, precio, tiempoEstimado, mensaje } = req.body || {};
  if (!idSolicitud || precio == null || !tiempoEstimado) return res.status(400).json({ error: 'faltan campos' });
  const ofertas = read('ofertas');
  const o = { id: nanoid(), idSolicitud, idProveedor: req.user.id, precio, tiempoEstimado, mensaje: mensaje||'', estado: 'activa', createdAt: new Date().toISOString() };
  ofertas.push(o);
  write('ofertas', ofertas);
  res.status(201).json(o);
});

router.post('/:id/aceptar', (req, res) => {
  // Solo el cliente dueño de la solicitud puede aceptar
  const ofertas = read('ofertas');
  const solicitudes = read('solicitudes');
  const o = ofertas.find(x => x.id === req.params.id);
  if (!o) return res.status(404).json({ error: 'no encontrada' });
  const s = solicitudes.find(y => y.id === o.idSolicitud);
  if (!s || s.idCliente !== req.user.id) return res.status(403).json({ error: 'no autorizado' });
  // marcar aceptada y otras rechazadas
  ofertas.forEach(x => { if (x.idSolicitud === s.id) x.estado = (x.id === o.id ? 'aceptada' : 'rechazada'); });
  s.estado = 'asignada';
  write('ofertas', ofertas);
  write('solicitudes', solicitudes);
  res.json({ ok: true });
});

export default router;
