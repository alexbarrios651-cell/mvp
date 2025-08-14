import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { ensureDataFiles } from './util/db.js';
import authRouter from './routes/auth.js';
import vehiculosRouter from './routes/vehiculos.js';
import tallerRouter from './routes/taller.js';
import solicitudesRouter from './routes/solicitudes.js';
import ofertasRouter from './routes/ofertas.js';
import chatRouter from './routes/chat.js';
import ratingsRouter from './routes/ratings.js';
import catalogRouter from './routes/catalog.js';

dotenv.config();
ensureDataFiles();

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.get('/api/health', (_, res) => res.json({ ok: true }));

app.use('/api/auth', authRouter);
app.use('/api/vehiculos', vehiculosRouter);
app.use('/api/taller', tallerRouter);
app.use('/api/solicitudes', solicitudesRouter);
app.use('/api/ofertas', ofertasRouter);
app.use('/api/chat', chatRouter);
app.use('/api/ratings', ratingsRouter);
app.use('/api/catalog', catalogRouter);

const port = process.env.PORT || 4000;
// Bind to all interfaces for accessibility on LAN. Es necesario para
// permitir conexiones desde dispositivos móviles en la misma red.
app.listen(port, '0.0.0.0', () => console.log('API listening on', port));
