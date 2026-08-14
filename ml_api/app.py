# ============================================================
# AeroSense — Python ML Prediction API  (v2)
# Model  : GradientBoosting / RandomForest (best from training)
# Port   : 5000
#
# Endpoints:
#   GET  /ml/health             — health + model status
#   POST /ml/predict            — 1-hour AQI prediction
#   POST /ml/predict/future     — multi-hour forecast (2–24 h)
#   GET  /ml/model-info         — model metadata
#   POST /ml/predict/batch      — batch predictions (max 50)
#
# Input fields for /ml/predict:
#   Required : temperature, humidity
#   Optional : pm25, pm10, no2, so2, o3, co  (pollutants from API)
#              lat, lon                       (location for future use)
#   Legacy   : co2, voc  (mapped to co and pm25 if pollutants absent)
# ============================================================

import os, json, math, datetime
import numpy as np
import joblib
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app, origins="*")

# ── Paths ─────────────────────────────────────────────────────
_DIR  = os.path.dirname(__file__)
MODEL_PATH    = os.path.join(_DIR, "models", "aqi_rf_model.pkl")
METADATA_PATH = os.path.join(_DIR, "models", "model_metadata.json")

model    = None
metadata = {}

def load_model():
    global model, metadata
    if os.path.exists(MODEL_PATH):
        model = joblib.load(MODEL_PATH)
        print(f"✅ ML model loaded: {MODEL_PATH}")
    else:
        print("⚠️  No trained model — run: python train_model.py")
    if os.path.exists(METADATA_PATH):
        with open(METADATA_PATH) as f:
            metadata = json.load(f)

load_model()

# ── Feature list (must match train_model.py FEATURE_NAMES) ───
FEATURE_NAMES = [
    "temperature", "humidity",
    "pm25", "pm10", "no2", "so2", "o3", "co",
    "current_aqi",
    "hour", "day_of_week", "month",
    "hour_sin", "hour_cos",
    "month_sin", "month_cos",
    "temp_hum_ratio", "pm25_no2", "pm10_co",
]

# ─────────────────────────────────────────────────────────────
# AQI helpers
# ─────────────────────────────────────────────────────────────
def _sub_index(c, bp):
    for (c_lo, c_hi, bp_lo, bp_hi) in bp:
        if c_lo <= c <= c_hi:
            if c_hi == c_lo: return float(bp_lo)
            return float(((bp_hi - bp_lo) / (c_hi - c_lo)) * (c - c_lo) + bp_lo)
    return 500.0 if c > bp[-1][1] else 0.0

def aqi_from_pollutants(pm25, pm10, co, no2, so2, o3):
    """India NAQI max sub-index. co is in µg/m³."""
    subs = []
    if pm25 >= 0:
        subs.append(_sub_index(pm25, [(0,30,0,50),(30,60,51,100),(60,90,101,200),(90,120,201,300),(120,250,301,400),(250,380,401,500)]))
    if pm10 >= 0:
        subs.append(_sub_index(pm10, [(0,50,0,50),(50,100,51,100),(100,250,101,200),(250,350,201,300),(350,430,301,400),(430,600,401,500)]))
    if no2 >= 0:
        subs.append(_sub_index(no2,  [(0,40,0,50),(40,80,51,100),(80,180,101,200),(180,280,201,300),(280,400,301,400),(400,800,401,500)]))
    if so2 >= 0:
        subs.append(_sub_index(so2,  [(0,40,0,50),(40,80,51,100),(80,380,101,200),(380,800,201,300),(800,1600,301,400),(1600,2100,401,500)]))
    if co >= 0:
        co_mg = co / 1000.0
        subs.append(_sub_index(co_mg, [(0,1,0,50),(1,2,51,100),(2,10,101,200),(10,17,201,300),(17,34,301,400),(34,46,401,500)]))
    if o3 >= 0:
        subs.append(_sub_index(o3,   [(0,50,0,50),(50,100,51,100),(100,168,101,200),(168,208,201,300),(208,748,301,400),(748,1000,401,500)]))
    return float(np.clip(max(subs) if subs else 50.0, 0, 500))

# Legacy formula — used as fallback when no pollutants available
def aqi_legacy(temperature, humidity, co2_ppm, voc_ppb):
    base    = (co2_ppm * 0.05) + (voc_ppb * 0.2)
    penalty = (30 if temperature > 35 else 0) + (10 if humidity > 80 else 0)
    return float(np.clip(base + penalty, 0, 500))

