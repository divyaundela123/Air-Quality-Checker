@echo off
set PATH=%PATH%;C:\Program Files\Git\bin
git add .github
git commit -m "Add GitHub Actions CI workflow"
git push origin main
echo Done! Visit https://github.com/divyaundela123/Air-Quality-Checker/actions
pause
