# Script de Instalación y Adaptación de CleanYourTV para TV Box
# Requiere que la TV Box tenga la Depuración USB (o por red) activada.
param(
    [string]$TvHost = "",
    [switch]$KeepStockLauncher,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = New-Object System.Text.UTF8Encoding $false

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   CLEANYOURTV - INSTALADOR ADAPTADO PARA TV BOX         " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Localizar ADB
$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) { $adb = $adbCmd.Source }
    else { throw "No se encontro adb.exe. Asegurate de que Android SDK platform-tools este disponible." }
}
Write-Host "[+] ADB localizado en: $adb" -ForegroundColor Green

# 2. Conectar al dispositivo
if ($TvHost) {
    if ($TvHost -notmatch ':\d+$') { $deviceTarget = "$TvHost`:5555" }
    else { $deviceTarget = $TvHost }
    Write-Host "[*] Conectando a la TV Box en $deviceTarget..." -ForegroundColor Yellow
    & $adb connect $deviceTarget
    Start-Sleep -Seconds 2
} else {
    $devices = & $adb devices | Select-String -Pattern "\b(device|offline|unauthorized)\b"
    if ($devices.Count -eq 0) {
        Write-Host "No se especifico IP y no hay dispositivos conectados por USB/Red." -ForegroundColor Red
        $TvHost = Read-Host "Ingresa la IP de tu TV Box (ejemplo: 192.168.1.50)"
        if (-not $TvHost) { throw "Dirección IP obligatoria." }
        $deviceTarget = "$TvHost`:5555"
        Write-Host "[*] Conectando a $deviceTarget..." -ForegroundColor Yellow
        & $adb connect $deviceTarget
        Start-Sleep -Seconds 2
    } else {
        $firstDev = ($devices[0].Line -split '\s+')[0]
        $deviceTarget = $firstDev
        Write-Host "[+] Dispositivo detectado: $deviceTarget" -ForegroundColor Green
    }
}

# Verificar conexión activa
$state = (& $adb -s $deviceTarget get-state 2>&1).Trim()
if ($state -ne 'device') {
    if ($state -eq 'unauthorized') {
        throw "El dispositivo aparece como 'No autorizado'. Revisa la pantalla de tu TV Box y acepta la casilla 'Permitir depuracion USB'."
    }
    throw "No se pudo comunicar con $deviceTarget (Estado: $state). Verifica que la TV Box este encendida y en la misma red Wi-Fi."
}

# 3. Obtener especificaciones de la TV Box
$model = (& $adb -s $deviceTarget shell getprop ro.product.model).Trim()
$mfg = (& $adb -s $deviceTarget shell getprop ro.product.manufacturer).Trim()
$androidVer = (& $adb -s $deviceTarget shell getprop ro.build.version.release).Trim()
$sdkVer = (& $adb -s $deviceTarget shell getprop ro.build.version.sdk).Trim()

Write-Host "==========================================================" -ForegroundColor DarkGray
Write-Host " Dispositivo detectado:" -ForegroundColor Cyan
Write-Host " - Modelo:       $mfg $model" -ForegroundColor White
Write-Host " - Android:      $androidVer (SDK $sdkVer)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor DarkGray

# 4. Crear Carpeta de Respaldo
$backupDir = Join-Path $PSScriptRoot "backups\$($model -replace '[\\/:\*\?""<>\|]', '_')"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
Write-Host "[*] Creando respaldo de seguridad en $backupDir..." -ForegroundColor Yellow

& $adb -s $deviceTarget shell pm list packages -f > (Join-Path $backupDir "packages-all.txt")
& $adb -s $deviceTarget shell pm list packages -d > (Join-Path $backupDir "packages-disabled.txt")
& $adb -s $deviceTarget shell getprop > (Join-Path $backupDir "getprop.txt")
Write-Host "[+] Respaldo completado con exito." -ForegroundColor Green

