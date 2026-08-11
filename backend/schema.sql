-- ============================================================
-- AeroSense Database Schema
-- Run this script in your MySQL server to create the database
-- ============================================================

CREATE DATABASE IF NOT EXISTS aerosense CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE aerosense;

-- ── Users table ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(120)  NOT NULL,
  email       VARCHAR(191)  NOT NULL UNIQUE,
  password    VARCHAR(255)  NOT NULL,
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── AQI Records table ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS aqi_records (
  id          VARCHAR(36)   PRIMARY KEY,          -- UUID or timestamp string from Flutter
  user_id     INT UNSIGNED  NOT NULL,
  aqi_score   FLOAT         NOT NULL,
  status      VARCHAR(20)   NOT NULL,
  temperature FLOAT         NOT NULL,
  humidity    FLOAT         NOT NULL,
  co2         FLOAT         NOT NULL,
  voc         FLOAT         NOT NULL,
  recorded_at DATETIME      NOT NULL,
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_aqi_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_aqi_user_recorded ON aqi_records (user_id, recorded_at DESC);
