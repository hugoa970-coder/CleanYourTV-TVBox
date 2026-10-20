$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"
$artifactDir = "C:\Users\User\.gemini\antigravity\brain\a4ba12ec-59d4-4cf2-82c5-bf931dbc49a0"

Write-Host "Conectando ADB..."
& $adb connect $device
Start-Sleep -Milliseconds 600

Write-Host "Enviando DPAD DOWN..."
& $adb -s $device shell input keyevent 20
Start-Sleep -Milliseconds 800

& $adb -s $device shell screencap -p /sdcard/cat_down1.png
& $adb -s $device pull /sdcard/cat_down1.png "$artifactDir\cat_down1.png"
& $adb -s $device shell rm -f /sdcard/cat_down1.png

Write-Host "Enviando otro DPAD DOWN..."
& $adb -s $device shell input keyevent 20
Start-Sleep -Milliseconds 800

& $adb -s $device shell screencap -p /sdcard/cat_down2.png
& $adb -s $device pull /sdcard/cat_down2.png "$artifactDir\cat_down2.png"
& $adb -s $device shell rm -f /sdcard/cat_down2.png

Write-Host "Listo!"
