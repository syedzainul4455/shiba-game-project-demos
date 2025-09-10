@echo off
cd /d "C:\Users\toong\OneDrive\Documents\my-shiba-game--1"

git add .
git commit -m "Auto update from script"
git pull origin main --rebase
git push origin main

echo.
echo ✅ Game folder updated to GitHub!
pause
