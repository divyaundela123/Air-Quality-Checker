// ============================================================
// AeroSense — Cloud Backend (Railway + MongoDB Atlas)
// This runs on Railway cloud — connects to MongoDB Atlas.
// Flutter app calls this over HTTPS from any network.
// ============================================================

require('dotenv').config();

const express        = require('express');
const cors           = require('cors');
const bcrypt         = require('bcryptjs');
const jwt            = require('jsonwebtoken');
const mongoose       = require('mongoose');
const { randomUUID } = require('crypto');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors({ origin: '*' }));
app.use(express.json());

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

// ── MongoDB Schemas ────────────────────────────────────────────
const userSchema = new mongoose.Schema({
  name      : { type: String, required: true, trim: true },
  email     : { type: String, required: true, unique: true, lowercase: true, trim: true },
  password  : { type: String, required: true },
  phone     : { type: String, default: null },
  created_at: { type: Date, default: Date.now },
});

const aqiSchema = new mongoose.Schema({
  _id        : { type: String },
  user_id    : { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  aqi_score  : { type: Number, required: true },
  status     : { type: String, required: true },
  temperature: { type: Number, default: 0 },
  humidity   : { type: Number, default: 0 },
  co2        : { type: Number, default: 0 },
  voc        : { type: Number, default: 0 },
  recorded_at: { type: Date, default: Date.now },
  created_at : { type: Date, default: Date.now },
}, { _id: false });

const userSettingsSchema = new mongoose.Schema({
  user_id             : { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  language            : { type: String, default: 'english' },
  dark_mode           : { type: Boolean, default: false },
  temperature_unit    : { type: String, default: 'celsius' },
  notif_status_changes: { type: Boolean, default: true },
  notif_danger_alerts : { type: Boolean, default: true },
  notif_analysis_saved: { type: Boolean, default: true },
  notif_live_updates  : { type: Boolean, default: true },
  updated_at          : { type: Date, default: Date.now },
});

const User         = mongoose.models.User         || mongoose.model('User',         userSchema);
const AqiRecord    = mongoose.models.AqiRecord    || mongoose.model('AqiRecord',    aqiSchema);
const UserSettings = mongoose.models.UserSettings || mongoose.model('UserSettings', userSettingsSchema);

// ── MongoDB Connect ────────────────────────────────────────────
async function connectDB() {
  const uri = process.env.MONGODB_URI;
  if (!uri) { console.error('❌ MONGODB_URI not set'); process.exit(1); }

  await mongoose.connect(uri, { serverSelectionTimeoutMS: 30000, family: 4 });
  console.log('✅ MongoDB Atlas connected — DB:', mongoose.connection.name);
  console.log('✅ Collections: users, aqi_records, user_settings');
  console.log('🎉 Database fully initialised!\n');
}

// ══════════════════════════════════════════════════════════════
// ROUTES
// ══════════════════════════════════════════════════════════════

// ── HEALTH ─────────────────────────────────────────────────────
app.get('/health', (_, res) => res.json({
  status   : 'ok',
  db       : mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
  db_ready : mongoose.connection.readyState === 1,
  db_type  : 'MongoDB Atlas',
  db_name  : mongoose.connection.name || 'aerosense',
  timestamp: new Date().toISOString(),
  version  : '6.0.0',
}));

// ── POST /api/auth/register ────────────────────────────────────
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name?.trim() || !email?.trim() || !password)
      return apiErr(res, 400, 'name, email and password are required');
    if (password.length < 6)
      return apiErr(res, 400, 'Password must be at least 6 characters');

    const clean = email.toLowerCase().trim();
    if (await User.findOne({ email: clean })) return apiErr(res, 409, 'Email already registered');

    const hash = await bcrypt.hash(password, 12);
    const user = await User.create({ name: name.trim(), email: clean, password: hash });

    // Create default settings for new user
    await UserSettings.create({ user_id: user._id }).catch(() => {});

    const id = user._id.toString();
    res.status(201).json({ token: signToken(id), user: { id, name: user.name, email: user.email } });
  } catch (e) {
    console.error('register:', e.message);
    if (e.code === 11000) return apiErr(res, 409, 'Email already registered');
    apiErr(res, 500, 'Server error during registration');
  }
});

// ── POST /api/auth/login ───────────────────────────────────────
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email?.trim() || !password) return apiErr(res, 400, 'email and password are required');

    const clean = email.toLowerCase().trim();
    const user  = await User.findOne({ email: clean });
    if (!user || !(await bcrypt.compare(password, user.password)))
      return apiErr(res, 401, 'Invalid email or password');

    const id = user._id.toString();
    res.json({ token: signToken(id), user: { id, name: user.name, email: user.email } });
  } catch (e) {
    console.error('login:', e.message);
    apiErr(res, 500, 'Server error during login');
  }
});