def get_status(aqi):
    if aqi <= 50:  return "Safe"
    if aqi <= 100: return "Moderate"
    if aqi <= 150: return "Warning"
    return "Hazardous"

def get_trend(current, predicted):
    diff = predicted - current
    if abs(diff) < 3:  return "stable"
    if diff > 0:       return "worsening"
    return "improving"

# ─────────────────────────────────────────────────────────────
# Feature builder — 19 features matching train_model.py
# ─────────────────────────────────────────────────────────────
def build_features(temperature, humidity, pm25, pm10, no2, so2, o3, co,
                   hour=None, day_of_week=None, month=None):
    now = datetime.datetime.now()
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

def _parse_inputs(data):
    """
    Parse and normalise all inputs from the request body.
    Accepts new pollutant fields AND legacy co2/voc fields.
    Returns a dict ready for build_features().
    """
    temperature = float(data.get("temperature", 28))
    humidity    = float(data.get("humidity",    60))

    # New pollutant fields (µg/m³ from OpenAQ/CPCB)
    pm25 = data.get("pm25")
    pm10 = data.get("pm10")
    no2  = data.get("no2")
    so2  = data.get("so2")
    o3   = data.get("o3")
    co   = data.get("co")   # µg/m³

    # Legacy fields — map to pollutant equivalents if real data absent
    co2_legacy = data.get("co2")   # ppm
    voc_legacy = data.get("voc")   # ppb

    # If real pollutants not provided, estimate from legacy sensor data
    if pm25 is None and co2_legacy is not None:
        # Rough heuristic: CO2 600 ppm ≈ PM2.5 40 µg/m³ in urban India
        pm25 = float(co2_legacy) * 0.065
    if co is None and co2_legacy is not None:
        # CO2 in ppm → CO in µg/m³ (very rough: CO ≈ CO2 * 0.6)
        co = float(co2_legacy) * 0.6 * 1.145  # ppm→µg/m³
    if no2 is None and voc_legacy is not None:
        # VOC in ppb → NO2 proxy (urban correlation)
        no2 = float(voc_legacy) * 0.18

    # Final defaults for anything still missing
    pm25 = float(pm25) if pm25 is not None else 40.0
    pm10 = float(pm10) if pm10 is not None else pm25 * 1.8
    no2  = float(no2)  if no2  is not None else 40.0
    so2  = float(so2)  if so2  is not None else 15.0
    o3   = float(o3)   if o3   is not None else 60.0
    co   = float(co)   if co   is not None else 600.0

    # Clamp to physical limits
    pm25 = float(np.clip(pm25, 0, 500))
    pm10 = float(np.clip(pm10, 0, 600))
    no2  = float(np.clip(no2,  0, 800))
    so2  = float(np.clip(so2,  0, 2000))
    o3   = float(np.clip(o3,   0, 1000))
    co   = float(np.clip(co,   0, 50000))

    # Lat/lon for future use (location-specific adjustments)
    lat = float(data.get("lat", 28.6139))
    lon = float(data.get("lon", 77.2090))

    return dict(temperature=temperature, humidity=humidity,
                pm25=pm25, pm10=pm10, no2=no2, so2=so2, o3=o3, co=co,
                lat=lat, lon=lon,
                had_real_pollutants=any(data.get(k) is not None for k in ["pm25","pm10","no2","so2","o3","co"]))

