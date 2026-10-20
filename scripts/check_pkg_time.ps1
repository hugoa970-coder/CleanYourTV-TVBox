$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"
& $adb connect $device
Start-Sleep -Milliseconds 400
& $adb -s $device shell "dumpsys package com.gathin.tvhome | grep -iE 'firstinstalltime|lastupdatetime|version'"
