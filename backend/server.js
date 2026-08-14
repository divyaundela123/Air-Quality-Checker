// ============================================================
// AeroSense — Backend API v6  (Supabase / PostgreSQL)
//
// Uses Supabase over HTTPS (port 443) — works on ALL networks
// including college/restricted internet.
// Same API endpoints — app flow unchanged.
// ============================================================

require('dotenv').config();

const express        = require('express');
const cors           = require('cors');
const bcrypt         = require('bcryptjs');
const jwt            = require('jsonwebtoken');
const { createClient } = require('@supabase/supabase-js');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors({ origin: '*' }));
app.use(express.json());

// ── Supabase client (service_role key — bypasses RLS) ─────────
const SUPABASE_URL  = process.env.SUPABASE_URL;
const SUPABASE_KEY  = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.log('⚠️ SUPABASE_URL / SUPABASE_SERVICE_KEY not set. Using SQLite local server mode...');
  require('./server-local.js');
  return;
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY, {
  auth: { persistSession: false },
});

// ── JWT ────────────────────────────────────────────────────────
const JWT_SECRET  = process.env.JWT_SECRET  || 'aerosense_secret_2024';
const JWT_EXPIRES = process.env.JWT_EXPIRES_IN || '30d';

const signToken = (id)  => jwt.sign({ sub: id }, JWT_SECRET, { expiresIn: JWT_EXPIRES });
const apiErr    = (res, status, msg) => res.status(status).json({ error: msg });

function authenticate(req, res, next) {
  const header = req.headers['authorization'] || '';
  const token  = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return apiErr(res, 401, 'No token provided');
  try {
    req.userId = jwt.verify(token, JWT_SECRET).sub;
    next();
  } catch {
    apiErr(res, 401, 'Invalid or expired token');
  }
}

// ── Supabase helper — throws on error ─────────────────────────
async function sbQuery(promise) {
  const { data, error } = await promise;
  if (error) throw new Error(error.message);
  return data;
}

// ══════════════════════════════════════════════════════════════
// ROUTES
// ══════════════════════════════════════════════════════════════

// ── HEALTH ─────────────────────────────────────────────────────
app.get('/health', async (req, res) => {
  try {
    // Ping Supabase with a lightweight query
    const { error } = await supabase.from('users').select('id').limit(1);
    const ok = !error;
    res.json({
      status   : 'ok',
      db       : ok ? 'connected' : 'error',
      db_ready : ok,
      db_type  : 'Supabase (PostgreSQL)',
      db_name  : 'aerosense',
      timestamp: new Date().toISOString(),
      version  : '6.0.0',
    });
  } catch {
    res.json({ status: 'ok', db: 'error', db_ready: false,
      db_type: 'Supabase', timestamp: new Date().toISOString() });
  }
});

// ── POST /api/auth/register ────────────────────────────────────
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    console.log(`📝 Register attempt: name="${name}", email="${email}"`);

    if (!name?.trim() || !email?.trim() || !password)
      return apiErr(res, 400, 'name, email and password are required');
    if (password.length < 6)
      return apiErr(res, 400, 'Password must be at least 6 characters');

    const clean = email.toLowerCase().trim();

    // Check existing
    const existing = await sbQuery(
      supabase.from('users').select('id').eq('email', clean).maybeSingle()
    );
    if (existing) {
      console.log(`⚠️  Register: email already exists: ${clean}`);
      return apiErr(res, 409, 'Email already registered');
    }

    // Create user
    const hash = await bcrypt.hash(password, 12);
    console.log(`   Inserting user into Supabase...`);
    const inserted = await sbQuery(
      supabase.from('users')
        .insert({ name: name.trim(), email: clean, password: hash })
        .select('id, name, email')
    );
    console.log(`   Insert result:`, JSON.stringify(inserted));
    const [user] = inserted;
    if (!user) throw new Error('Insert returned no data');

    console.log(`✅ Register success: id=${user.id}, email=${user.email}`);

    // Create default settings
    await supabase.from('user_settings').insert({ user_id: user.id });

    res.status(201).json({ token: signToken(user.id), user: { id: user.id, name: user.name, email: user.email } });
  } catch (e) {
    console.error('❌ register error:', e.message);
    if (e.message?.includes('unique') || e.message?.includes('duplicate'))
      return apiErr(res, 409, 'Email already registered');
    apiErr(res, 500, 'Server error during registration');
  }
});

