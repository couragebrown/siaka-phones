$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = '/k cd /d "d:\siaka phones antigravity\siaka-phones\manager_desktop" && call install_vs_buildtools.bat'
$psi.Verb = "runas"
$psi.UseShellExecute = $true
[System.Diagnostics.Process]::Start($psi) | Out-Null
