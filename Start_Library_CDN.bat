@echo off
chcp 65001 >nul
title خادم مكتبة أوان - Awan Library CDN
cd /d "%~dp0tools\cdn"

echo.
echo   ============================================
echo    خادم مكتبة "أوان" يعمل الآن على المنفذ 8099
echo   ============================================
echo.
echo   عنوان الشبكة المحلية الذي يدخل في التطبيق:
echo   http://192.168.0.112:8099
echo.
echo   * ضع الموبايل على نفس شبكة الواي فاي.
echo   * لإيقاف الخادم: أغلق هذه النافذة.
echo.

where python >nul 2>nul
if %errorlevel%==0 (
    python -m http.server 8099 --bind 0.0.0.0
) else (
    "C:\Users\ok\AppData\Local\Programs\Python\Python312\python.exe" -m http.server 8099 --bind 0.0.0.0
)
pause