// ── GET /api/auth/me ───────────────────────────────────────────
app.get('/api/auth/me', authenticate, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('-password');
    if (!user) return apiErr(res, 404, 'User not found');
    res.json({ user: { id: user._id.toString(), name: user.name, email: user.email, created_at: user.created_at } });
  } catch (e) { apiErr(res, 500, 'Server error'); }
});

// ── PUT /api/auth/profile ──────────────────────────────────────
app.put('/api/auth/profile', authenticate, async (req, res) => {
  try {
    const { name } = req.body;
    if (!name?.trim() || name.trim().length < 2) return apiErr(res, 400, 'Name must be at least 2 characters');
    await User.findByIdAndUpdate(req.userId, { name: name.trim() });
    res.json({ message: 'Profile updated', name: name.trim() });
  } catch (e) { apiErr(res, 500, 'Server error'); }
});

// ── PUT /api/auth/reset-password ───────────────────────────────
app.put('/api/auth/reset-password', async (req, res) => {
  try {
    const { email, new_password } = req.body;
    if (!email?.trim() || !new_password) return apiErr(res, 400, 'email and new_password are required');
    if (new_password.length < 6) return apiErr(res, 400, 'Password must be at least 6 characters');

    const clean = email.toLowerCase().trim();
    const user  = await User.findOne({ email: clean });
    if (!user) return apiErr(res, 404, 'No account found with that email');

    await User.findByIdAndUpdate(user._id, { password: await bcrypt.hash(new_password, 12) });
    res.json({ message: 'Password reset successful' });
  } catch (e) {
    console.error('reset-password:', e.message);
    apiErr(res, 500, 'Server error');
  }
});

// ── GET /api/records ───────────────────────────────────────────
app.get('/api/records', authenticate, async (req, res) => {
  try {
    const records = await AqiRecord.find({ user_id: req.userId })
      .sort({ recorded_at: -1 }).lean();
    res.json({
      records: records.map(r => ({
        id: r._id, aqi_score: r.aqi_score, status: r.status,
        temperature: r.temperature, humidity: r.humidity,
        co2: r.co2, voc: r.voc, recorded_at: r.recorded_at,
      })),
      count: records.length,
    });
  } catch (e) { apiErr(res, 500, 'Server error fetching records'); }
});

// ── GET /api/records/latest ────────────────────────────────────
app.get('/api/records/latest', authenticate, async (req, res) => {
  try {
    const r = await AqiRecord.findOne({ user_id: req.userId }).sort({ recorded_at: -1 }).lean();
    res.json({ record: r ? { id: r._id, aqi_score: r.aqi_score, status: r.status,
      temperature: r.temperature, humidity: r.humidity,
      co2: r.co2, voc: r.voc, recorded_at: r.recorded_at } : null });
  } catch (e) { apiErr(res, 500, 'Server error'); }
});

// ── POST /api/records ──────────────────────────────────────────
app.post('/api/records', authenticate, async (req, res) => {
  try {
    const { id, aqi_score, status, temperature, humidity, co2, voc, recorded_at } = req.body;
    if (!id || aqi_score == null || !status) return apiErr(res, 400, 'id, aqi_score and status are required');

    await AqiRecord.findByIdAndUpdate(id,
      { _id: id, user_id: req.userId, aqi_score, status,
        temperature: temperature ?? 0, humidity: humidity ?? 0,
        co2: co2 ?? 0, voc: voc ?? 0,
        recorded_at: recorded_at ? new Date(recorded_at) : new Date() },
      { upsert: true, new: true, setDefaultsOnInsert: true });

    res.status(201).json({ message: 'Record saved', id });
  } catch (e) {
    console.error('post record:', e.message);
    apiErr(res, 500, 'Server error saving record');
  }
});

// ── DELETE /api/records/:id ────────────────────────────────────
app.delete('/api/records/:id', authenticate, async (req, res) => {
  try {
    const r = await AqiRecord.findOneAndDelete({ _id: req.params.id, user_id: req.userId });
    if (!r) return apiErr(res, 404, 'Record not found');
    res.json({ message: 'Record deleted' });
  } catch (e) { apiErr(res, 500, 'Server error'); }
});

// ── DELETE /api/records ────────────────────────────────────────
app.delete('/api/records', authenticate, async (req, res) => {
  try {
    const r = await AqiRecord.deleteMany({ user_id: req.userId });
    res.json({ message: 'All records cleared', deleted: r.deletedCount });
  } catch (e) { apiErr(res, 500, 'Server error'); }
});

// ── START ──────────────────────────────────────────────────────
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 AeroSense Cloud API running on port ${PORT}`);
    console.log(`   Health : /health`);
    console.log(`   DB     : ☁️  MongoDB Atlas\n`);
  });
}).catch(err => {
  console.error('❌ Failed to connect to MongoDB:', err.message);
  process.exit(1);
});
