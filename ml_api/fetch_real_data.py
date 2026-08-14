# ============================================================
# AeroSense — Real AQI Data Fetcher
# Source: OpenAQ API v3 (free, no API key required)
#         Provides PM2.5, PM10, CO, NO2, SO2, O3 for India
# Output: ml_api/data/india_aqi_real.csv
# Usage : python fetch_real_data.py
#         python fetch_real_data.py --cities "Delhi,Mumbai,Chennai"
#         python fetch_real_data.py --days 30
# ============================================================

import os, sys, json, time, argparse, math
from datetime import datetime, timedelta, timezone
import urllib.request
import urllib.error

try:
    import pandas as pd
    import numpy as np
except ImportError:
    print("Install pandas/numpy: pip install pandas numpy")
    sys.exit(1)

# ── OpenAQ v3 endpoints ───────────────────────────────────────
BASE = "https://api.openaq.org/v3"

# CPCB station IDs for major Indian cities (OpenAQ location IDs)
# Each entry: (city_name, lat, lon, openaq_location_id)
INDIA_STATIONS = [
    ("New Delhi",     28.6139, 77.2090, 8118),    # Anand Vihar
    ("New Delhi",     28.6694, 77.1458, 8119),    # Rohini
    ("Mumbai",        19.0760, 72.8777, 8098),    # Bandra Kurla Complex
    ("Chennai",       13.0500, 80.2500, 8237),    # Alandur
    ("Kolkata",       22.5726, 88.3639, 8136),    # Rabindra Bharati Univ
    ("Hyderabad",     17.3850, 78.4867, 8210),    # Bollaram
    ("Bengaluru",     12.9716, 77.5946, 8073),    # Bapuji Nagar
    ("Ahmedabad",     23.0225, 72.5714, 8001),    # Maninagar
    ("Pune",          18.5204, 73.8567, 8189),    # Lohegaon
    ("Lucknow",       26.8467, 80.9462, 8155),    # Talkatora
    ("Kanpur",        26.4499, 80.3319, 8127),    # Nehru Nagar
    ("Patna",         25.5941, 85.1376, 8183),    # IGSC Planetarium
    ("Jaipur",        26.9124, 75.7873, 8116),    # Shastri Nagar
    ("Nagpur",        21.1458, 79.0882, 8169),    # Civil Lines
    ("Visakhapatnam", 17.6868, 83.2185, 8230),    # VUDA Layout
]

POLLUTANTS = ["pm25", "pm10", "co", "no2", "so2", "o3"]

# ─────────────────────────────────────────────────────────────

def openaq_get(path, params=None, retries=3):
    """Simple HTTP GET wrapper with retry / rate-limit handling."""
    url = BASE + path
    if params:
        url += "?" + "&".join(f"{k}={v}" for k, v in params.items())
    headers = {"Accept": "application/json"}
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=15) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait = 10 * (attempt + 1)
                print(f"    Rate limited — waiting {wait}s…")
                time.sleep(wait)
            else:
                print(f"    HTTP {e.code} for {url}")
                return None
        except Exception as ex:
            print(f"    Request failed ({ex}), retry {attempt+1}/{retries}")
            time.sleep(3)
    return None


