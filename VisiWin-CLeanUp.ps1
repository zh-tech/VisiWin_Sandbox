<# 
.SYNOPSIS
  Bereitet das VisiWin-Projektverzeichnis für Branch-Wechsel/Merge vor.
  Beendet Prozesse und löscht Sperrdateien/Caches im PROJEKT, nicht in system32.
#>

param(
  [string]$ProjectDir = $PSScriptRoot  # Standard: Ordner des Skripts
)

# Falls $PSScriptRoot leer ist (ältere PS-Versionen), Fallback:
if (-not $ProjectDir) { $ProjectDir = Split-Path -Parent $PSCommandPath }

if (-not (Test-Path $ProjectDir)) {
  Write-Error "Projektpfad nicht gefunden: $ProjectDir"
  exit 1
}

Write-Host "--- VisiWin Cleanup gestartet im Pfad: $ProjectDir ---" -ForegroundColor Cyan

# 1) VisiWin-Prozesse beenden
Write-Host "Beende VisiWin Prozesse..." -ForegroundColor Yellow
$procs = "VisiWin7.IDE","VisiWin.Runtime.Manager","VisiWin.Runtime.Service","VisiWin7.ProjectCompare"
foreach ($p in $procs) {
  Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  if ($?) { Write-Host "  > $p beendet." }
}

Start-Sleep -Seconds 2

# 2) Sperrdateien und temporäre Daten im PROJEKT löschen
Write-Host "Lösche Sperrdateien und temporäre Daten..." -ForegroundColor Yellow

# Access-Locks
foreach ($pat in '*.ldb','*.laccdb') {
  Get-ChildItem -Path $ProjectDir -Filter $pat -File -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue
}
Write-Host "  > Access Locks entfernt."

# Build-Ordner (nur unterhalb des Projektpfads)
Get-ChildItem -Path $ProjectDir -Directory -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -in @('obj','bin') } |
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  > Ordner obj/bin gelöscht (falls vorhanden)."

Write-Host "--- System ist bereit für Branch-Wechsel / Merge ---" -ForegroundColor Green
