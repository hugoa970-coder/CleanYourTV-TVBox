$apkPath = "D:\Proyectos\cleanyourtv-main\CleanYourTV-TVBox.apk"
$apk = Get-Item $apkPath
$bytes = $apk.Length
$kb = [math]::Round($bytes / 1KB, 2)
$mb = [math]::Round($bytes / 1MB, 2)

Write-Host "========================================="
Write-Host "   INFORMACION DE PESO Y ALMACENAMIENTO"
Write-Host "========================================="
Write-Host "Archivo APK: $apkPath"
Write-Host "Tamano exacto: $bytes bytes"
Write-Host "Tamano en KB:  $kb KB"
Write-Host "Tamano en MB:  $mb MB"

# Crear carpeta permanente de releases
$releaseDir = "D:\Proyectos\cleanyourtv-main\release\CleanYourTV_Horizontal_Fusion_Final"
New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
$finalApkCopy = "$releaseDir\CleanYourTV-Horizontal-Fusion.apk"
Copy-Item $apkPath $finalApkCopy -Force
Write-Host "`nCopia de seguridad guardada en:"
Write-Host "$finalApkCopy"

# Crear backup en carpeta backups\X96Air_P3
$backupCopy = "D:\Proyectos\cleanyourtv-main\backups\X96Air_P3\CleanYourTV-TVBox-Horizontal.apk"
Copy-Item $apkPath $backupCopy -Force
Write-Host "Copia de respaldo para la X96 Air:"
Write-Host "$backupCopy"

# Git tag y branch
Set-Location "D:\Proyectos\cleanyourtv-main"
git tag -f v2.4-horizontal-fusion
git branch -f backup/v2.4-horizontal
Write-Host "`nGit tag y branch creados:"
Write-Host "Tag: v2.4-horizontal-fusion"
Write-Host "Branch: backup/v2.4-horizontal"

# Obtener memoria y peso en el TV Box via ADB
$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"
& $adb connect $device
Start-Sleep -Milliseconds 400

Write-Host "`n--- CONSUMO DE MEMORIA RAM EN LA TV BOX (PSS) ---"
& $adb -s $device shell dumpsys meminfo com.gathin.tvhome | Select-String -Pattern "TOTAL PSS|TOTAL RSS|TOTAL:"

Write-Host "`n--- TAMANO EN DISCO EN LA TV BOX ---"
& $adb -s $device shell "pm path com.gathin.tvhome"
& $adb -s $device shell "du -h /data/app/com.gathin.tvhome* /data/data/com.gathin.tvhome"
