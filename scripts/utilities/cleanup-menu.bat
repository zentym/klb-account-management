@echo off
echo ===================================================
echo            DON SACH KLB PROJECT
echo ===================================================

echo.
echo [1] Don sach nhanh (containers + build artifacts)
echo [2] Don sach day du (bao gom logs, temp files)  
echo [3] Reset project hoan toan (XOA TAT CA!)
echo [4] Chi don sach Docker
echo [5] Chi don sach Maven build
echo [0] Thoat
echo.

set /p choice="Chon lua chon (0-5): "

if "%choice%"=="1" goto quick_cleanup
if "%choice%"=="2" goto full_cleanup  
if "%choice%"=="3" goto reset_project
if "%choice%"=="4" goto docker_only
if "%choice%"=="5" goto maven_only
if "%choice%"=="0" goto exit
goto invalid

:quick_cleanup
echo.
echo Dang thuc hien don sach nhanh...
powershell -ExecutionPolicy Bypass -File "quick-cleanup.ps1"
goto end

:full_cleanup  
echo.
echo Dang thuc hien don sach day du...
powershell -ExecutionPolicy Bypass -File "cleanup-all.ps1" -Force
goto end

:reset_project
echo.
echo CANH BAO: Se xoa tat ca du lieu!
set /p confirm="Ban co chac chan? (YES de xac nhan): "
if "%confirm%"=="YES" (
    powershell -ExecutionPolicy Bypass -File "reset-project.ps1" -ConfirmAll
) else (
    echo Huy bo reset project.
)
goto end

:docker_only
echo.
echo Don sach Docker containers va images...
docker-compose -f "kienlongbank-project\docker-compose.yml" down --remove-orphans
docker stop klb-postgres klb-postgres-customer klb-customer-service klb-account-management 2>nul
docker rm klb-postgres klb-postgres-customer klb-customer-service klb-account-management 2>nul
echo Hoan thanh don sach Docker!
goto end

:maven_only
echo.
echo Don sach Maven build artifacts...
for /d %%i in (kienlongbank-project\*) do (
    if exist "%%i\pom.xml" (
        if exist "%%i\target" (
            rmdir /s /q "%%i\target"
            echo Da xoa target: %%~nxi
        )
    )
)
echo Hoan thanh don sach Maven!
goto end

:invalid
echo Lua chon khong hop le!
pause
goto menu

:end
echo.
echo Hoan thanh!
pause

:exit
