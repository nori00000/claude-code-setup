#requires -Version 5.1
<#
.SYNOPSIS
    Apply Claude Code settings on Windows. Idempotent + dry-run safe.

.DESCRIPTION
    Phase 1~5 of playbooks/windows-setup.md, automated.
    - Diagnoses existing config
    - Backs up everything with timestamp
    - Writes settings/user-settings.json to ~/.claude/settings.json
    - Resets ~/.claude/settings.local.json to empty container
    - Flips ~/.claude.json autoUpdates → true if needed
    - Validates JSON after each write
    Re-running this script is safe: it skips writes when the file already matches.

.PARAMETER DryRun
    Show what would change without writing anything.

.PARAMETER SkipLocalReset
    Don't touch settings.local.json (preserve accumulated allow rules).

.EXAMPLE
    pwsh scripts/apply-windows.ps1 -DryRun
    pwsh scripts/apply-windows.ps1
    pwsh scripts/apply-windows.ps1 -SkipLocalReset
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipLocalReset
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Msg, [string]$Color = 'Cyan')
    Write-Host "→ $Msg" -ForegroundColor $Color
}
function Write-Ok    { param([string]$Msg) Write-Host "  ✅ $Msg" -ForegroundColor Green }
function Write-Skip  { param([string]$Msg) Write-Host "  ⏭  $Msg" -ForegroundColor DarkGray }
function Write-Warn2 { param([string]$Msg) Write-Host "  ⚠ $Msg" -ForegroundColor Yellow }
function Write-Err2  { param([string]$Msg) Write-Host "  ❌ $Msg" -ForegroundColor Red }

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SettingsDir = Join-Path $RepoRoot 'settings'
$SrcUserSettings  = Join-Path $SettingsDir 'user-settings.json'
$SrcLocalEmpty    = Join-Path $SettingsDir 'settings.local.empty.json'

$ClaudeDir   = Join-Path $env:USERPROFILE '.claude'
$DstSettings = Join-Path $ClaudeDir       'settings.json'
$DstLocal    = Join-Path $ClaudeDir       'settings.local.json'
$DstUserCfg  = Join-Path $env:USERPROFILE '.claude.json'

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

Write-Host ""
Write-Host "Claude Code on Windows — apply ($(if($DryRun){'DRY-RUN'}else{'WRITE'}))" -ForegroundColor Magenta
Write-Host "Repo: $RepoRoot"
Write-Host "Home: $env:USERPROFILE"
Write-Host ""

# --- Sanity ---
if (-not (Test-Path $SrcUserSettings)) {
    Write-Err2 "Missing $SrcUserSettings (repo not initialized correctly)"
    exit 1
}
if (-not (Test-Path $SrcLocalEmpty)) {
    Write-Err2 "Missing $SrcLocalEmpty"
    exit 1
}

# --- Phase 1: Diagnose ---
Write-Step 'Phase 1 — Diagnose'

try {
    $cliVersion = (& claude --version) 2>&1 | Out-String
    Write-Host "  claude --version: $($cliVersion.Trim())"
} catch {
    Write-Warn2 "claude command not found on PATH"
}

foreach ($p in @($DstSettings, $DstLocal, $DstUserCfg)) {
    if (Test-Path $p) { Write-Host "  exists: $p" }
    else              { Write-Host "  absent: $p" }
}

if (Test-Path (Join-Path $env:ProgramData 'ClaudeCode\managed-settings.json')) {
    Write-Warn2 'Enterprise managed-settings.json detected — it will override everything.'
}

foreach ($var in @('CLAUDE_CODE_DISABLE_AUTO_UPDATE','DISABLE_AUTOUPDATER')) {
    $val = [Environment]::GetEnvironmentVariable($var)
    if ($val) { Write-Warn2 "$var = $val (set; may interfere)" }
}

