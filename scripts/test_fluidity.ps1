$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"

Write-Host "Conectando..."
& $adb connect $device
Start-Sleep -Milliseconds 300

Write-Host "Simulando navegacion rapida con control remoto..."
# Navegar rapido horizontal y verticalmente
& $adb -s $device shell input keyevent 22 # RIGHT
Start-Sleep -Milliseconds 150
& $adb -s $device shell input keyevent 22 # RIGHT
Start-Sleep -Milliseconds 150
& $adb -s $device shell input keyevent 22 # RIGHT
Start-Sleep -Milliseconds 150
& $adb -s $device shell input keyevent 20 # DOWN
Start-Sleep -Milliseconds 150
& $adb -s $device shell input keyevent 22 # RIGHT
Start-Sleep -Milliseconds 150
& $adb -s $device shell input keyevent 22 # RIGHT
Start-Sleep -Milliseconds 150
& $adb -s $device shell input keyevent 20 # DOWN
Start-Sleep -Milliseconds 150
& $adb -s $device shell input keyevent 21 # LEFT
Start-Sleep -Milliseconds 150
& $adb -s $device shell input keyevent 19 # UP
Start-Sleep -Milliseconds 150
& $adb -s $device shell input keyevent 19 # UP
Start-Sleep -Milliseconds 500

Write-Host "Tomando captura tras navegacion rapida..."
& $adb -s $device shell screencap -p /sdcard/screen_fluid_test.png
& $adb -s $device pull /sdcard/screen_fluid_test.png "C:\Users\User\.gemini\antigravity\brain\a4ba12ec-59d4-4cf2-82c5-bf931dbc49a0\screen_fluid_test.png"
& $adb -s $device shell rm -f /sdcard/screen_fluid_test.png

Write-Host "Prueba de fluidez completada con exito."
