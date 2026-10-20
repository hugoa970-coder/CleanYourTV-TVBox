$lines = Get-Content "D:\Proyectos\cleanyourtv-main\backups\X96Air_P3\top_activity.txt"
$inGrid = $false
foreach ($line in $lines) {
    if ($line -like "*app:id/grid*") { $inGrid = $true; continue }
    if ($inGrid) {
        if ($line -like "*app:id/glass*") { break }
        if ($line -like "*app:id/name*") {
            Write-Host $line.Trim()
        }
    }
}
