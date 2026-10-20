$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"

& $adb connect $device
Start-Sleep -Milliseconds 400

# Ver qué vista tiene el foco en la UI
Write-Host "--- DUMPSYS ACTIVITY FOCUS ---"
& $adb -s $device shell "dumpsys activity top | grep -iE 'View Hierarchy|focus|ResumedActivity'"

Write-Host "--- SENDING DPAD RIGHT THEN DOWN ---"
& $adb -s $device shell input keyevent 22 # RIGHT
Start-Sleep -Milliseconds 500
& $adb -s $device shell input keyevent 20 # DOWN
Start-Sleep -Milliseconds 500
& $adb -s $device shell "dumpsys activity top | grep -iE 'mFocusedView|focus'"
