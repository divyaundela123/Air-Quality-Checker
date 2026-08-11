// ============================================================
// AeroSense — One-click database setup script
// Run: node setup-db.js
// ============================================================
require('dotenv').config();
const mysql = require('mysql2/promise');

async function setup() {
  console.log('🔧 AeroSense Database Setup\n');

  // Connect WITHOUT specifying a database first
  let conn;
  try {
    conn = await mysql.createConnection({
      host    : process.env.DB_HOST     || 'localhost',
      port    : parseInt(process.env.DB_PORT || '3306'),
      user    : process.env.DB_USER     || 'root',
      password: process.env.DB_PASSWORD || '',
      ssl     : process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
    });
    console.log('✅ Connected to MySQL');
  } catch (e) {
    console.error('❌ Cannot connect to MySQL:', e.message);
    console.error('\nMake sure:');
    console.error('  1. XAMPP is installed and MySQL is Started in XAMPP Control Panel');
    console.error('  2. Your .env credentials match (default: root / no password)');
    process.exit(1);
  }

  try {
    // 1. Create database (skipped if using Aiven defaultdb)
    const dbName = process.env.DB_NAME || 'aerosense';
    const isAiven = process.env.DB_SSL === 'true';

    if (!isAiven) {
      await conn.query(
        `CREATE DATABASE IF NOT EXISTS \`${dbName}\`
         CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
      );
    }
    console.log(`✅ Database '${dbName}' ready`);
    await conn.query(`USE \`${dbName}\``);

    // 2. Users table
    await conn.query(`
      CREATE TABLE IF NOT EXISTS users (
        id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        name        VARCHAR(120)  NOT NULL,
        email       VARCHAR(191)  NOT NULL UNIQUE,
        password    VARCHAR(255)  NOT NULL,
        created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    `);
    console.log('✅ Table users ready');

    // 3. AQI records table
    await conn.query(`
      CREATE TABLE IF NOT EXISTS aqi_records (
        id          VARCHAR(36)   PRIMARY KEY,
        user_id     INT UNSIGNED  NOT NULL,
        aqi_score   FLOAT         NOT NULL,
        status      VARCHAR(20)   NOT NULL,
        temperature FLOAT         NOT NULL,
        humidity    FLOAT         NOT NULL,
        co2         FLOAT         NOT NULL,
        voc         FLOAT         NOT NULL,
        recorded_at DATETIME      NOT NULL,
        created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_aqi_user FOREIGN KEY (user_id)
          REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    `);
    console.log('✅ Table aqi_records ready');

    // 4. Index
    try {
      await conn.query(
        `CREATE INDEX idx_aqi_user_recorded ON aqi_records (user_id, recorded_at DESC)`
      );
    } catch { /* index already exists — ok */ }

    console.log('\n🎉 Database setup complete!');
    console.log('   Run "node server.js" to start the API server.\n');
  } catch (e) {
    console.error('❌ Setup error:', e.message);
  } finally {
    await conn.end();
  }
}

setup();
