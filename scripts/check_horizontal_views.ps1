$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.1.33:5555"

& $adb connect $device
Start-Sleep -Milliseconds 400
& $adb -s $device shell "dumpsys activity top" > "D:\Proyectos\cleanyourtv-main\backups\X96Air_P3\top_activity_horizontal.txt"

$lines = Get-Content "D:\Proyectos\cleanyourtv-main\backups\X96Air_P3\top_activity_horizontal.txt"
$inGrid = $false
foreach ($line in $lines) {
    if ($line -like "*app:id/grid*") { $inGrid = $true; continue }
    if ($inGrid) {
        if ($line -like "*app:id/glass*") { break }
        if ($line -like "*categoryTitle*" -or $line -like "*categoryRecycler*") {
            Write-Host $line.Trim()
        }
    }
}
