// ============================================================
// AeroSense — MongoDB Atlas Database Setup Script
//
// Creates the 'aerosense' database with 3 collections:
//   1. users        — registered user accounts
//   2. aqi_records  — air quality readings per user
//   3. user_settings — notification & app preferences per user
//
// Run once: node db-setup.js
// Safe to re-run — uses createCollection only if not exists.
// ============================================================

// ⚡ Set Google DNS BEFORE any network call so college/corp firewalls are bypassed
process.env.NODE_OPTIONS = '';
const dns = require('dns');
dns.setDefaultResultOrder('ipv4first');
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);

require('dotenv').config();
const mongoose = require('mongoose');

const MONGODB_URI = process.env.MONGODB_URI;

// ── Collection definitions ─────────────────────────────────
const collections = [
  {
    name: 'users',
    description: 'Registered user accounts',
    validator: {
      $jsonSchema: {
        bsonType: 'object',
        required: ['name', 'email', 'password', 'created_at'],
        properties: {
          name       : { bsonType: 'string', description: 'Full name of the user' },
          email      : { bsonType: 'string', description: 'Unique email address' },
          password   : { bsonType: 'string', description: 'Bcrypt hashed password' },
          phone      : { bsonType: ['string', 'null'], description: 'Optional phone number' },
          created_at : { bsonType: 'date',   description: 'Account creation timestamp' },
          updated_at : { bsonType: ['date', 'null'], description: 'Last profile update' },
        },
      },
    },
    indexes: [
      { key: { email: 1 }, options: { unique: true, name: 'email_unique' } },
      { key: { created_at: -1 }, options: { name: 'created_at_desc' } },
    ],
  },
  {
    name: 'aqi_records',
    description: 'Air quality readings saved by users',
    validator: {
      $jsonSchema: {
        bsonType: 'object',
        required: ['_id', 'user_id', 'aqi_score', 'status', 'recorded_at'],
        properties: {
          _id         : { bsonType: 'string',   description: 'UUID from Flutter app' },
          user_id     : { bsonType: 'objectId', description: 'Reference to users._id' },
          aqi_score   : { bsonType: 'double',   description: 'Calculated AQI value 0-300' },
          status      : {
            bsonType: 'string',
            enum: ['Safe', 'Moderate', 'Warning', 'Hazardous'],
            description: 'Air quality status label',
          },
          temperature : { bsonType: ['double', 'int'], description: 'Temperature in °C' },
          humidity    : { bsonType: ['double', 'int'], description: 'Relative humidity %' },
          co2         : { bsonType: ['double', 'int'], description: 'CO₂ in ppm' },
          voc         : { bsonType: ['double', 'int'], description: 'VOC in ppb' },
          recorded_at : { bsonType: 'date', description: 'When the reading was taken' },
          created_at  : { bsonType: 'date', description: 'When the record was saved' },
        },
      },
    },
    indexes: [
      { key: { user_id: 1, recorded_at: -1 }, options: { name: 'user_records_desc' } },
      { key: { user_id: 1, status: 1 },       options: { name: 'user_status_filter' } },
      { key: { recorded_at: -1 },             options: { name: 'recorded_at_desc' } },
    ],
  },
  {
    name: 'user_settings',
    description: 'Notification and app preferences per user',
    validator: {
      $jsonSchema: {
        bsonType: 'object',
        required: ['user_id'],
        properties: {
          user_id             : { bsonType: 'objectId', description: 'Reference to users._id' },
          language            : {
            bsonType: 'string',
            enum: ['english', 'telugu', 'hindi', 'tamil'],
            description: 'Selected UI language',
          },
          dark_mode           : { bsonType: 'bool',   description: 'Dark mode on/off' },
          temperature_unit    : {
            bsonType: 'string',
            enum: ['celsius', 'fahrenheit'],
            description: 'Preferred temperature unit',
          },
          notif_status_changes: { bsonType: 'bool', description: 'Notify on AQI status change' },
          notif_danger_alerts : { bsonType: 'bool', description: 'Notify on Warning/Hazardous' },
          notif_analysis_saved: { bsonType: 'bool', description: 'Notify when analysis saved' },
          notif_live_updates  : { bsonType: 'bool', description: 'Notify on live sensor refresh' },
          updated_at          : { bsonType: 'date', description: 'Last settings update' },
        },
      },
    },
    indexes: [
      { key: { user_id: 1 }, options: { unique: true, name: 'user_settings_unique' } },
    ],
  },
];

// ── Main setup ─────────────────────────────────────────────
async function setupDatabase() {
  console.log('╔══════════════════════════════════════════════╗');
  console.log('║   AeroSense — MongoDB Atlas Database Setup   ║');
  console.log('╚══════════════════════════════════════════════╝\n');

  console.log('🔌 Connecting to MongoDB Atlas...');

  await mongoose.connect(MONGODB_URI, {
    serverSelectionTimeoutMS: 30000,
    connectTimeoutMS        : 30000,
    family                  : 4,
  });

  const db = mongoose.connection.db;
  console.log(`✅ Connected to MongoDB Atlas — DB: "${mongoose.connection.name}"\n`);

  // Get existing collection names
  const existing = await db.listCollections().toArray();
  const existingNames = existing.map(c => c.name);
  console.log(`📦 Existing collections: [${existingNames.join(', ') || 'none'}]\n`);

  // Create each collection
  for (const col of collections) {
    process.stdout.write(`  ➤ Collection: "${col.name}" — ${col.description}\n`);

    if (existingNames.includes(col.name)) {
      // Update validator on existing collection
      await db.command({
        collMod   : col.name,
        validator : col.validator,
        validationLevel : 'moderate',
        validationAction: 'warn',
      });
      console.log(`    ✓ Already exists — validator updated`);
    } else {
      // Create new collection with validator
      await db.createCollection(col.name, {
        validator       : col.validator,
        validationLevel : 'moderate',   // moderate = warn only, don't reject existing docs
        validationAction: 'warn',
      });
      console.log(`    ✓ Created`);
    }

    // Create/ensure indexes
    const collection = db.collection(col.name);
    for (const idx of col.indexes) {
      try {
        await collection.createIndex(idx.key, idx.options);
        console.log(`    ✓ Index: ${JSON.stringify(idx.key)} → ${idx.options.name}`);
      } catch (e) {
        if (e.code === 85 || e.code === 86) {
          console.log(`    ⚠ Index "${idx.options.name}" already exists — skipped`);
        } else {
          throw e;
        }
      }
    }
    console.log('');
  }

  // Print summary
  console.log('═══════════════════════════════════════════════');
  console.log('✅  Database setup complete!\n');
  const final_cols = await db.listCollections().toArray();
  console.log('📋 Collections in "aerosense":');
  for (const c of final_cols) {
    const stats = await db.collection(c.name).estimatedDocumentCount();
    console.log(`   • ${c.name.padEnd(20)} ${stats} document(s)`);
  }
  console.log('\n🔗 View in Atlas:');
  console.log('   https://cloud.mongodb.com → Browse Collections → aerosense');
  console.log('═══════════════════════════════════════════════\n');

  await mongoose.disconnect();
  process.exit(0);
}

setupDatabase().catch(err => {
  console.error('\n❌ Setup failed:', err.message);
  if (err.message.includes('whitelist') || err.message.includes('IP')) {
    console.error('\n⚠️  Your IP is not whitelisted in MongoDB Atlas.');
    console.error('   Go to: https://cloud.mongodb.com → Network Access → Allow 0.0.0.0/0');
  }
  process.exit(1);
});