def fetch_measurements(location_id, pollutant, days=30):
    """
    Fetch hourly measurements for one pollutant from one station.
    Returns list of {datetime, value}.
    """
    date_from = (datetime.now(timezone.utc) - timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ")
    date_to   = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    results, page = [], 1
    while True:
        data = openaq_get("/measurements", {
            "locations_id" : location_id,
            "parameters_id": _param_id(pollutant),
            "date_from"    : date_from,
            "date_to"      : date_to,
            "limit"        : 1000,
            "page"         : page,
        })
        if not data or "results" not in data:
            break
        batch = data["results"]
        if not batch:
            break
        for m in batch:
            try:
                ts  = m.get("date", {}).get("utc") or m.get("datetime", {}).get("utc", "")
                val = float(m.get("value", -1))
                if val >= 0:
                    results.append({"datetime": ts, "value": val})
            except (TypeError, ValueError):
                pass
        if len(batch) < 1000:
            break
        page += 1
        time.sleep(0.3)   # be polite to the API
    return results


def _param_id(name):
    """OpenAQ v3 parameter IDs (numeric)."""
    return {
        "pm25": 2, "pm10": 1, "co": 8, "no2": 7, "so2": 9, "o3": 10,
    }.get(name, 2)


def aqi_from_pollutants(pm25=None, pm10=None, co=None, no2=None, so2=None, o3=None,
                        temperature=25.0, humidity=60.0):
    """
    Compute AQI from real pollutant values using India NAQI breakpoints (CPCB).
    Falls back to sub-index maximum (standard India method).
    """
    sub = []

    def _linear(bp_lo, bp_hi, c_lo, c_hi, c):
        if c_hi == c_lo: return 0.0
        return ((bp_hi - bp_lo) / (c_hi - c_lo)) * (c - c_lo) + bp_lo

    # PM2.5 (µg/m³) — 24-h average breakpoints (CPCB India)
    if pm25 is not None and pm25 >= 0:
        bp = [(0,30,0,50),(30,60,51,100),(60,90,101,200),
              (90,120,201,300),(120,250,301,400),(250,380,401,500)]
        sub.append(_sub_index(pm25, bp))

    # PM10 (µg/m³)
    if pm10 is not None and pm10 >= 0:
        bp = [(0,50,0,50),(50,100,51,100),(100,250,101,200),
              (250,350,201,300),(350,430,301,400),(430,600,401,500)]
        sub.append(_sub_index(pm10, bp))

    # NO2 (µg/m³)
    if no2 is not None and no2 >= 0:
        bp = [(0,40,0,50),(40,80,51,100),(80,180,101,200),
              (180,280,201,300),(280,400,301,400),(400,800,401,500)]
        sub.append(_sub_index(no2, bp))

    # SO2 (µg/m³)
    if so2 is not None and so2 >= 0:
        bp = [(0,40,0,50),(40,80,51,100),(80,380,101,200),
              (380,800,201,300),(800,1600,301,400),(1600,2100,401,500)]
        sub.append(_sub_index(so2, bp))

    # CO (mg/m³) — convert ppb → mg/m³ if needed (CO values from API in µg/m³)
    if co is not None and co >= 0:
        co_mgm3 = co / 1000.0  # µg/m³ → mg/m³
        bp = [(0,1.0,0,50),(1.0,2.0,51,100),(2.0,10.0,101,200),
              (10.0,17.0,201,300),(17.0,34.0,301,400),(34.0,46.0,401,500)]
        sub.append(_sub_index(co_mgm3, bp))

    # O3 (µg/m³)
    if o3 is not None and o3 >= 0:
        bp = [(0,50,0,50),(50,100,51,100),(100,168,101,200),
              (168,208,201,300),(208,748,301,400),(748,1000,401,500)]
        sub.append(_sub_index(o3, bp))

    if not sub:
        # Fallback to sensor-based formula
        base = 0.0
        if temperature and humidity:
            base = (temperature * 0.8) + (humidity * 0.2)
        return float(np.clip(base, 0, 500))

    return float(np.clip(max(sub), 0, 500))


def _sub_index(c, breakpoints):
    """NAQI sub-index calculation."""
    for (c_lo, c_hi, bp_lo, bp_hi) in breakpoints:
        if c_lo <= c <= c_hi:
            if c_hi == c_lo: return float(bp_lo)
            return float(((bp_hi - bp_lo) / (c_hi - c_lo)) * (c - c_lo) + bp_lo)
    return 500.0 if c > breakpoints[-1][1] else 0.0


def build_synthetic_row(city, lat, lon, hour, pm25=None, pm10=None,
                        co=None, no2=None, so2=None, o3=None,
                        temperature=None, humidity=None, rng=None):
    """
    Fill missing sensor values with realistic synthetic defaults
    so every row has a complete feature vector. Values that are
    truly available from OpenAQ are passed in; missing ones are
    estimated from time-of-day patterns typical for Indian cities.
    """
    if rng is None:
        rng = np.random.default_rng(42)

    # Realistic patterns for Indian urban environment
    temp = temperature if temperature is not None else float(
        np.clip(28 + 8 * math.sin((hour - 6) * math.pi / 12) + rng.normal(0, 2), 15, 45))
    hum  = humidity if humidity is not None else float(
        np.clip(60 + 20 * math.sin((hour - 14) * math.pi / 12) + rng.normal(0, 8), 20, 95))

    # If a pollutant is missing, estimate from typical urban profiles
    pm25_ = pm25 if pm25 is not None else float(np.clip(40 + 30 * math.sin((hour - 10) * math.pi / 12) + rng.normal(0, 10), 5, 300))
    pm10_ = pm10 if pm10 is not None else float(np.clip(pm25_ * 1.8 + rng.normal(0, 15), 10, 500))
    no2_  = no2  if no2  is not None else float(np.clip(40 + 20 * math.sin((hour - 8) * math.pi / 12) + rng.normal(0, 8), 5, 400))
    so2_  = so2  if so2  is not None else float(np.clip(15 + rng.normal(0, 5), 1, 200))
    o3_   = o3   if o3   is not None else float(np.clip(60 + 40 * math.sin((hour - 14) * math.pi / 12) + rng.normal(0, 10), 5, 400))
    co_   = co   if co   is not None else float(np.clip(500 + 200 * math.sin((hour - 10) * math.pi / 12) + rng.normal(0, 80), 100, 3000))  # µg/m³

    aqi = aqi_from_pollutants(pm25=pm25_, pm10=pm10_, co=co_, no2=no2_,
                              so2=so2_, o3=o3_, temperature=temp, humidity=hum)
    return {
        "city"       : city,
        "latitude"   : lat,
        "longitude"  : lon,
        "hour"       : hour,
        "temperature": round(temp, 2),
        "humidity"   : round(hum, 2),
        "pm25"       : round(pm25_, 2),
        "pm10"       : round(pm10_, 2),
        "no2"        : round(no2_, 2),
        "so2"        : round(so2_, 2),
        "o3"         : round(o3_, 2),
        "co"         : round(co_, 2),
        "aqi"        : round(aqi, 2),
        "source"     : "real" if pm25 is not None or pm10 is not None else "synthetic",
    }


def fetch_city(city, lat, lon, location_id, days, rng):
    """Fetch all available pollutant data for one city station."""
    print(f"  📍 {city} (location {location_id})")
    measurements = {}

    for pol in POLLUTANTS:
        print(f"     ↳ {pol}…", end=" ", flush=True)
        data = fetch_measurements(location_id, pol, days)
        measurements[pol] = {}
        for m in data:
            # Round to nearest hour
            try:
                dt = datetime.fromisoformat(m["datetime"].replace("Z", "+00:00"))
                key = dt.replace(minute=0, second=0, microsecond=0)
                measurements[pol][key] = m["value"]
            except Exception:
                pass
        print(f"{len(measurements[pol])} readings")
        time.sleep(0.5)

    # Determine time range to build rows
    all_keys = set()
    for pol in POLLUTANTS:
        all_keys.update(measurements[pol].keys())

    rows = []
    if all_keys:
        for ts in sorted(all_keys):
            hour = ts.hour
            row  = build_synthetic_row(
                city=city, lat=lat, lon=lon, hour=hour,
                pm25 = measurements["pm25"].get(ts),
                pm10 = measurements["pm10"].get(ts),
                co   = measurements["co"].get(ts),
                no2  = measurements["no2"].get(ts),
                so2  = measurements["so2"].get(ts),
                o3   = measurements["o3"].get(ts),
                rng  = rng,
            )
            row["datetime"] = ts.isoformat()
            rows.append(row)
        print(f"     ✅ {len(rows)} hourly rows built from real data")
    else:
        # Station returned no data — generate synthetic hourly rows for N days
        print(f"     ⚠️  No OpenAQ data — generating {days * 24} synthetic rows")
        base_dt = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0)
        for h_back in range(days * 24, 0, -1):
            ts   = base_dt - timedelta(hours=h_back)
            hour = ts.hour
            row  = build_synthetic_row(city=city, lat=lat, lon=lon, hour=hour, rng=rng)
            row["datetime"] = ts.isoformat()
            rows.append(row)

    return rows