# --- Phase 2: Backup ---
Write-Step 'Phase 2 — Backup (timestamped)'
function Backup-File {
    param([string]$Path)
    if (-not (Test-Path $Path)) { Write-Skip "$Path (no source to back up)"; return }
    $bak = "$Path.bak.$ts"
    if ($DryRun) { Write-Host "  [dry] cp $Path → $bak"; return }
    Copy-Item $Path $bak -Force
    Write-Ok "$Path → $bak"
}
Backup-File $DstSettings
Backup-File $DstLocal
Backup-File $DstUserCfg

# --- Phase 3: Apply ---
Write-Step 'Phase 3 — Apply settings'

# 3.0 ensure ~/.claude
if (-not (Test-Path $ClaudeDir)) {
    if ($DryRun) { Write-Host "  [dry] mkdir $ClaudeDir" }
    else        { New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null; Write-Ok "created $ClaudeDir" }
}

function Compare-File {
    param([string]$Src, [string]$Dst)
    if (-not (Test-Path $Dst)) { return $false }
    $a = (Get-FileHash $Src -Algorithm SHA256).Hash
    $b = (Get-FileHash $Dst -Algorithm SHA256).Hash
    return ($a -eq $b)
}

# 3.1 user settings
if (Compare-File $SrcUserSettings $DstSettings) {
    Write-Skip "settings.json already matches user-settings.json"
} else {
    if ($DryRun) {
        Write-Host "  [dry] cp $SrcUserSettings → $DstSettings"
    } else {
        Copy-Item $SrcUserSettings $DstSettings -Force
        try {
            Get-Content $DstSettings -Raw | ConvertFrom-Json | Out-Null
            Write-Ok "settings.json written + JSON valid"
        } catch {
            Write-Err2 "settings.json JSON invalid — rolling back from latest backup"
            $bak = Get-ChildItem "$DstSettings.bak.*" | Sort-Object LastWriteTime -Desc | Select-Object -First 1
            if ($bak) { Copy-Item $bak.FullName $DstSettings -Force }
            exit 2
        }
    }
}

# 3.2 settings.local.json reset
if ($SkipLocalReset) {
    Write-Skip "settings.local.json reset skipped (--SkipLocalReset)"
} elseif (Compare-File $SrcLocalEmpty $DstLocal) {
    Write-Skip "settings.local.json already empty container"
} else {
    if ($DryRun) {
        Write-Host "  [dry] cp $SrcLocalEmpty → $DstLocal"
    } else {
        Copy-Item $SrcLocalEmpty $DstLocal -Force
        Write-Ok "settings.local.json reset to empty container"
    }
}

# 3.3 ~/.claude.json autoUpdates → true
if (Test-Path $DstUserCfg) {
    $content = Get-Content $DstUserCfg -Raw
    if ($content -match '"autoUpdates"\s*:\s*false') {
        if ($DryRun) {
            Write-Host "  [dry] flip autoUpdates: false → true in $DstUserCfg"
        } else {
            $new = $content -replace '"autoUpdates"\s*:\s*false', '"autoUpdates": true'
            [System.IO.File]::WriteAllText($DstUserCfg, $new, [System.Text.UTF8Encoding]::new($false))
            Write-Ok "autoUpdates flipped to true in $DstUserCfg"
        }
    } else {
        Write-Skip "autoUpdates already true (or key absent) in $DstUserCfg"
    }
} else {
    Write-Skip "$DstUserCfg does not exist yet (will be created by Claude Code on first run)"
}

# --- Phase 4 hint ---
Write-Step 'Phase 4 — Verify (next manual step)'
Write-Host @"
  1. Quit any running Claude Code session.
  2. Start a fresh one:    claude
  3. Check inside session:
       /status      → Default permission mode: Auto mode, Model: Opus 4.7
       /permissions → allow 9, deny 6
       /plugin      → marketplace 'omc' only
  4. First run will prompt 'Enable auto mode?' — pick (1) Yes, make it default.
"@

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry-run complete. No files changed." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Apply complete." -ForegroundColor Green
}