def _build_response(current_aqi, predicted_aqi, inp, source="random_forest",
                    horizon_h=1, hour_offset=0):
    trend  = get_trend(current_aqi, predicted_aqi)
    diff   = round(predicted_aqi - current_aqi, 1)

    # Alerts
    alerts = []
    ps     = get_status(predicted_aqi)
    cs     = get_status(current_aqi)
    if ps == "Hazardous":
        alerts.append({"level":"critical", "message":"🚨 Hazardous AQI predicted! Avoid outdoor activity."})
    elif ps == "Warning":
        alerts.append({"level":"warning",  "message":"⚠️ AQI will enter Warning range. Improve ventilation."})
    elif ps == "Moderate" and cs == "Safe":
        alerts.append({"level":"info",     "message":"ℹ️ Air quality will decline from Safe to Moderate."})
    if trend == "worsening" and diff > 15:
        alerts.append({"level":"warning",  "message":"📈 Rapid AQI increase expected. Monitor closely."})
    elif trend == "improving":
        alerts.append({"level":"success",  "message":"✅ Air quality improving. Expect better conditions."})
    if not alerts:
        alerts.append({"level":"info",     "message":"ℹ️ Air quality is expected to remain stable."})

    # Confidence from training R² (per-prediction confidence not available for these models)
    r2   = metadata.get("metrics", {}).get("r2", 0.92)
    conf = round(max(0.70, min(0.99, r2)), 2)

    # 3-hour ML forecast (if model available) or linear extrapolation
    now = datetime.datetime.now()
    forecast = []
    for h in range(1, 4):
        if model is not None:
            future_hour = (now.hour + hour_offset + h) % 24
            fts = build_features(
                inp["temperature"], inp["humidity"],
                inp["pm25"], inp["pm10"], inp["no2"], inp["so2"], inp["o3"], inp["co"],
                hour=future_hour,
            )
            aqi_h = float(np.clip(model.predict([fts])[0], 0, 500))
        else:
            aqi_h = float(np.clip(current_aqi + diff * h * 0.6, 0, 500))
        ts = (now + datetime.timedelta(hours=hour_offset + h)).strftime("%H:%M")
        forecast.append({
            "hour"        : f"+{hour_offset + h}h ({ts})",
            "predicted_aqi": round(aqi_h, 1),
            "status"      : get_status(aqi_h),
            "source"      : "ml_model" if model else "extrapolation",
        })

    return jsonify({
        "current_aqi"       : round(float(current_aqi), 1),
        "predicted_aqi"     : round(float(predicted_aqi), 1),
        "prediction_horizon": f"{horizon_h} hour{'s' if horizon_h > 1 else ''}",
        "current_status"    : cs,
        "predicted_status"  : ps,
        "trend"             : trend,
        "change"            : f"{'+' if diff > 0 else ''}{diff} AQI",
        "confidence"        : conf,
        "confidence_pct"    : f"{int(conf * 100)}%",
        "alerts"            : alerts,
        "forecast_3h"       : forecast,
        "inputs"            : {
            "temperature": inp["temperature"], "humidity": inp["humidity"],
            "pm25": inp["pm25"], "pm10": inp["pm10"],
            "no2" : inp["no2"],  "so2" : inp["so2"],
            "o3"  : inp["o3"],   "co"  : inp["co"],
            "real_pollutants": inp["had_real_pollutants"],
        },
        "model_source"  : source,
        "mae"           : metadata.get("metrics", {}).get("mae", 5.0),
        "data_note"     : (
            "Pollutant values from real sensor/API data."
            if inp["had_real_pollutants"]
            else "Pollutant values estimated from CO2/VOC sensors (legacy). "
                 "For more accurate predictions, provide pm25, pm10, no2, so2, o3, co."
        ),
    })

# ═══════════════════════════════════════════════════════════
# ROUTES
# ═══════════════════════════════════════════════════════════

@app.route("/ml/health", methods=["GET"])
def health():
    return jsonify({
        "status"        : "ok",
        "model_loaded"  : model is not None,
        "model_type"    : metadata.get("model_type", "Unknown"),
        "features"      : len(FEATURE_NAMES),
        "real_data_pct" : metadata.get("real_data_fraction", 0),
        "mae"           : metadata.get("metrics", {}).get("mae", "–"),
        "version"       : "2.0.0",
        "port"          : 5000,
    })

@app.route("/ml/model-info", methods=["GET"])
def model_info():
    if not metadata:
        return jsonify({"error": "Model metadata not available"}), 404
    return jsonify(metadata)

