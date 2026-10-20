$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"
$pkg = "com.gathin.tvhome"
$dir = "/sdcard/Android/data/$pkg/files"
$themeDir = "D:\Proyectos\cleanyourtv-main\themes\aurora"
$revision = [guid]::NewGuid().ToString('N')

Write-Host "Conectando a la TV Box..." -ForegroundColor Cyan
& $adb connect $device
Start-Sleep -Milliseconds 500

Write-Host "Aplicando tema Aurora..." -ForegroundColor Yellow
& $adb -s $device shell "mkdir -p $dir"
& $adb -s $device push "$themeDir\config.json" "$dir/config.json"
& $adb -s $device push "$themeDir\wallpaper.jpg" "$dir/wallpaper.jpg"
& $adb -s $device shell "printf '%s' '$revision' > $dir/theme_revision"

Write-Host "Reiniciando Launcher..." -ForegroundColor Yellow
& $adb -s $device shell "am force-stop $pkg; am start -n $pkg/.MainActivity"
Start-Sleep -Seconds 2

Write-Host "Tomando captura de pantalla..." -ForegroundColor Yellow
& $adb -s $device shell screencap -p /sdcard/screen_aurora.png
& $adb -s $device pull /sdcard/screen_aurora.png "C:\Users\User\.gemini\antigravity\brain\a4ba12ec-59d4-4cf2-82c5-bf931dbc49a0\screen_aurora.png"
& $adb -s $device shell rm -f /sdcard/screen_aurora.png

Write-Host "¡Tema Aurora aplicado con exito!" -ForegroundColor Green
