@echo off
setlocal EnableDelayedExpansion

echo.
echo ====================================
echo  KLB Account Management - STOP ALL
echo ====================================
echo.

set "SERVICES_STOPPED=0"

:: Function to check if port is in use
echo [INFO] Checking current service status...

:: Check for Node.js processes (port 3000)
netstat -ano | findstr ":3000" >nul 2>&1
if !errorlevel!==0 (
    echo ^> Frontend service detected on port 3000
    set /a SERVICES_STOPPED+=1
)

:: Check for Java processes (port 8080)
netstat -ano | findstr ":8080" >nul 2>&1
if !errorlevel!==0 (
    echo ^> Backend service detected on port 8080
    set /a SERVICES_STOPPED+=1
)

:: Check Docker containers
docker ps --format "table {{.Names}}" | findstr "klb" >nul 2>&1
if !errorlevel!==0 (
    echo ^> Database containers detected
    set /a SERVICES_STOPPED+=1
)

if !SERVICES_STOPPED!==0 (
    echo ^> No services are currently running
    echo.
    goto :end
)

echo.
echo [1/5] Stopping Frontend (Node.js on port 3000)...
:: Find and kill processes on port 3000
for /f "tokens=5" %%i in ('netstat -ano ^| findstr ":3000"') do (
    taskkill /f /pid %%i >nul 2>&1
    if !errorlevel!==0 (
        echo ^> Killed process %%i on port 3000
    )
)

:: Additional Node.js cleanup
taskkill /f /im node.exe >nul 2>&1
taskkill /f /im "npm.exe" >nul 2>&1
taskkill /f /im "npx.exe" >nul 2>&1
echo ^> Frontend processes cleaned up

echo.
echo [2/5] Stopping Backend (Java on port 8080)...
:: Find and kill processes on port 8080
for /f "tokens=5" %%i in ('netstat -ano ^| findstr ":8080"') do (
    taskkill /f /pid %%i >nul 2>&1
    if !errorlevel!==0 (
        echo ^> Killed process %%i on port 8080
    )
)

:: Additional Java cleanup
taskkill /f /im java.exe >nul 2>&1
echo ^> Backend processes cleaned up

echo.
echo [3/5] Stopping Maven processes...
:: Kill Maven wrapper processes
taskkill /f /im mvnw.exe >nul 2>&1
taskkill /f /im mvnw.cmd >nul 2>&1
taskkill /f /im "Maven Integration for Eclipse JVM" >nul 2>&1
echo ^> Maven processes cleaned up

echo.
echo [4/5] Stopping Database (Docker)...
:: Stop Docker containers
cd /d "e:\dowload\klb-account-management\klb-account-management"
echo ^> Stopping PostgreSQL containers...
docker-compose down --volumes --remove-orphans
if !errorlevel!==0 (
    echo ^> Database containers stopped successfully
) else (
    echo ^> Warning: Failed to stop some containers or no containers running
)

echo.
echo [5/5] Final cleanup...
:: Kill any remaining processes by window title or command line
taskkill /f /fi "WINDOWTITLE eq *KLB*" >nul 2>&1
taskkill /f /fi "WINDOWTITLE eq *React*" >nul 2>&1
taskkill /f /fi "WINDOWTITLE eq *Spring*" >nul 2>&1

:: Kill processes by command line (for hidden processes)
wmic process where "CommandLine like '%%spring-boot:run%%'" delete >nul 2>&1
wmic process where "CommandLine like '%%npm start%%'" delete >nul 2>&1
wmic process where "CommandLine like '%%serve -s build%%'" delete >nul 2>&1

echo ^> Additional cleanup completed

:: Wait a moment for processes to fully terminate
timeout /t 2 /nobreak >nul 2>&1

echo.
echo [VERIFICATION] Checking if services are stopped...
:: Verify ports are free
netstat -ano | findstr ":3000" >nul 2>&1
if !errorlevel!==0 (
    echo ^> Warning: Port 3000 still in use
) else (
    echo ^> Port 3000 is now free ✓
)

netstat -ano | findstr ":8080" >nul 2>&1
if !errorlevel!==0 (
    echo ^> Warning: Port 8080 still in use
) else (
    echo ^> Port 8080 is now free ✓
)

:: Check Docker containers
docker ps --format "table {{.Names}}" | findstr "klb" >nul 2>&1
if !errorlevel!==0 (
    echo ^> Warning: Some KLB containers may still be running
) else (
    echo ^> All KLB containers stopped ✓
)

:end
echo.
echo ====================================
echo  All Services Stopped Successfully!
echo ====================================
echo.
echo Next steps:
echo   • To start all services: start-all.bat
echo   • To start only database: start-databases.ps1
echo   • To check system status: check-system.ps1
echo.
echo Press any key to exit...
pause >nul
