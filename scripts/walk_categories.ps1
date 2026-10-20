$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"
$artifactDir = "C:\Users\User\.gemini\antigravity\brain\a4ba12ec-59d4-4cf2-82c5-bf931dbc49a0"

& $adb connect $device
Start-Sleep -Milliseconds 400

# Navegar abajo paso 1
Write-Host "Enviando DPAD DOWN 1..."
& $adb -s $device shell input keyevent 20
Start-Sleep -Milliseconds 600

# Navegar abajo paso 2
Write-Host "Enviando DPAD DOWN 2..."
& $adb -s $device shell input keyevent 20
Start-Sleep -Milliseconds 600

& $adb -s $device shell screencap -p /sdcard/screen_cat_step2.png
& $adb -s $device pull /sdcard/screen_cat_step2.png "$artifactDir\screen_cat_step2.png"
& $adb -s $device shell rm -f /sdcard/screen_cat_step2.png

# Navegar abajo paso 3
Write-Host "Enviando DPAD DOWN 3..."
& $adb -s $device shell input keyevent 20
Start-Sleep -Milliseconds 600

& $adb -s $device shell screencap -p /sdcard/screen_cat_step3.png
& $adb -s $device pull /sdcard/screen_cat_step3.png "$artifactDir\screen_cat_step3.png"
& $adb -s $device shell rm -f /sdcard/screen_cat_step3.png

Write-Host "Capturas listas!"
