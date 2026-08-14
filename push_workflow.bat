@echo off
set PATH=%PATH%;C:\Program Files\Git\bin
echo === Pushing GitHub Actions Workflow ===
git add .github/
git add .github/workflows/aerosense-ci.yml
git add .github/SECRETS.md
git commit -m "Add GitHub Actions CI workflow: selenium, appium, load, security, summary"
git push origin main
echo === Workflow pushed to GitHub! ===
echo Visit: https://github.com/divyaundela123/Air-Quality-Checker/actions
pause
