import { Router } from 'express';
import { read, write } from '../util/db.js';
import { requireAuth } from '../middleware/auth.js';
import { nanoid } from 'nanoid';

const router = Router();
router.use(requireAuth);

router.get('/', (req, res) => {
  const all = read('vehiculos').filter(v => v.idCliente === req.user.id);
  res.json(all);
});

router.post('/', (req, res) => {
  const { marca, modelo, anio, patente, notas } = req.body || {};
  if (!marca || !modelo || !anio) return res.status(400).json({ error: 'marca, modelo, anio requeridos' });
  const vehiculos = read('vehiculos');
  const v = { id: nanoid(), idCliente: req.user.id, marca, modelo, anio, patente: patente || '', notas: notas || '' };
  vehiculos.push(v);
  write('vehiculos', vehiculos);
  res.status(201).json(v);
});

router.put('/:id', (req, res) => {
  const vehiculos = read('vehiculos');
  const idx = vehiculos.findIndex(v => v.id === req.params.id && v.idCliente === req.user.id);
  if (idx < 0) return res.status(404).json({ error: 'no encontrado' });
  vehiculos[idx] = { ...vehiculos[idx], ...req.body };
  write('vehiculos', vehiculos);
  res.json(vehiculos[idx]);
});

export default router;
