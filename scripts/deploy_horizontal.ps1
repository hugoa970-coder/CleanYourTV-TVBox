$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"
$apk = "D:\Proyectos\cleanyourtv-main\CleanYourTV-TVBox.apk"
$destDir = "C:\Users\User\.gemini\antigravity\brain\a4ba12ec-59d4-4cf2-82c5-bf931dbc49a0"

Write-Host "Conectando a la TV Box..." -ForegroundColor Cyan
& $adb connect $device
Start-Sleep -Milliseconds 500

Write-Host "Instalando launcher con diseño horizontal..." -ForegroundColor Yellow
& $adb -s $device push $apk /data/local/tmp/tvhome.apk
$res = (& $adb -s $device shell pm install -r /data/local/tmp/tvhome.apk)
& $adb -s $device shell rm -f /data/local/tmp/tvhome.apk
Write-Host "Resultado: $res"

Write-Host "Reiniciando launcher..." -ForegroundColor Yellow
& $adb -s $device shell "am force-stop com.gathin.tvhome; am start -n com.gathin.tvhome/.MainActivity"
Start-Sleep -Seconds 2

Write-Host "Capturando pantalla inicial (Favoritos + Categorías)..." -ForegroundColor Yellow
& $adb -s $device shell screencap -p /sdcard/screen_horizontal_home.png
& $adb -s $device pull /sdcard/screen_horizontal_home.png "$destDir\screen_horizontal_home.png"
& $adb -s $device shell rm -f /sdcard/screen_horizontal_home.png

Write-Host "Navegando a la derecha (DPAD RIGHT)..." -ForegroundColor Yellow
& $adb -s $device shell input keyevent 22
Start-Sleep -Milliseconds 600

Write-Host "Navegando abajo (DPAD DOWN a Películas y Series)..." -ForegroundColor Yellow
& $adb -s $device shell input keyevent 20
Start-Sleep -Milliseconds 800

Write-Host "Capturando pantalla tras DOWN..." -ForegroundColor Yellow
& $adb -s $device shell screencap -p /sdcard/screen_horizontal_down.png
& $adb -s $device pull /sdcard/screen_horizontal_down.png "$destDir\screen_horizontal_down.png"
& $adb -s $device shell rm -f /sdcard/screen_horizontal_down.png

Write-Host "Navegando a la derecha en Películas y Series..." -ForegroundColor Yellow
& $adb -s $device shell input keyevent 22
Start-Sleep -Milliseconds 400
& $adb -s $device shell input keyevent 22
Start-Sleep -Milliseconds 800

Write-Host "Capturando carrusel desplazado..." -ForegroundColor Yellow
& $adb -s $device shell screencap -p /sdcard/screen_horizontal_scroll.png
& $adb -s $device pull /sdcard/screen_horizontal_scroll.png "$destDir\screen_horizontal_scroll.png"
& $adb -s $device shell rm -f /sdcard/screen_horizontal_scroll.png

Write-Host "¡Despliegue y pruebas completadas!" -ForegroundColor Green
