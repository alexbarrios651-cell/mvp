import { Router } from 'express';
import { read, write } from '../util/db.js';
import { requireAuth } from '../middleware/auth.js';
import { nanoid } from 'nanoid';

function haversine(lat1, lon1, lat2, lon2) {
  function toRad(d){return d*Math.PI/180;}
  const R=6371;
  const dLat=toRad(lat2-lat1), dLon=toRad(lon2-lon1);
  const a=Math.sin(dLat/2)**2+Math.cos(toRad(lat1))*Math.cos(toRad(lat2))*Math.sin(dLon/2)**2;
  return 2*R*Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
}

const router = Router();
router.use(requireAuth);

router.get('/', (req, res) => {
  const { rol, near, especialidad } = req.query;
  const solicitudes = read('solicitudes');
  if (rol === 'cliente') {
    return res.json(solicitudes.filter(s => s.idCliente === req.user.id));
  }
  if (rol === 'proveedor') {
    // listar asignadas al proveedor (cuando su oferta fue aceptada)
    const ofertas = read('ofertas').filter(o => o.idProveedor === req.user.id && o.estado === 'aceptada');
    const ids = new Set(ofertas.map(o => o.idSolicitud));
    return res.json(solicitudes.filter(s => ids.has(s.id)));
  }
  // búsqueda por cercanía para proveedores: near=lat,lng
  if (near && especialidad) {
    const [lat, lng] = near.split(',').map(Number);
    const candidatos = solicitudes.filter(s => s.estado === 'abierta' && s.especialidad === especialidad);
    const ordenados = candidatos.map(s => {
      const d = haversine(lat, lng, s.geo.lat, s.geo.lng);
      return { s, d };
    }).sort((a,b)=>a.d-b.d).map(x=>x.s);
    return res.json(ordenados);
  }
  res.json(solicitudes);
});

router.post('/', (req, res) => {
  const { idVehiculo, especialidad, sintomas, fotos, geo } = req.body || {};
  if (!idVehiculo || !especialidad || !sintomas || !geo) return res.status(400).json({ error: 'faltan campos' });
  const s = {
    id: nanoid(),
    idCliente: req.user.id,
    idVehiculo,
    especialidad,
    sintomas,
    fotos: fotos || [],
    geo,
    estado: 'abierta',
    createdAt: new Date().toISOString()
  };
  const solicitudes = read('solicitudes');
  solicitudes.push(s);
  write('solicitudes', solicitudes);
  res.status(201).json(s);
});

export default router;
