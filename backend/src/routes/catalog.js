import { Router } from 'express';
import fs from 'fs';
import path from 'path';
const router = Router();

router.get('/specialties', (req, res) => {
  const p = path.resolve(process.cwd(), 'backend', 'data', 'specialties.json');
  const txt = fs.readFileSync(p, 'utf-8');
  res.json(JSON.parse(txt));
});

export default router;
