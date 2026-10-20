$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"
$apk = "D:\Proyectos\cleanyourtv-main\CleanYourTV-TVBox.apk"
$destDir = "D:\Proyectos\cleanyourtv-main\backups\X96Air_P3"

Write-Host "Conectando a la TV Box..." -ForegroundColor Cyan
& $adb connect $device
Start-Sleep -Milliseconds 500

Write-Host "Instalando launcher con categorías organizadas..." -ForegroundColor Yellow
& $adb -s $device push $apk /data/local/tmp/tvhome.apk
$res = (& $adb -s $device shell pm install -r /data/local/tmp/tvhome.apk)
& $adb -s $device shell rm -f /data/local/tmp/tvhome.apk
Write-Host "Resultado: $res"

Write-Host "Reiniciando launcher..." -ForegroundColor Yellow
& $adb -s $device shell "am force-stop com.gathin.tvhome; am start -n com.gathin.tvhome/.MainActivity"
Start-Sleep -Seconds 2

Write-Host "Capturando pantalla de inicio..." -ForegroundColor Yellow
& $adb -s $device shell screencap -p /sdcard/screen_home_cat.png
& $adb -s $device pull /sdcard/screen_home_cat.png "C:\Users\User\.gemini\antigravity\brain\a4ba12ec-59d4-4cf2-82c5-bf931dbc49a0\screen_home_cat.png"
& $adb -s $device shell rm -f /sdcard/screen_home_cat.png

Write-Host "Navegando hacia abajo para ver categorías..." -ForegroundColor Yellow
& $adb -s $device shell input keyevent 20 # DPAD DOWN
Start-Sleep -Milliseconds 800

Write-Host "Capturando pantalla de categorías organizadas..." -ForegroundColor Yellow
& $adb -s $device shell screencap -p /sdcard/screen_categories.png
& $adb -s $device pull /sdcard/screen_categories.png "C:\Users\User\.gemini\antigravity\brain\a4ba12ec-59d4-4cf2-82c5-bf931dbc49a0\screen_categories.png"
& $adb -s $device shell rm -f /sdcard/screen_categories.png

Write-Host "¡Completado!" -ForegroundColor Green
