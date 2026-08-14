# ============================================================
# AeroSense — ML Model Training  (v2)
# Uses real OpenAQ data when available (via fetch_real_data.py)
# Falls back to realistic synthetic data if real data is absent.
#
# Models trained:
#   1. RandomForest  — robust, works well on tabular AQI data
#   2. GradientBoosting — often better accuracy on structured data
#   The better model (lower MAE on test set) is saved as primary.
#
# Features (19):
#   Core sensors  : temperature, humidity, pm25, pm10, no2, so2, o3, co
#   Derived AQI   : current_aqi  (NAQI formula from pollutants)
#   Time           : hour, day_of_week, month
#   Cyclical time  : hour_sin, hour_cos, month_sin, month_cos
#   Interactions   : temp_hum_ratio, pm25_no2, pm10_co, o3_temp
#
# Target: aqi_1h_ahead  (AQI one hour in the future)
# ============================================================

import os, sys, math, json, warnings
import numpy as np
import pandas as pd
from datetime import datetime, timedelta, timezone

warnings.filterwarnings("ignore")

# ── Imports — install hint ────────────────────────────────────
try:
    from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
    from sklearn.model_selection import train_test_split, cross_val_score
    from sklearn.metrics import mean_absolute_error, r2_score, mean_squared_error
    from sklearn.preprocessing import StandardScaler
    import joblib
except ImportError:
    print("Install deps: pip install scikit-learn joblib")
    sys.exit(1)

print("=" * 60)
print("  AeroSense — AQI Prediction Model Training  v2")
print("=" * 60)

# ─────────────────────────────────────────────────────────────
# 1. AQI helpers (NAQI breakpoints — India CPCB)
# ─────────────────────────────────────────────────────────────

def _sub_index(c, breakpoints):
    for (c_lo, c_hi, bp_lo, bp_hi) in breakpoints:
        if c_lo <= c <= c_hi:
            if c_hi == c_lo:
                return float(bp_lo)
            return float(((bp_hi - bp_lo) / (c_hi - c_lo)) * (c - c_lo) + bp_lo)
    return 500.0 if c > breakpoints[-1][1] else 0.0

def aqi_from_pollutants(pm25, pm10, co, no2, so2, o3):
    """India NAQI (CPCB) — max sub-index method."""
    subs = []
    if pm25 >= 0:
        subs.append(_sub_index(pm25, [(0,30,0,50),(30,60,51,100),(60,90,101,200),(90,120,201,300),(120,250,301,400),(250,380,401,500)]))
    if pm10 >= 0:
        subs.append(_sub_index(pm10, [(0,50,0,50),(50,100,51,100),(100,250,101,200),(250,350,201,300),(350,430,301,400),(430,600,401,500)]))
    if no2 >= 0:
        subs.append(_sub_index(no2, [(0,40,0,50),(40,80,51,100),(80,180,101,200),(180,280,201,300),(280,400,301,400),(400,800,401,500)]))
    if so2 >= 0:
        subs.append(_sub_index(so2, [(0,40,0,50),(40,80,51,100),(80,380,101,200),(380,800,201,300),(800,1600,301,400),(1600,2100,401,500)]))
    if co >= 0:
        co_mg = co / 1000.0
        subs.append(_sub_index(co_mg, [(0,1,0,50),(1,2,51,100),(2,10,101,200),(10,17,201,300),(17,34,301,400),(34,46,401,500)]))
    if o3 >= 0:
        subs.append(_sub_index(o3, [(0,50,0,50),(50,100,51,100),(100,168,101,200),(168,208,201,300),(208,748,301,400),(748,1000,401,500)]))
    return float(np.clip(max(subs) if subs else 50.0, 0, 500))

def get_status(aqi):
    if aqi <= 50:  return "Safe"
    if aqi <= 100: return "Moderate"
    if aqi <= 150: return "Warning"
    return "Hazardous"

# ─────────────────────────────────────────────────────────────
# 2. Build feature vector (19 features — must match app.py)
# ─────────────────────────────────────────────────────────────
FEATURE_NAMES = [
    "temperature", "humidity",
    "pm25", "pm10", "no2", "so2", "o3", "co",
    "current_aqi",
    "hour", "day_of_week", "month",
    "hour_sin", "hour_cos",
    "month_sin", "month_cos",
    "temp_hum_ratio", "pm25_no2", "pm10_co",
]

