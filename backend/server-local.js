// ============================================================
// AeroSense — Local Backend (SQLite)
// Works on any network — no internet required.
// Use this on college / restricted networks.
// For MongoDB Atlas use: node server.js (needs open internet)
// ============================================================
require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const Database = require('better-sqlite3');
const path    = require('path');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors({ origin: '*' }));
app.use(express.json());

// ── SQLite setup ───────────────────────────────────────────────
const DB_PATH = path.join(__dirname, 'aerosense.db');
const db = new Database(DB_PATH);

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id         TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    email      TEXT UNIQUE NOT NULL,
    password   TEXT NOT NULL,
    phone      TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS aqi_records (
    id          TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    aqi_score   REAL NOT NULL,
    status      TEXT NOT NULL,
    temperature REAL DEFAULT 0,
    humidity    REAL DEFAULT 0,
    co2         REAL DEFAULT 0,
    voc         REAL DEFAULT 0,
    recorded_at TEXT NOT NULL DEFAULT (datetime('now')),
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS user_settings (
    user_id              TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    language             TEXT DEFAULT 'english',
    dark_mode            INTEGER DEFAULT 0,
    temperature_unit     TEXT DEFAULT 'celsius',
    notif_status_changes INTEGER DEFAULT 1,
    notif_danger_alerts  INTEGER DEFAULT 1,
    notif_analysis_saved INTEGER DEFAULT 1,
    notif_live_updates   INTEGER DEFAULT 1,
    updated_at           TEXT DEFAULT (datetime('now'))
  );

  CREATE INDEX IF NOT EXISTS idx_records_user   ON aqi_records(user_id, recorded_at DESC);
  CREATE INDEX IF NOT EXISTS idx_records_status ON aqi_records(user_id, status);
`);

console.log('✅ SQLite database ready:', DB_PATH);
console.log('✅ Tables: users, aqi_records, user_settings');
console.log('🎉 Database fully initialised — no internet needed!\n');

// ── Helpers ────────────────────────────────────────────────────
const { randomUUID } = require('crypto');

const JWT_SECRET  = process.env.JWT_SECRET  || 'aerosense_local_secret_2024';
const JWT_EXPIRES = process.env.JWT_EXPIRES_IN || '30d';

const signToken   = (id) => jwt.sign({ sub: id }, JWT_SECRET, { expiresIn: JWT_EXPIRES });
const verifyToken = (t)  => jwt.verify(t, JWT_SECRET);
const apiErr      = (res, status, msg) => res.status(status).json({ error: msg });

function authenticate(req, res, next) {
  const header = req.headers['authorization'] || '';
  const token  = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return apiErr(res, 401, 'No token provided');
  try {
    req.userId = verifyToken(token).sub;
    next();
  } catch {
    apiErr(res, 401, 'Invalid or expired token');
  }
}

// ── HEALTH ─────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status   : 'ok',
    db       : 'connected',
    db_ready : true,
    db_type  : 'SQLite (local)',
    db_name  : 'aerosense',
    timestamp: new Date().toISOString(),
    version  : '2.0.0',
  });
});

// ── AUTH ───────────────────────────────────────────────────────

// POST /api/auth/register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name?.trim() || !email?.trim() || !password)
      return apiErr(res, 400, 'name, email and password are required');
    if (password.length < 6)
      return apiErr(res, 400, 'Password must be at least 6 characters');

    const clean = email.toLowerCase().trim();
    const exists = db.prepare('SELECT id FROM users WHERE email = ?').get(clean);
    if (exists) return apiErr(res, 409, 'Email already registered');

    const hash = await bcrypt.hash(password, 12);
    const id   = randomUUID();
    db.prepare('INSERT INTO users (id, name, email, password) VALUES (?,?,?,?)')
      .run(id, name.trim(), clean, hash);

    // Create default settings for new user
    db.prepare('INSERT OR IGNORE INTO user_settings (user_id) VALUES (?)').run(id);

    const token = signToken(id);
    res.status(201).json({ token, user: { id, name: name.trim(), email: clean } });
  } catch (e) {
    console.error('register error:', e.message);
    if (e.message?.includes('UNIQUE')) return apiErr(res, 409, 'Email already registered');
    apiErr(res, 500, 'Server error during registration');
  }
});

// POST /api/auth/login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email?.trim() || !password)
      return apiErr(res, 400, 'email and password are required');

    const user = db.prepare('SELECT * FROM users WHERE email = ?')
                   .get(email.toLowerCase().trim());
    if (!user || !(await bcrypt.compare(password, user.password)))
      return apiErr(res, 401, 'Invalid email or password');

    const token = signToken(user.id);
    res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
  } catch (e) {
    console.error('login error:', e.message);
    apiErr(res, 500, 'Server error during login');
  }
});

// GET /api/auth/me
app.get('/api/auth/me', authenticate, (req, res) => {
  const user = db.prepare('SELECT id, name, email, created_at FROM users WHERE id = ?')
                 .get(req.userId);
  if (!user) return apiErr(res, 404, 'User not found');
  res.json({ user });
});

// PUT /api/auth/profile
app.put('/api/auth/profile', authenticate, (req, res) => {
  const { name } = req.body;
  if (!name?.trim() || name.trim().length < 2)
    return apiErr(res, 400, 'Name must be at least 2 characters');
  db.prepare('UPDATE users SET name = ? WHERE id = ?').run(name.trim(), req.userId);
  res.json({ message: 'Profile updated', name: name.trim() });
});

// PUT /api/auth/reset-password
app.put('/api/auth/reset-password', async (req, res) => {
  try {
    const { email, new_password } = req.body;
    if (!email?.trim() || !new_password)
      return apiErr(res, 400, 'email and new_password are required');
    if (new_password.length < 6)
      return apiErr(res, 400, 'Password must be at least 6 characters');

    const user = db.prepare('SELECT id FROM users WHERE email = ?')
                   .get(email.toLowerCase().trim());
    if (!user) return apiErr(res, 404, 'No account found with that email');

    const hash = await bcrypt.hash(new_password, 12);
    db.prepare('UPDATE users SET password = ? WHERE id = ?').run(hash, user.id);
    res.json({ message: 'Password reset successful' });
  } catch (e) {
    console.error('reset-password error:', e.message);
    apiErr(res, 500, 'Server error');
  }
});

// ── AQI RECORDS ────────────────────────────────────────────────

// GET /api/records
app.get('/api/records', authenticate, (req, res) => {
  const records = db.prepare(
    'SELECT * FROM aqi_records WHERE user_id = ? ORDER BY recorded_at DESC'
  ).all(req.userId);
  res.json({ records, count: records.length });
});

// GET /api/records/latest
app.get('/api/records/latest', authenticate, (req, res) => {
  const record = db.prepare(
    'SELECT * FROM aqi_records WHERE user_id = ? ORDER BY recorded_at DESC LIMIT 1'
  ).get(req.userId);
  res.json({ record: record || null });
});

// POST /api/records
app.post('/api/records', authenticate, (req, res) => {
  const { id, aqi_score, status, temperature, humidity, co2, voc, recorded_at } = req.body;
  if (!id || aqi_score == null || !status)
    return apiErr(res, 400, 'id, aqi_score and status are required');

  db.prepare(`
    INSERT INTO aqi_records (id, user_id, aqi_score, status, temperature, humidity, co2, voc, recorded_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      aqi_score = excluded.aqi_score, status = excluded.status,
      temperature = excluded.temperature, humidity = excluded.humidity,
      co2 = excluded.co2, voc = excluded.voc,
      recorded_at = excluded.recorded_at
  `).run(id, req.userId, aqi_score, status,
         temperature ?? 0, humidity ?? 0, co2 ?? 0, voc ?? 0,
         recorded_at ?? new Date().toISOString());

  res.status(201).json({ message: 'Record saved', id });
});

// DELETE /api/records/:id
app.delete('/api/records/:id', authenticate, (req, res) => {
  const result = db.prepare(
    'DELETE FROM aqi_records WHERE id = ? AND user_id = ?'
  ).run(req.params.id, req.userId);
  if (result.changes === 0) return apiErr(res, 404, 'Record not found');
  res.json({ message: 'Record deleted' });
});

// DELETE /api/records
app.delete('/api/records', authenticate, (req, res) => {
  const result = db.prepare('DELETE FROM aqi_records WHERE user_id = ?').run(req.userId);
  res.json({ message: 'All records cleared', deleted: result.changes });
});

// ── START ──────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`🚀 AeroSense API running on http://localhost:${PORT}`);
  console.log(`   Health check: http://localhost:${PORT}/health\n`);
});
