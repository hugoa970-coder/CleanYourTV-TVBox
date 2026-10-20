$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"

& $adb connect $device
Start-Sleep -Milliseconds 400

Write-Host "=== DUMPSYS POWER ==="
& $adb -s $device shell dumpsys power | Select-String "mHolding|Display Power|mWakefulness"

Write-Host "=== CURRENT FOCUS ==="
& $adb -s $device shell "dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'"

Write-Host "=== TOP ACTIVITIES ==="
& $adb -s $device shell "dumpsys activity activities | grep -E 'ResumedActivity|topResumedActivity'"
