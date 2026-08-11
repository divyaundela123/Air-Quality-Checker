# AeroSense — Live Cloud Deployment (10 minutes)

## Step 1 — Create Free Aiven MySQL Database

1. Go to: https://aiven.io/free-tier
2. Click **"Start for free"** → sign up with Google or email (NO credit card)
3. After login → click **"Create service"**
4. Choose **MySQL**
5. Select free plan → **Hobbyist** 
6. Region: pick closest to you (e.g. `google-asia-south1` for India)
7. Click **Create service** — takes ~2 minutes to provision

8. Once green/running → click on your service
9. On the **Overview** tab, copy these values:
   ```
   Host:     something.aivencloud.com
   Port:     (5-digit number like 12345)
   User:     avnadmin
   Password: (long random string)
   Database: defaultdb
   ```

---

## Step 2 — Update backend/.env

Open `backend/.env` and replace the placeholder values:
```
DB_HOST=your-actual-host.aivencloud.com
DB_PORT=12345
DB_USER=avnadmin
DB_PASSWORD=your-actual-password
DB_NAME=defaultdb
DB_SSL=true
```

---

## Step 3 — Create the Tables in Cloud DB

In your terminal (backend folder):
```bash
node setup-db.js
```

You should see:
```
✅ Connected to MySQL
✅ Database 'defaultdb' ready
✅ Table users ready
✅ Table aqi_records ready
🎉 Database setup complete!
```

---

## Step 4 — Push Backend to GitHub

```bash
git init
git add .
git commit -m "AeroSense backend"
git remote add origin https://github.com/YOUR_USERNAME/aerosense-backend.git
git push -u origin main
```

---

## Step 5 — Deploy to Render.com (Free, no credit card)

1. Go to: https://render.com
2. Sign up with GitHub
3. Click **"New +"** → **"Web Service"**
4. Connect your GitHub repo
5. Settings:
   - **Build Command:** `npm install`
   - **Start Command:** `node server.js`
6. Scroll to **Environment Variables** → add all values from your `.env`
7. Click **"Create Web Service"**
8. Wait ~3 minutes → you get a URL like:
   ```
   https://aerosense-api.onrender.com
   ```

---

## Step 6 — Update Flutter App

Open `lib/services/api_service.dart`:
```dart
static const String _baseUrl = 'https://aerosense-api.onrender.com';
// Replace with YOUR actual Render URL
```

---

## Step 7 — Run Flutter App

```bash
flutter run -d chrome
```

Register → Login → data is now saved in Aiven cloud MySQL! 🎉

---

## Your Live URLs (fill these in after deploy)

| Service | URL |
|---------|-----|
| API Backend | https://aerosense-api.onrender.com |
| Health Check | https://aerosense-api.onrender.com/health |
| Aiven Console | https://console.aiven.io |
