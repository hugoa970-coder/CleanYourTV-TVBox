$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"
$destDir = "C:\Users\User\.gemini\antigravity\brain\a4ba12ec-59d4-4cf2-82c5-bf931dbc49a0"

& $adb connect $device
Start-Sleep -Milliseconds 400

# Subir a la primera fila (Favoritos)
& $adb -s $device shell input keyevent 19 # UP
Start-Sleep -Milliseconds 400
& $adb -s $device shell input keyevent 19 # UP
Start-Sleep -Milliseconds 400
& $adb -s $device shell input keyevent 21 # LEFT
Start-Sleep -Milliseconds 400
& $adb -s $device shell input keyevent 21 # LEFT
Start-Sleep -Milliseconds 800

& $adb -s $device shell screencap -p /sdcard/screen_horizontal_top.png
& $adb -s $device pull /sdcard/screen_horizontal_top.png "$destDir\screen_horizontal_top.png"
& $adb -s $device shell rm -f /sdcard/screen_horizontal_top.png

Write-Host "Captura screen_horizontal_top.png lista!"
