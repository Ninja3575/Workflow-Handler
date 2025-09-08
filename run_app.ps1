$ErrorActionPreference = 'Stop'

param(
  [int]$WebPort = 8080,
  [int]$BackendPort = 4000,
  [string]$Device = 'chrome'
)

Write-Host "Starting backend on port $BackendPort..."
Start-Process -WindowStyle Hidden -FilePath powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\run_backend.ps1`" -Port $BackendPort"

Start-Sleep -Seconds 2

Write-Host "Launching Flutter app on $Device (web port $WebPort)..."
flutter run -d $Device --web-port=$WebPort

