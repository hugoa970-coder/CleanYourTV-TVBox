$env:JAVA_HOME = "C:\Program Files\Android\Android Studio1\jbr"
$env:ANDROID_HOME = "C:\Users\User\AppData\Local\Android\Sdk"
Set-Location "D:\Proyectos\cleanyourtv-main\launcher"

Write-Host "Compilando con Gradle..." -ForegroundColor Cyan
& ".\gradlew.bat" clean assembleRelease

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build exitoso!" -ForegroundColor Green
    Copy-Item "app\build\outputs\apk\release\app-release.apk" "..\CleanYourTV-TVBox.apk" -Force
    Write-Host "Copiado a CleanYourTV-TVBox.apk"
} else {
    Write-Host "Error en compilación! Codigo: $LASTEXITCODE" -ForegroundColor Red
}
