$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"
$artifactDir = "C:\Users\User\.gemini\antigravity\brain\a4ba12ec-59d4-4cf2-82c5-bf931dbc49a0"

Write-Host "Conectando ADB..."
& $adb connect $device
Start-Sleep -Milliseconds 600

# Asegurar que com.gathin.tvhome este enfocado
& $adb -s $device shell am start -n com.gathin.tvhome/.MainActivity
Start-Sleep -Seconds 1

Write-Host "Capturando pantalla inicial..."
& $adb -s $device shell screencap -p /sdcard/s0.png
& $adb -s $device pull /sdcard/s0.png "$artifactDir\s0.png"
& $adb -s $device shell rm -f /sdcard/s0.png

Write-Host "Presionando DOWN..."
& $adb -s $device shell input keyevent 20
Start-Sleep -Seconds 1

Write-Host "Capturando pantalla tras DOWN 1..."
& $adb -s $device shell screencap -p /sdcard/s1.png
& $adb -s $device pull /sdcard/s1.png "$artifactDir\s1.png"
& $adb -s $device shell rm -f /sdcard/s1.png

Write-Host "Presionando DOWN otra vez..."
& $adb -s $device shell input keyevent 20
Start-Sleep -Seconds 1

Write-Host "Capturando pantalla tras DOWN 2..."
& $adb -s $device shell screencap -p /sdcard/s2.png
& $adb -s $device pull /sdcard/s2.png "$artifactDir\s2.png"
& $adb -s $device shell rm -f /sdcard/s2.png

# Verificar focused window y view en dumpsys
Write-Host "Verificando foco actual en ventana:"
& $adb -s $device shell dumpsys window | Select-String "mCurrentFocus|mFocusedApp"

Write-Host "Fin de inspección."
