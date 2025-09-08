$ErrorActionPreference = 'Stop'

param(
  [int]$Port = 4000
)

function Stop-Port($port) {
  $proc = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty OwningProcess
  if ($proc) {
    try { Stop-Process -Id $proc -Force -ErrorAction SilentlyContinue } catch {}
  }
}

Write-Host "Ensuring port $Port is free..."
Stop-Port $Port

Write-Host "Starting mock backend on port $Port..."
$env:PORT = "$Port"
node mock-backend.js

