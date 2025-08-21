# Ballgame Metrics
# BallgameBI Repository Update Script
# This script updates the local Git repository for the BallgameBI project.
# 

param(
    [string]$RepoDir = "C:\baseball\ballgameBI",
    [string]$LogDir  = "C:\baseball\ballgameBI"
)

# ---------- Config ----------
$DateStamp   = Get-Date -Format "yyyyMMdd"
$TimeStamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$LogFile     = Join-Path $LogDir "update_log_$DateStamp.txt"

# Event Log config
$EventLogName   = "Application"
$EventSource    = "BallgameBI-Updater"    # custom source for your task
$FallbackSource = "Windows PowerShell"    # used if we can't register custom source
$EventIdSuccess = 1000
$EventIdFail    = 2000
$EventIdNoGit   = 2001
$EventIdNoRepo  = 2002
# ----------------------------

# Ensure log dir exists
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-Log($msg) {
    $line = "[$TimeStamp] $msg"
    Add-Content -Path $LogFile -Value $line
    Write-Output $line
}

# Prepare Event Log source
$ActiveSource = $null
try {
    if (-not [System.Diagnostics.EventLog]::SourceExists($EventSource)) {
        # Requires admin
        New-EventLog -LogName $EventLogName -Source $EventSource
    }
    $ActiveSource = $EventSource
} catch {
    # Fall back to built-in source if custom creation not allowed
    $ActiveSource = $FallbackSource
}

function Write-Event($type, $message, $eventId) {
    try {
        Write-EventLog -LogName $EventLogName -Source $ActiveSource -EntryType $type -EventId $eventId -Message $message
    } catch {
        # Last-ditch fallback so the script never crashes on logging
        Write-Output "EVENTLOG WRITE FAILED: $($_.Exception.Message) | Intended: [$type/$eventId] $message"
    }
}

Write-Log "----- Run started -----"

# --- Locate Git ---
$gitExe = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $gitExe) {
    $candidates = @(
        "C:\Program Files\Git\bin\git.exe",
        "C:\Program Files\Git\cmd\git.exe",
        "C:\Program Files (x86)\Git\bin\git.exe",
        "C:\Program Files (x86)\Git\cmd\git.exe"
    )
    foreach ($cand in $candidates) { if (Test-Path $cand) { $gitExe = $cand; break } }
}
if (-not $gitExe) {
    $msg = "Git not found. Install Git for Windows or add it to PATH."
    Write-Log "ERROR: $msg"
    Write-Event -type Error -message $msg -eventId $EventIdNoGit
    exit 1
}
Write-Log "Using Git: $gitExe"

# --- Check repo ---
if (-not (Test-Path (Join-Path $RepoDir ".git"))) {
    $msg = "$RepoDir is not a Git repository."
    Write-Log "ERROR: $msg"
    Write-Event -type Error -message $msg -eventId $EventIdNoRepo
    exit 2
}

Push-Location $RepoDir
# Avoid “unsafe repository” when run under service accounts
& $gitExe config --global --add safe.directory $RepoDir | Out-Null

$failed = $false
try {
    Write-Log "Fetching…"
    & $gitExe fetch --all --prune 2>&1 | Tee-Object -FilePath $LogFile -Append

    $upstream = & $gitExe rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null
    if ($upstream) {
        Write-Log "Resetting to $upstream"
        & $gitExe reset --hard $upstream 2>&1 | Tee-Object -FilePath $LogFile -Append
    } else {
        Write-Log "Resetting to origin/HEAD"
        & $gitExe remote set-head origin -a | Out-Null
        & $gitExe reset --hard origin/HEAD 2>&1 | Tee-Object -FilePath $LogFile -Append
    }

    Write-Log "Pulling (ff-only)"
    & $gitExe pull --ff-only 2>&1 | Tee-Object -FilePath $LogFile -Append

    Write-Log "SUCCESS: Repository updated."
    Write-Event -type Information -message "Repository updated successfully." -eventId $EventIdSuccess
}
catch {
    $failed = $true
    $err = $_.Exception.Message
    Write-Log "ERROR: $err"
    Write-Event -type Error -message "Update failed: $err" -eventId $EventIdFail
}
finally {
    Pop-Location
}

if ($failed) { exit 3 } else { exit 0 }




# Scheduling (Task Scheduler)
# GUI
# Create two tasks (or two triggers on one task):
# Daily at 20:00
# At log on → Any user
# Action → Start a program
# Program/script: powershell.exe
# Arguments:
# -ExecutionPolicy Bypass -File "C:\baseball\ballgameBI\update_repo.ps1"

# General:
# (Recommended) Run with highest privileges
# If you want it headless: Run whether user is logged on or not

# schtasks /create /tn "UpdateBallgameRepoDaily" ^
#  /tr "cmd /c \"powershell.exe -ExecutionPolicy Bypass -File C:\baseball\ballgameBI\update_repo.ps1\"" ^
#  /sc daily /st 20:00
# schtasks /create /tn "UpdateBallgameRepoOnLogon" ^
#  /tr "cmd /c \"powershell.exe -ExecutionPolicy Bypass -File C:\baseball\ballgameBI\update_repo.ps1\"" ^
#  /sc onlogon

# Viewing the Event Log entries
# Open Event Viewer → Windows Logs → Application
# Filter by Source:
# BallgameBI-Updater (if the source was created successfully)
# or fallback Windows PowerShell
# Or via PowerShell (success & failure IDs):

# Get-WinEvent -FilterHashtable @{ LogName='Application'; ProviderName='BallgameBI-Updater'; Id=@(1000,2000,2001,2002) } | Format-Table TimeCreated, Id, LevelDisplayName, ProviderName, Message -Auto

# Notes
# First run as Administrator is recommended so the custom event source can be registered. 
# If not, the script will still work and will log under Windows PowerShell.
# Works on Windows 10/11, Home and Pro.
# If you always want to target a specific branch (e.g., origin/main), 
# replace the reset logic with:

# & $gitExe fetch --all --prune
# & $gitExe reset --hard origin/main