// ── POST /api/auth/login ───────────────────────────────────────
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email?.trim() || !password) return apiErr(res, 400, 'email and password are required');

    const clean = email.toLowerCase().trim();
    const user  = await sbQuery(
      supabase.from('users').select('*').eq('email', clean).maybeSingle()
    );
    if (!user || !(await bcrypt.compare(password, user.password)))
      return apiErr(res, 401, 'Invalid email or password');

    res.json({ token: signToken(user.id), user: { id: user.id, name: user.name, email: user.email } });
  } catch (e) {
    console.error('login:', e.message);
    apiErr(res, 500, 'Server error during login');
  }
});

// ── GET /api/auth/me ───────────────────────────────────────────
app.get('/api/auth/me', authenticate, async (req, res) => {
  try {
    const user = await sbQuery(
      supabase.from('users').select('id, name, email, created_at').eq('id', req.userId).maybeSingle()
    );
    if (!user) return apiErr(res, 404, 'User not found');
    res.json({ user });
  } catch (e) { apiErr(res, 500, 'Server error'); }
});

// ── PUT /api/auth/profile ──────────────────────────────────────
app.put('/api/auth/profile', authenticate, async (req, res) => {
  try {
    const { name } = req.body;
    if (!name?.trim() || name.trim().length < 2)
      return apiErr(res, 400, 'Name must be at least 2 characters');
    await sbQuery(
      supabase.from('users').update({ name: name.trim() }).eq('id', req.userId)
    );
    res.json({ message: 'Profile updated', name: name.trim() });
  } catch (e) { apiErr(res, 500, 'Server error'); }
});

// ── PUT /api/auth/reset-password ───────────────────────────────
app.put('/api/auth/reset-password', async (req, res) => {
  try {
    const { email, new_password } = req.body;
    if (!email?.trim() || !new_password)
      return apiErr(res, 400, 'email and new_password are required');
    if (new_password.length < 6)
      return apiErr(res, 400, 'Password must be at least 6 characters');

    const clean = email.toLowerCase().trim();
    const user  = await sbQuery(
      supabase.from('users').select('id').eq('email', clean).maybeSingle()
    );
    if (!user) return apiErr(res, 404, 'No account found with that email');

    const hash = await bcrypt.hash(new_password, 12);
    await sbQuery(
      supabase.from('users').update({ password: hash }).eq('id', user.id)
    );
    res.json({ message: 'Password reset successful' });
  } catch (e) {
    console.error('reset-password:', e.message);
    apiErr(res, 500, 'Server error');
  }
});

// ── GET /api/records ───────────────────────────────────────────
app.get('/api/records', authenticate, async (req, res) => {
  try {
    const records = await sbQuery(
      supabase.from('aqi_records')
        .select('*')
        .eq('user_id', req.userId)
        .order('recorded_at', { ascending: false })
    );
    res.json({ records: records || [], count: (records || []).length });
  } catch (e) { apiErr(res, 500, 'Server error fetching records'); }
});

// ── GET /api/records/latest ────────────────────────────────────
app.get('/api/records/latest', authenticate, async (req, res) => {
  try {
    const record = await sbQuery(
      supabase.from('aqi_records')
        .select('*')
        .eq('user_id', req.userId)
        .order('recorded_at', { ascending: false })
        .limit(1)
        .maybeSingle()
    );
    res.json({ record: record || null });
  } catch (e) { apiErr(res, 500, 'Server error'); }
});

