$ErrorActionPreference = 'Continue'

param([int]$Port = 4000)

Write-Host "Stopping any process listening on port $Port..."
$conns = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($conns) {
  $pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique
  foreach ($procId in $pids) {
    try { Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue; Write-Host "Stopped PID $procId" } catch {}
  }
} else {
  Write-Host "No process found on $Port."
}

