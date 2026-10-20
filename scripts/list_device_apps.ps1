$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"

& $adb connect $device
Start-Sleep -Milliseconds 400

Write-Host "Apps Leanback:"
& $adb -s $device shell "cmd package query-activities --brief -c android.intent.category.LEANBACK_LAUNCHER"

Write-Host "`nApps Standard Launcher:"
& $adb -s $device shell "cmd package query-activities --brief -c android.intent.category.LAUNCHER"
