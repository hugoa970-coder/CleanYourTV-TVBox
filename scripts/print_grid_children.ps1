$lines = Get-Content "D:\Proyectos\cleanyourtv-main\backups\X96Air_P3\top_activity.txt"
$inGrid = $false
foreach ($line in $lines) {
    if ($line -like "*app:id/grid*") { $inGrid = $true; continue }
    if ($inGrid) {
        if ($line -like "*app:id/glass*") { break }
        # Match only direct children of grid (indented with 20 spaces)
        if ($line -match '^\s{20}\S+') {
            Write-Host $line.Trim()
        }
    }
}
