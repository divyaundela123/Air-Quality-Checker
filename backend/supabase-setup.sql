-- ============================================================
-- AeroSense — Supabase Database Setup
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── 1. users ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name       TEXT NOT NULL,
  email      TEXT UNIQUE NOT NULL,
  password   TEXT NOT NULL,
  phone      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 2. aqi_records ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS aqi_records (
  id          TEXT PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  aqi_score   NUMERIC NOT NULL,
  status      TEXT NOT NULL CHECK (status IN ('Safe','Moderate','Warning','Hazardous')),
  temperature NUMERIC DEFAULT 0,
  humidity    NUMERIC DEFAULT 0,
  co2         NUMERIC DEFAULT 0,
  voc         NUMERIC DEFAULT 0,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 3. user_settings ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_settings (
  user_id              UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  language             TEXT DEFAULT 'english',
  dark_mode            BOOLEAN DEFAULT FALSE,
  temperature_unit     TEXT DEFAULT 'celsius',
  notif_status_changes BOOLEAN DEFAULT TRUE,
  notif_danger_alerts  BOOLEAN DEFAULT TRUE,
  notif_analysis_saved BOOLEAN DEFAULT TRUE,
  notif_live_updates   BOOLEAN DEFAULT TRUE,
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ── Indexes for fast queries ───────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_aqi_user_date   ON aqi_records(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_aqi_user_status ON aqi_records(user_id, status);
CREATE INDEX IF NOT EXISTS idx_users_email     ON users(email);

-- ── Row Level Security (disabled — backend uses service_role) ──
ALTER TABLE users         DISABLE ROW LEVEL SECURITY;
ALTER TABLE aqi_records   DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings DISABLE ROW LEVEL SECURITY;

-- Done!
SELECT 'AeroSense tables created successfully!' AS result;
