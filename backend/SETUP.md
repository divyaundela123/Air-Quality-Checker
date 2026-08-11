# AeroSense Backend — Setup Guide

## Stack
- **Node.js** (Express) — REST API
- **MySQL** (via XAMPP) — database
- **JWT** — authentication tokens

---

## Step 1 — Install XAMPP (MySQL)

1. Download XAMPP from https://www.apachefriends.org/
2. Install it (default path: `C:\xampp`)
3. Open **XAMPP Control Panel**
4. Click **Start** next to **MySQL**
5. MySQL is now running on `localhost:3306`

---

## Step 2 — Create the Database

Open a terminal in the `backend/` folder and run:

```bash
node setup-db.js
```

You should see:
```
✅ Connected to MySQL
✅ Database 'aerosense' ready
✅ Table users ready
✅ Table aqi_records ready
🎉 Database setup complete!
```

---

## Step 3 — Start the API Server

```bash
node server.js
```

You should see:
```
✅ DB connected
🚀 AeroSense API running on http://localhost:3000
```

Test it:
```
http://localhost:3000/health
```

---

## Step 4 — Configure Flutter App

Open `lib/services/api_service.dart` and set the correct base URL:

| Target              | URL                           |
|---------------------|-------------------------------|
| Chrome (web)        | `http://localhost:3000`       |
| Android Emulator    | `http://10.0.2.2:3000`        |
| Physical Device     | `http://<your-LAN-IP>:3000`   |

To find your LAN IP on Windows:
```
ipconfig
```
Look for **IPv4 Address** under your Wi-Fi adapter.

---

## API Endpoints

### Auth
| Method | Route                  | Auth | Description        |
|--------|------------------------|------|--------------------|
| POST   | /api/auth/register     | —    | Register new user  |
| POST   | /api/auth/login        | —    | Login              |
| GET    | /api/auth/me           | JWT  | Get profile        |
| PUT    | /api/auth/profile      | JWT  | Update name        |

### Records
| Method | Route                  | Auth | Description        |
|--------|------------------------|------|--------------------|
| GET    | /api/records           | JWT  | Get all records    |
| POST   | /api/records           | JWT  | Save a record      |
| DELETE | /api/records/:id       | JWT  | Delete one record  |
| DELETE | /api/records           | JWT  | Clear all records  |

---

## .env Configuration

Edit `backend/.env`:
```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=          # leave blank for XAMPP default
DB_NAME=aerosense

JWT_SECRET=change_this_to_something_long_and_random
JWT_EXPIRES_IN=30d

PORT=3000
```
