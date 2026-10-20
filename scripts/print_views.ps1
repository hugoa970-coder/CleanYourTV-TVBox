$content = Get-Content "D:\Proyectos\cleanyourtv-main\backups\X96Air_P3\top_activity.txt"
$start = $false
foreach ($line in $content) {
    if ($line -like "*DecorView@86ecc4d*") {
        $start = $true
    }
    if ($start) {
        Write-Host $line
    }
}
