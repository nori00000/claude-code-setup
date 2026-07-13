#requires -Version 5.1
<#
.SYNOPSIS
    One-shot bootstrap for a fresh Windows machine.

.DESCRIPTION
    Sequence:
      1. Verify gh CLI is installed and authenticated
      2. Clone or update nori00000/claude-code-setup
      3. Run apply-windows.ps1
      4. Print next steps (start claude, /model Opus 4.7, etc.)

    Assumes Node.js + npm are already installed (needed for Claude Code itself).

.PARAMETER Dest
    Where to clone the repo. Default: $env:USERPROFILE\projects\claude-code-setup

.PARAMETER DryRun
    Pass-through to apply-windows.ps1.

.EXAMPLE
    pwsh -File scripts/bootstrap-windows.ps1
    pwsh -File scripts/bootstrap-windows.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [string]$Dest = (Join-Path $env:USERPROFILE 'projects\claude-code-setup'),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Step { param($Msg) Write-Host "→ $Msg" -ForegroundColor Cyan }
function Ok   { param($Msg) Write-Host "  ✅ $Msg" -ForegroundColor Green }
function Err  { param($Msg) Write-Host "  ❌ $Msg" -ForegroundColor Red }

# --- 1. Tools ---
Step '1. Verifying tools (gh, git, claude)'

foreach ($cmd in @('git','gh')) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Err "$cmd not found on PATH"
        Write-Host "    Install:  winget install --id GitHub.cli   (for gh)"
        Write-Host "              winget install --id Git.Git      (for git)"
        exit 1
    }
}

# gh auth status
$ghStatus = & gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Err "gh CLI not authenticated"
    Write-Host "    Run:  gh auth login"
    exit 1
}
Ok 'gh CLI authenticated'

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "  ⚠ claude not on PATH yet. Install with:" -ForegroundColor Yellow
    Write-Host "       npm install -g @anthropic-ai/claude-code@latest"
    Write-Host "    (continuing — apply-windows.ps1 still works without claude)"
} else {
    Ok ("claude found: " + (& claude --version 2>&1 | Out-String).Trim())
}

# --- 2. Clone or update ---
Step "2. Cloning/updating to $Dest"

if (Test-Path $Dest) {
    Push-Location $Dest
    try {
        $remote = (& git remote get-url origin 2>&1).Trim()
        if ($remote -notmatch 'nori00000/claude-code-setup') {
            Err "$Dest exists but is not the right repo (origin: $remote)"
            exit 1
        }
        & git fetch origin
        & git pull --ff-only
        Ok "updated $Dest"
    } finally {
        Pop-Location
    }
} else {
    $parent = Split-Path $Dest -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    & gh repo clone nori00000/claude-code-setup $Dest
    Ok "cloned to $Dest"
}

# --- 3. Apply ---
Step '3. Applying Claude Code config'

$applyScript = Join-Path $Dest 'scripts\apply-windows.ps1'
if (-not (Test-Path $applyScript)) {
    Err "apply-windows.ps1 not found at $applyScript"
    exit 1
}

if ($DryRun) {
    & pwsh -File $applyScript -DryRun
} else {
    & pwsh -File $applyScript
}

# --- 4. Next steps ---
Step '4. Next steps (manual)'
Write-Host @"
  - Quit any running Claude Code session.
  - Start a fresh one:    claude
  - In session:
      /status      → confirm Auto mode + Opus 4.7
      /model       → pick Opus 4.7 if not already
      /plugin      → install 'omc' marketplace if desired
  - First run prompts 'Enable auto mode?' → pick (1) Yes, make it default.
  - See playbooks/windows-setup.md §8 for the full verification checklist.
"@
