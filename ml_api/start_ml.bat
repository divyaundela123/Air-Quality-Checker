@echo off
echo ============================================
echo  AeroSense ML API — Starting
echo ============================================
echo.

set PATH=%PATH%;C:\Users\hp\AppData\Local\Programs\Python\Python311;C:\Users\hp\AppData\Local\Programs\Python\Python311\Scripts
set PATH=%PATH%;C:\Program Files\Python311;C:\Program Files\Python311\Scripts

python --version 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Python not found. Install Python 3.11 first.
    pause
    exit /b 1
)

echo Installing dependencies...
pip install -r requirements.txt -q

echo.
echo Training ML model (first run only)...
if not exist models\aqi_rf_model.pkl (
    python train_model.py
) else (
    echo Model already trained. Skipping.
)

echo.
echo Starting Flask ML API on port 5000...
python app.py
pause