def build_features_row(temperature, humidity, pm25, pm10, no2, so2, o3, co,
                       hour=None, day_of_week=None, month=None):
    now = datetime.now()
    if hour        is None: hour        = now.hour
    if day_of_week is None: day_of_week = now.weekday()
    if month       is None: month       = now.month

    current_aqi = aqi_from_pollutants(pm25, pm10, co, no2, so2, o3)

    return [
        temperature, humidity,
        pm25, pm10, no2, so2, o3, co,
        current_aqi,
        hour, day_of_week, month,
        math.sin(2 * math.pi * hour / 24),
        math.cos(2 * math.pi * hour / 24),
        math.sin(2 * math.pi * month / 12),
        math.cos(2 * math.pi * month / 12),
        temperature / (humidity + 1),
        pm25 * no2 / 1000.0,
        pm10 * co  / 100000.0,
    ]

# ─────────────────────────────────────────────────────────────
# 3. Load real data or generate synthetic fallback
# ─────────────────────────────────────────────────────────────
DATA_PATH = os.path.join(os.path.dirname(__file__), "data", "india_aqi_real.csv")

def load_real_data():
    if not os.path.exists(DATA_PATH):
        return None
    df = pd.read_csv(DATA_PATH, parse_dates=["datetime"])
    required = {"temperature", "humidity", "pm25", "pm10", "no2", "so2", "o3", "co", "aqi"}
    if not required.issubset(df.columns):
        print(f"  ⚠️  CSV missing columns: {required - set(df.columns)}")
        return None
    df = df.dropna(subset=list(required))
    if len(df) < 200:
        print(f"  ⚠️  Only {len(df)} rows in real data — augmenting with synthetic")
        return df
    print(f"  ✅ Loaded {len(df)} real rows from {DATA_PATH}")
    return df

def generate_synthetic(n=8000, seed=42):
    """
    Realistic synthetic data for Indian urban environment.
    Uses NAQI-compatible AQI formula so the model learns correct mappings.
    """
    rng = np.random.default_rng(seed)
    hours       = rng.integers(0, 24, n)
    dows        = rng.integers(0, 7,  n)
    months      = rng.integers(1, 13, n)

    temp = np.clip(28 + 8 * np.sin((hours - 6) * math.pi / 12) + rng.normal(0, 3, n), 15, 45)
    hum  = np.clip(60 + 20 * np.sin((hours - 14) * math.pi / 12) + rng.normal(0, 8, n), 20, 95)

    # Pollutants — realistic Indian urban diurnal profiles
    pm25 = np.clip(40 + 30 * np.sin((hours - 10) * math.pi / 12) + rng.normal(0, 15, n), 5, 250)
    pm10 = np.clip(pm25 * 1.8 + rng.normal(0, 20, n), 10, 450)
    no2  = np.clip(40 + 25 * np.sin((hours - 8) * math.pi / 12) + rng.normal(0, 10, n), 5, 350)
    so2  = np.clip(15 + rng.normal(0, 5, n), 1, 180)
    o3   = np.clip(60 + 40 * np.sin((hours - 14) * math.pi / 12) + rng.normal(0, 10, n), 5, 380)
    co   = np.clip(500 + 200 * np.sin((hours - 10) * math.pi / 12) + rng.normal(0, 80, n), 100, 2800)

    aqi_vals = np.array([aqi_from_pollutants(p25, p10, c, n2, s2, oz)
                         for p25, p10, c, n2, s2, oz in zip(pm25, pm10, co, no2, so2, o3)])

    # Future AQI (1h ahead): drift each pollutant slightly
    pm25_f = np.clip(pm25 * (1 + rng.normal(0.01, 0.05, n)), 5, 250)
    pm10_f = np.clip(pm10 * (1 + rng.normal(0.01, 0.05, n)), 10, 450)
    no2_f  = np.clip(no2  * (1 + rng.normal(0.01, 0.04, n)), 5, 350)
    so2_f  = np.clip(so2  * (1 + rng.normal(0.01, 0.03, n)), 1, 180)
    o3_f   = np.clip(o3   * (1 + rng.normal(0.01, 0.04, n)), 5, 380)
    co_f   = np.clip(co   * (1 + rng.normal(0.01, 0.05, n)), 100, 2800)
    aqi_1h = np.array([aqi_from_pollutants(p25, p10, c, n2, s2, oz)
                       for p25, p10, c, n2, s2, oz in zip(pm25_f, pm10_f, co_f, no2_f, so2_f, o3_f)])

    df = pd.DataFrame({
        "temperature": temp, "humidity": hum,
        "pm25": pm25, "pm10": pm10, "no2": no2, "so2": so2, "o3": o3, "co": co,
        "aqi": aqi_vals, "aqi_1h": aqi_1h,
        "hour": hours, "day_of_week": dows, "month": months,
        "source": "synthetic",
    })
    return df


