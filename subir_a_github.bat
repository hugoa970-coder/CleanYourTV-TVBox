@echo off
title Subir CleanYourTV-TVBox a GitHub
color 0A
echo ===================================================
echo     SUBIENDO PROYECTO A TU GITHUB (hugoa970-coder)
echo ===================================================
echo.
echo 1. Si es tu primera vez, se abrira una ventana en tu
echo    navegador para autorizar el acceso a GitHub.
echo    Haz clic en 'Authorize' o 'Sign in with your browser'.
echo.
echo Subiendo rama master y etiquetas de version...
cd /d "%~dp0"
git push -u origin master --tags
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===================================================
    echo   EXITO: Proyecto y versiones subidas a GitHub!
    echo ===================================================
) else (
    echo.
    echo ===================================================
    echo   Ocurrio un error al subir. Revisa la conexion
    echo   o la autorizacion en el navegador.
    echo ===================================================
)
echo.
pause