# 5. Compilar si es necesario
$apkPath = Join-Path $PSScriptRoot "launcher\app\build\outputs\apk\release\app-release.apk"
if (-not (Test-Path $apkPath) -or (-not $SkipBuild)) {
    Write-Host "[*] Verificando compilacion del launcher adaptado..." -ForegroundColor Yellow
    $javaCandidate = "C:\Program Files\Android\Android Studio1\jbr"
    if (Test-Path "$javaCandidate\bin\java.exe") {
        $env:JAVA_HOME = $javaCandidate
    }
    $env:ANDROID_HOME = "C:\Users\User\AppData\Local\Android\Sdk"
    Push-Location (Join-Path $PSScriptRoot "launcher")
    cmd /c "set JAVA_HOME=$($env:JAVA_HOME)&& set ANDROID_HOME=$($env:ANDROID_HOME)&& gradlew.bat assembleRelease -q --console=plain"
    Pop-Location
}

if (-not (Test-Path $apkPath)) { throw "No se encontro el APK compilado en $apkPath" }

# 6. Instalar APK en la TV Box
Write-Host "[*] Instalando CleanYourTV Launcher en la TV Box..." -ForegroundColor Yellow
& $adb -s $deviceTarget push $apkPath /data/local/tmp/tvhome.apk
$installRes = & $adb -s $deviceTarget shell pm install -r /data/local/tmp/tvhome.apk
& $adb -s $deviceTarget shell rm -f /data/local/tmp/tvhome.apk

if ($installRes -notmatch 'Success') {
    throw "Fallo la instalacion del APK: $installRes"
}
Write-Host "[+] Launcher instalado correctamente." -ForegroundColor Green

# 7. Permisos y optimización
Write-Host "[*] Concediendo permisos y optimizando inicio..." -ForegroundColor Yellow
& $adb -s $deviceTarget shell pm grant com.gathin.tvhome android.permission.ACCESS_FINE_LOCATION 2>$null
& $adb -s $deviceTarget shell cmd package compile -m speed -f com.gathin.tvhome 2>$null

# 8. Iniciar el nuevo launcher
Write-Host "[*] Iniciando el nuevo launcher..." -ForegroundColor Yellow
& $adb -s $deviceTarget shell am start -W -n com.gathin.tvhome/.MainActivity

# 9. Configurar como Launcher por defecto
Write-Host "[*] Configurando como pantalla de inicio predeterminada..." -ForegroundColor Yellow
& $adb -s $deviceTarget shell cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity

# 10. Detección y gestión del Launcher de Fábrica (Stock)
$currentHome = (& $adb -s $deviceTarget shell "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME" | Select-Object -Last 1).Trim().Split('/')[0]
Write-Host "[i] Launcher detectado previamente: $currentHome" -ForegroundColor Cyan

if (-not $KeepStockLauncher -and $currentHome -ne "com.gathin.tvhome" -and $currentHome -ne "android") {
    $confirm = Read-Host "¿Deseas deshabilitar el launcher de fabrica '$currentHome' para evitar publicidad y liberar memoria RAM? (S/N)"
    if ($confirm -eq 'S' -or $confirm -eq 's') {
        & $adb -s $deviceTarget shell pm disable-user --user 0 $currentHome
        Write-Host "[+] Launcher de fabrica deshabilitado: $currentHome" -ForegroundColor Green
        
        # Crear script de restauracion individual
        $restoreContent = @"
& "$adb" -s $deviceTarget shell pm enable $currentHome
& "$adb" -s $deviceTarget shell cmd package set-home-activity --user 0 $currentHome
Write-Host "Launcher de fabrica restaurado." -ForegroundColor Green
"@
        $restoreContent | Out-File -Encoding utf8 (Join-Path $backupDir "restaurar_launcher_original.ps1")
        Write-Host "[i] Se guardo un script de restauracion en: $backupDir\restaurar_launcher_original.ps1" -ForegroundColor Gray
    } else {
        Write-Host "[i] El launcher de fabrica se mantuvo activo como respaldo." -ForegroundColor Yellow
    }
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   ¡INSTALACION Y ADAPTACION COMPLETADA CON EXITO!        " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Tu TV Box ahora cuenta con una interfaz limpia estilo Apple TV," -ForegroundColor White
Write-Host "soporte para todas las apps instaladas (incluyendo APKs estandar)," -ForegroundColor White
Write-Host "y sin publicidad de fábrica." -ForegroundColor White