// ── POST /api/records ──────────────────────────────────────────
app.post('/api/records', authenticate, async (req, res) => {
  try {
    const { id, aqi_score, status, temperature, humidity, co2, voc, recorded_at } = req.body;
    if (!id || aqi_score == null || !status)
      return apiErr(res, 400, 'id, aqi_score and status are required');

    await sbQuery(
      supabase.from('aqi_records').upsert({
        id,
        user_id    : req.userId,
        aqi_score,
        status,
        temperature: temperature ?? 0,
        humidity   : humidity    ?? 0,
        co2        : co2         ?? 0,
        voc        : voc         ?? 0,
        recorded_at: recorded_at ?? new Date().toISOString(),
      }, { onConflict: 'id' })
    );
    res.status(201).json({ message: 'Record saved', id });
  } catch (e) {
    console.error('post record:', e.message);
    apiErr(res, 500, 'Server error saving record');
  }
});

// ── DELETE /api/records/:id ────────────────────────────────────
app.delete('/api/records/:id', authenticate, async (req, res) => {
  try {
    const result = await sbQuery(
      supabase.from('aqi_records')
        .delete()
        .eq('id', req.params.id)
        .eq('user_id', req.userId)
        .select('id')
    );
    if (!result || result.length === 0) return apiErr(res, 404, 'Record not found');
    res.json({ message: 'Record deleted' });
  } catch (e) { apiErr(res, 500, 'Server error'); }
});

// ── DELETE /api/records ────────────────────────────────────────
app.delete('/api/records', authenticate, async (req, res) => {
  try {
    const result = await sbQuery(
      supabase.from('aqi_records')
        .delete()
        .eq('user_id', req.userId)
        .select('id')
    );
    res.json({ message: 'All records cleared', deleted: (result || []).length });
  } catch (e) { apiErr(res, 500, 'Server error'); }
});

// ── ML PREDICTION PROXY ────────────────────────────────────────
// Proxies to Python Flask ML API on port 5000
const ML_API_URL = process.env.ML_API_URL || 'http://localhost:5000';

// Shared fetch helper — forwards body to ML API and returns JSON
async function mlFetch(endpoint, body, timeoutMs = 8000) {
  const fetch = require('node-fetch').default || require('node-fetch');
  const res   = await fetch(`${ML_API_URL}${endpoint}`, {
    method : 'POST',
    headers: { 'Content-Type': 'application/json' },
    body   : JSON.stringify(body),
    signal : AbortSignal.timeout(timeoutMs),
  });
  if (!res.ok) throw new Error(`ML API ${res.status}`);
  return res.json();
}

// Inline rule-based fallback (used when Python ML API is offline)
function mlFallback(body) {
  const { temperature = 28, humidity = 60, co2 = 500, voc = 100,
          pm25, pm10, no2, so2, o3, co } = body;

  const calcAqi = (t, h, c, v) => {
    const base = (c * 0.05) + (v * 0.2);
    const pen  = (t > 35 ? 30 : 0) + (h > 80 ? 10 : 0);
    return Math.min(Math.max(base + pen, 0), 500);
  };
  const getStatus = (aqi) =>
    aqi <= 50 ? 'Safe' : aqi <= 100 ? 'Moderate' : aqi <= 150 ? 'Warning' : 'Hazardous';

  const currentAqi   = calcAqi(temperature, humidity, co2, voc);
  const predictedAqi = Math.min(currentAqi * 1.03 + 1.5, 500);
  const diff         = parseFloat((predictedAqi - currentAqi).toFixed(1));
  const trend        = Math.abs(diff) < 3 ? 'stable' : diff > 0 ? 'worsening' : 'improving';

  return {
    current_aqi    : parseFloat(currentAqi.toFixed(1)),
    predicted_aqi  : parseFloat(predictedAqi.toFixed(1)),
    prediction_horizon: '1 hour',
    current_status : getStatus(currentAqi),
    predicted_status: getStatus(predictedAqi),
    trend,
    change         : `${diff > 0 ? '+' : ''}${diff} AQI`,
    confidence     : 0.72,
    confidence_pct : '72%',
    alerts: [{ level: 'info', message: 'ℹ️ Rule-based estimate (ML API offline).' }],
    forecast_3h: [1, 2, 3].map(h => ({
      hour          : `+${h}h`,
      predicted_aqi : parseFloat(Math.min(currentAqi + diff * h * 0.6, 500).toFixed(1)),
      status        : getStatus(currentAqi + diff * h * 0.6),
      source        : 'extrapolation',
    })),
    inputs : { temperature, humidity, co2, voc, pm25, pm10, no2, so2, o3, co,
               real_pollutants: !!(pm25 || pm10 || no2 || so2 || o3 || co) },
    model_source   : 'rule_based_fallback',
    mae            : 5.0,
    data_note      : 'ML API offline — rule-based fallback used.',
  };
}

