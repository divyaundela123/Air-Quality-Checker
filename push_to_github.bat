@echo off
set PATH=%PATH%;C:\Program Files\Git\bin
echo === AeroSense - Pushing to GitHub ===
git --version
git config user.name "divyaundela123"
git config user.email "divyaundela123@users.noreply.github.com"
git commit -m "AeroSense - Flutter Air Quality Monitor with Supabase backend"
git branch -M main
git push -u origin main
echo === Done! ===
pause