def main():
    parser = argparse.ArgumentParser(description="Fetch real AQI data from OpenAQ for India")
    parser.add_argument("--days",   type=int,  default=30,  help="Days of history to fetch (default 30)")
    parser.add_argument("--cities", type=str,  default="",  help="Comma-separated city names to limit fetch")
    parser.add_argument("--no-api", action="store_true",    help="Skip API calls — generate synthetic data only")
    args = parser.parse_args()

    out_dir = os.path.join(os.path.dirname(__file__), "data")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "india_aqi_real.csv")

    city_filter = {c.strip().lower() for c in args.cities.split(",") if c.strip()}
    rng = np.random.default_rng(42)

    all_rows = []
    stations = INDIA_STATIONS if not city_filter else [
        s for s in INDIA_STATIONS if s[0].lower() in city_filter
    ]

    print(f"\n{'='*55}")
    print(f"  AeroSense — OpenAQ Data Fetcher")
    print(f"  Stations : {len(stations)} | Days : {args.days}")
    print(f"{'='*55}\n")

    for city, lat, lon, loc_id in stations:
        if args.no_api:
            print(f"  📍 {city} — synthetic only")
            base_dt = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0)
            for h_back in range(args.days * 24, 0, -1):
                ts  = base_dt - timedelta(hours=h_back)
                row = build_synthetic_row(city=city, lat=lat, lon=lon, hour=ts.hour, rng=rng)
                row["datetime"] = ts.isoformat()
                all_rows.append(row)
        else:
            rows = fetch_city(city, lat, lon, loc_id, args.days, rng)
            all_rows.extend(rows)

    if not all_rows:
        print("❌ No data collected.")
        return

    df = pd.DataFrame(all_rows)
    df = df.drop_duplicates(subset=["city", "datetime"]).sort_values(["city", "datetime"])
    df.to_csv(out_path, index=False)

    real_count = (df["source"] == "real").sum()
    print(f"\n✅ Saved {len(df)} rows → {out_path}")
    print(f"   Real: {real_count} | Synthetic: {len(df) - real_count}")
    print(f"   Cities: {df['city'].nunique()} | AQI range: {df['aqi'].min():.1f}–{df['aqi'].max():.1f}")
    print(f"\n▶  Next step: python train_model.py\n")


if __name__ == "__main__":
    main()