app.post('/api/ml/predict', async (req, res) => {
  try {
    const { temperature, humidity, co2, voc,
            pm25, pm10, no2, so2, o3, co, lat, lon } = req.body;

    // temperature and humidity are still required
    if (temperature == null || humidity == null)
      return apiErr(res, 400, 'temperature and humidity are required');

    const mlData = await mlFetch('/ml/predict', {
      temperature, humidity, co2, voc,
      pm25, pm10, no2, so2, o3, co, lat, lon,
    });
    res.json({ ...mlData, source: 'python_ml_api' });

  } catch (e) {
    console.warn('ML API unavailable, using fallback:', e.message);
    res.json(mlFallback(req.body));
  }
});

// ── ML FUTURE FORECAST ─────────────────────────────────────────
app.post('/api/ml/predict/future', async (req, res) => {
  try {
    const { temperature, humidity } = req.body;
    if (temperature == null || humidity == null)
      return apiErr(res, 400, 'temperature and humidity are required');

    const mlData = await mlFetch('/ml/predict/future', req.body, 12000);
    res.json({ ...mlData, source: 'python_ml_api' });

  } catch (e) {
    console.warn('ML future API unavailable:', e.message);
    // Minimal fallback for future predictions
    const fallback = mlFallback(req.body);
    const hours    = Math.min(parseInt(req.body.hours || 6), 24);
    const diff     = parseFloat((fallback.predicted_aqi - fallback.current_aqi).toFixed(1));
    const now      = new Date();
    const getStatus = (aqi) =>
      aqi <= 50 ? 'Safe' : aqi <= 100 ? 'Moderate' : aqi <= 150 ? 'Warning' : 'Hazardous';

    res.json({
      base_aqi   : fallback.current_aqi,
      base_status: fallback.current_status,
      hours_ahead: hours,
      predictions: Array.from({length: hours}, (_, i) => {
        const h   = i + 1;
        const aqi = parseFloat(Math.min(fallback.current_aqi + diff * h * 0.5, 500).toFixed(1));
        const ts  = new Date(now.getTime() + h * 3600000).toISOString().slice(0,16);
        return { hour: h, datetime: ts, predicted_aqi: aqi, status: getStatus(aqi),
                 trend: diff > 3 ? 'worsening' : diff < -3 ? 'improving' : 'stable' };
      }),
      model_source: 'rule_based_fallback',
      mae        : 5.0,
      data_note  : 'ML API offline — extrapolation fallback used.',
      source     : 'rule_based_fallback',
    });
  }
});

// ── ML HEALTH CHECK ────────────────────────────────────────────
app.get('/api/ml/health', async (req, res) => {
  try {
    const fetch  = require('node-fetch').default || require('node-fetch');
    const mlRes  = await fetch(`${ML_API_URL || 'http://localhost:5000'}/ml/health`,
      { signal: AbortSignal.timeout(3000) });
    const data   = await mlRes.json();
    res.json({ ml_api: 'online', ...data });
  } catch {
    res.json({ ml_api: 'offline', model_loaded: false,
      message: 'Python ML API not running. Start with: python ml_api/app.py' });
  }
});

// ── START ──────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log('╔══════════════════════════════════════════════╗');
  console.log('║    AeroSense API  —  Supabase Edition  v6    ║');
  console.log('╚══════════════════════════════════════════════╝');
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`   Health : http://localhost:${PORT}/health`);
  console.log(`   DB     : ☁️  Supabase (PostgreSQL) — HTTPS\n`);

  // Verify Supabase connection on startup
  supabase.from('users').select('id').limit(1)
    .then(({ error }) => {
      if (error) {
        console.error('❌ Supabase connection failed:', error.message);
        console.error('   Check SUPABASE_URL and SUPABASE_SERVICE_KEY in .env');
      } else {
        console.log('✅ Supabase connected — tables ready!\n');
      }
    });
});