# ── POST /ml/predict ──────────────────────────────────────────
@app.route("/ml/predict", methods=["POST"])
def predict():
    """
    Predict AQI 1 hour ahead.
    Required: temperature, humidity
    Optional: pm25, pm10, no2, so2, o3, co, lat, lon
    Legacy  : co2, voc  (mapped internally)
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "JSON body required"}), 400

    try:
        inp = _parse_inputs(data)
    except (ValueError, TypeError) as e:
        return jsonify({"error": f"Invalid input: {e}"}), 400

    if not (0 <= inp["temperature"] <= 60):
        return jsonify({"error": "temperature must be 0–60°C"}), 400
    if not (0 <= inp["humidity"] <= 100):
        return jsonify({"error": "humidity must be 0–100%"}), 400

    current_aqi = aqi_from_pollutants(
        inp["pm25"], inp["pm10"], inp["co"], inp["no2"], inp["so2"], inp["o3"])

    if model is None:
        predicted_aqi = current_aqi * 1.02
        source = "rule_based"
    else:
        fts = build_features(
            inp["temperature"], inp["humidity"],
            inp["pm25"], inp["pm10"], inp["no2"], inp["so2"], inp["o3"], inp["co"],
        )
        predicted_aqi = float(np.clip(model.predict([fts])[0], 0, 500))
        source = "ml_model"

    return _build_response(current_aqi, predicted_aqi, inp, source=source)

# ── POST /ml/predict/future ───────────────────────────────────
@app.route("/ml/predict/future", methods=["POST"])
def predict_future():
    """
    Multi-hour AQI forecast.
    Body: { ...sensor_fields..., "hours": 6 }
    Returns predictions for each hour up to `hours` (max 24).
    Requires model to be loaded; returns 503 otherwise.
    """
    if model is None:
        return jsonify({"error": "Model not loaded. Run train_model.py first."}), 503

    data = request.get_json()
    if not data:
        return jsonify({"error": "JSON body required"}), 400

    try:
        inp = _parse_inputs(data)
    except (ValueError, TypeError) as e:
        return jsonify({"error": f"Invalid input: {e}"}), 400

    hours = min(int(data.get("hours", 6)), 24)
    now   = datetime.datetime.now()
    base_aqi = aqi_from_pollutants(
        inp["pm25"], inp["pm10"], inp["co"], inp["no2"], inp["so2"], inp["o3"])

    predictions = []
    for h in range(1, hours + 1):
        future_hour = (now.hour + h) % 24
        future_dow  = (now.weekday() + (now.hour + h) // 24) % 7
        future_mon  = now.month

        fts = build_features(
            inp["temperature"], inp["humidity"],
            inp["pm25"], inp["pm10"], inp["no2"], inp["so2"], inp["o3"], inp["co"],
            hour=future_hour, day_of_week=future_dow, month=future_mon,
        )
        aqi_h = float(np.clip(model.predict([fts])[0], 0, 500))
        ts    = (now + datetime.timedelta(hours=h)).strftime("%Y-%m-%dT%H:%M")
        predictions.append({
            "hour"         : h,
            "datetime"     : ts,
            "predicted_aqi": round(aqi_h, 1),
            "status"       : get_status(aqi_h),
            "trend"        : get_trend(base_aqi, aqi_h),
        })

    return jsonify({
        "base_aqi"      : round(base_aqi, 1),
        "base_status"   : get_status(base_aqi),
        "hours_ahead"   : hours,
        "predictions"   : predictions,
        "model_source"  : "ml_model",
        "mae"           : metadata.get("metrics", {}).get("mae", 5.0),
        "data_note"     : (
            "Pollutant values from real sensor/API data."
            if inp["had_real_pollutants"]
            else "Estimated from legacy sensor inputs."
        ),
    })

# ── POST /ml/predict/batch ────────────────────────────────────
@app.route("/ml/predict/batch", methods=["POST"])
def predict_batch():
    if model is None:
        return jsonify({"error": "Model not loaded. Run train_model.py first."}), 503

    data     = request.get_json() or {}
    readings = data.get("readings", [])
    if not readings or not isinstance(readings, list):
        return jsonify({"error": "readings array required"}), 400

    results = []
    for r in readings[:50]:
        try:
            inp      = _parse_inputs(r)
            fts      = build_features(
                inp["temperature"], inp["humidity"],
                inp["pm25"], inp["pm10"], inp["no2"], inp["so2"], inp["o3"], inp["co"],
            )
            pred_aqi = float(np.clip(model.predict([fts])[0], 0, 500))
            curr_aqi = aqi_from_pollutants(
                inp["pm25"], inp["pm10"], inp["co"], inp["no2"], inp["so2"], inp["o3"])
            results.append({
                "current_aqi"  : round(curr_aqi, 1),
                "predicted_aqi": round(pred_aqi, 1),
                "status"       : get_status(pred_aqi),
                "trend"        : get_trend(curr_aqi, pred_aqi),
            })
        except Exception:
            results.append({"error": "invalid reading"})

    return jsonify({"predictions": results, "count": len(results)})

# ─────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("🚀 AeroSense ML API v2  →  http://localhost:5000")
    app.run(host="0.0.0.0", port=5000, debug=False)