def prepare_dataset():
    real_df = load_real_data()
    synth   = generate_synthetic(n=8000)

    if real_df is None:
        print("  ℹ️  No real data found — using synthetic dataset")
        df = synth
    else:
        # Build aqi_1h for real data using next row's aqi as label
        real_df = real_df.sort_values("datetime").copy()
        real_df["aqi_1h"] = real_df.groupby("city")["aqi"].shift(-1)
        real_df = real_df.dropna(subset=["aqi_1h"])
        if "hour" not in real_df.columns:
            real_df["hour"] = pd.to_datetime(real_df["datetime"]).dt.hour
        if "day_of_week" not in real_df.columns:
            real_df["day_of_week"] = pd.to_datetime(real_df["datetime"]).dt.dayofweek
        if "month" not in real_df.columns:
            real_df["month"] = pd.to_datetime(real_df["datetime"]).dt.month
        real_df["source"] = "real"

        # Augment: if real data < 2000 rows, pad with synthetic
        if len(real_df) < 2000:
            extra = synth.head(max(2000 - len(real_df), 1000))
            df = pd.concat([real_df, extra], ignore_index=True)
            print(f"  ℹ️  Augmented: {len(real_df)} real + {len(extra)} synthetic = {len(df)} total")
        else:
            df = real_df
            print(f"  ✅ Using real data only ({len(df)} rows)")

    return df


# ─────────────────────────────────────────────────────────────
# 4. Build X, y
# ─────────────────────────────────────────────────────────────
print("\n📦 Loading / generating dataset…")
df = prepare_dataset()

X_rows = []
for _, row in df.iterrows():
    try:
        features = build_features_row(
            temperature = float(row["temperature"]),
            humidity    = float(row["humidity"]),
            pm25        = float(row["pm25"]),
            pm10        = float(row["pm10"]),
            no2         = float(row["no2"]),
            so2         = float(row["so2"]),
            o3          = float(row["o3"]),
            co          = float(row["co"]),
            hour        = int(row.get("hour", 12)),
            day_of_week = int(row.get("day_of_week", 0)),
            month       = int(row.get("month", 6)),
        )
        X_rows.append(features)
    except Exception:
        pass

X = pd.DataFrame(X_rows, columns=FEATURE_NAMES)
y = df["aqi_1h"].values[:len(X)]

print(f"  Dataset: {len(X)} samples | Features: {len(FEATURE_NAMES)}")
print(f"  AQI (target) range: {y.min():.1f} – {y.max():.1f}")

real_frac = (df["source"] == "real").mean() * 100 if "source" in df.columns else 0
print(f"  Real data fraction: {real_frac:.1f}%")

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
print(f"  Train: {len(X_train)} | Test: {len(X_test)}")

# ─────────────────────────────────────────────────────────────
# 5. Train two models, pick the better one
# ─────────────────────────────────────────────────────────────
print("\n🌳 Training RandomForestRegressor…")
rf = RandomForestRegressor(
    n_estimators=200, max_depth=14, min_samples_split=4,
    min_samples_leaf=2, max_features="sqrt", random_state=42, n_jobs=-1)
rf.fit(X_train, y_train)
rf_pred = rf.predict(X_test)
rf_mae  = mean_absolute_error(y_test, rf_pred)
rf_r2   = r2_score(y_test, rf_pred)
print(f"  RF  — MAE: {rf_mae:.2f}  R²: {rf_r2:.4f}")

print("🔥 Training GradientBoostingRegressor…")
gb = GradientBoostingRegressor(
    n_estimators=200, max_depth=6, learning_rate=0.08,
    subsample=0.85, min_samples_split=4, random_state=42)
gb.fit(X_train, y_train)
gb_pred = gb.predict(X_test)
gb_mae  = mean_absolute_error(y_test, gb_pred)
gb_r2   = r2_score(y_test, gb_pred)
print(f"  GB  — MAE: {gb_mae:.2f}  R²: {gb_r2:.4f}")

# Pick best by MAE
if gb_mae <= rf_mae:
    model, y_pred, best_mae, best_r2, model_type = gb, gb_pred, gb_mae, gb_r2, "GradientBoostingRegressor"
    print(f"\n✅ Selected: GradientBoosting (MAE {gb_mae:.2f} < RF {rf_mae:.2f})")
