@echo off
title کارنما - نصب
echo ========================================
echo   کارنما - WorkLog Desktop App
echo   نسخه ۱.۰.۰
echo ========================================
echo.
echo در حال کپی کردن فایل‌ها...
mkdir "%USERPROFILE%\Desktop\Karnama" 2>nul
xcopy /E /I /Y "%~dp0Release" "%USERPROFILE%\Desktop\Karnama" >nul
echo.
echo نصب کامل شد!
echo فایل‌ها در: %USERPROFILE%\Desktop\Karnama
echo برای اجرا: Karnama.exe را باز کنید
echo.
pause
