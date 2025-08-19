@echo off
echo.
echo ====================================
echo  KLB Account Management System
echo ====================================
echo.

echo [1/3] Starting PostgreSQL Database...
cd /d "e:\dowload\klb-account-management\klb-account-management"
docker-compose up -d

echo.
echo [2/3] Starting Backend (Spring Boot)...
echo Please wait for backend to start completely...
start "KLB Backend" cmd /k "cd /d e:\dowload\klb-account-management\klb-account-management && .\mvnw.cmd spring-boot:run"

echo.
echo [3/3] Installing Frontend Dependencies and Starting...
timeout /t 10 /nobreak >nul
cd /d "e:\dowload\klb-account-management\klb-frontend"
call npm install
start "KLB Frontend" cmd /k "npm start"

echo.
echo ====================================
echo  Setup Complete!
echo ====================================
echo.
echo Frontend: http://localhost:3000
echo Backend:  http://localhost:8080
echo Database: localhost:5432
echo.
echo Press any key to exit...
pause >nul