else:
    model, y_pred, best_mae, best_r2, model_type = rf, rf_pred, rf_mae, rf_r2, "RandomForestRegressor"
    print(f"\n✅ Selected: RandomForest (MAE {rf_mae:.2f} < GB {gb_mae:.2f})")

# Full evaluation
rmse   = math.sqrt(mean_squared_error(y_test, y_pred))
acc5   = float(np.mean(np.abs(y_pred - y_test) <= 5) * 100)
acc10  = float(np.mean(np.abs(y_pred - y_test) <= 10) * 100)

print(f"\n📈 Final Evaluation:")
print(f"   MAE               : {best_mae:.2f} AQI points")
print(f"   RMSE              : {rmse:.2f} AQI points")
print(f"   R²                : {best_r2:.4f}")
print(f"   Accuracy (±5 AQI) : {acc5:.1f}%")
print(f"   Accuracy (±10 AQI): {acc10:.1f}%")

# Feature importance (RF only)
if hasattr(model, "feature_importances_"):
    fi = sorted(zip(FEATURE_NAMES, model.feature_importances_), key=lambda x: -x[1])
    print("\n🔑 Top Feature Importances:")
    for name, imp in fi[:8]:
        bar = "█" * int(imp * 50)
        print(f"   {name:<18} {imp:.4f} {bar}")

# ─────────────────────────────────────────────────────────────
# 6. Save model + both runners + metadata
# ─────────────────────────────────────────────────────────────
os.makedirs("models", exist_ok=True)

joblib.dump(model, "models/aqi_rf_model.pkl")       # primary (best)
joblib.dump(rf,    "models/aqi_rf_only.pkl")         # always save RF too
joblib.dump(gb,    "models/aqi_gb_only.pkl")         # always save GB too
print("\n✅ Models saved → models/")

metadata = {
    "model_type"       : model_type,
    "all_models"       : {"rf_mae": round(rf_mae, 2), "gb_mae": round(gb_mae, 2)},
    "features"         : FEATURE_NAMES,
    "n_features"       : len(FEATURE_NAMES),
    "train_samples"    : int(len(X_train)),
    "test_samples"     : int(len(X_test)),
    "real_data_fraction": round(real_frac, 1),
    "metrics": {
        "mae" : round(float(best_mae), 2),
        "rmse": round(float(rmse), 2),
        "r2"  : round(float(best_r2), 4),
        "accuracy_within_5_aqi" : round(float(acc5),  1),
        "accuracy_within_10_aqi": round(float(acc10), 1),
    },
    "feature_description": {
        "temperature"   : "Air temperature (°C) — real sensor",
        "humidity"      : "Relative humidity (%) — real sensor",
        "pm25"          : "PM2.5 fine particles (µg/m³) — OpenAQ/CPCB",
        "pm10"          : "PM10 particles (µg/m³) — OpenAQ/CPCB",
        "no2"           : "Nitrogen dioxide (µg/m³) — OpenAQ/CPCB",
        "so2"           : "Sulphur dioxide (µg/m³) — OpenAQ/CPCB",
        "o3"            : "Ozone (µg/m³) — OpenAQ/CPCB",
        "co"            : "Carbon monoxide (µg/m³) — OpenAQ/CPCB",
        "current_aqi"   : "Current AQI computed from NAQI breakpoints",
        "hour"          : "Hour of day (0–23)",
        "day_of_week"   : "Day of week (0=Mon)",
        "month"         : "Month (1–12)",
        "hour_sin/cos"  : "Cyclical encoding of hour",
        "month_sin/cos" : "Cyclical encoding of month",
        "temp_hum_ratio": "temperature / (humidity+1)",
        "pm25_no2"      : "PM2.5 × NO2 / 1000 interaction",
        "pm10_co"       : "PM10 × CO / 100000 interaction",
    },
    "aqi_thresholds": {
        "Safe"     : "0–50",
        "Moderate" : "51–100",
        "Warning"  : "101–150",
        "Hazardous": "151+",
    },
    "trained_at": datetime.now().isoformat(),
}

with open("models/model_metadata.json", "w") as f:
    json.dump(metadata, f, indent=2)
print("✅ Metadata saved → models/model_metadata.json")
print(f"\n🎉 Training complete! Best model: {model_type}  MAE={best_mae:.2f}\n")
