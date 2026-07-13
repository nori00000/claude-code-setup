#requires -Version 5.1
<#
.SYNOPSIS
    Read-only diagnosis of the current Claude Code config on Windows.
    Equivalent to Phase 1 of playbooks/windows-setup.md.

.EXAMPLE
    pwsh scripts/diagnose-windows.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

function Hd { param([string]$T) Write-Host ""; Write-Host "── $T ──" -ForegroundColor Cyan }
function Kv { param([string]$K,$V) Write-Host ("  {0,-32} {1}" -f $K, $V) }

Hd 'Version'
try {
    $v = (& claude --version) 2>&1 | Out-String
    Kv 'claude --version' $v.Trim()
} catch {
    Kv 'claude --version' '(not found on PATH)'
}

Hd 'Files'
$paths = @(
    @{ K = '~/.claude/settings.json';          P = Join-Path $env:USERPROFILE '.claude\settings.json' }
    @{ K = '~/.claude/settings.local.json';    P = Join-Path $env:USERPROFILE '.claude\settings.local.json' }
    @{ K = '~/.claude.json';                   P = Join-Path $env:USERPROFILE '.claude.json' }
    @{ K = 'ProgramData managed-settings';     P = Join-Path $env:ProgramData 'ClaudeCode\managed-settings.json' }
)
foreach ($e in $paths) {
    if (Test-Path $e.P) {
        $size = (Get-Item $e.P).Length
        Kv $e.K "exists ($size bytes)"
    } else {
        Kv $e.K 'absent'
    }
}

Hd 'autoUpdates'
$cfg = Join-Path $env:USERPROFILE '.claude.json'
if (Test-Path $cfg) {
    $line = Select-String -Path $cfg -Pattern 'autoUpdates' -SimpleMatch
    if ($line) { $line | ForEach-Object { Kv 'line' $_.Line.Trim() } }
    else       { Kv 'autoUpdates' '(key not found)' }
} else {
    Kv 'autoUpdates' '(~/.claude.json absent — will be created on first run)'
}

Hd 'Env vars (should all be empty)'
foreach ($v in @('CLAUDE_CODE_DISABLE_AUTO_UPDATE','DISABLE_AUTOUPDATER','ANTHROPIC_API_KEY','CLAUDE_CODE_USE_BEDROCK','CLAUDE_CODE_USE_VERTEX')) {
    $val = [Environment]::GetEnvironmentVariable($v)
    Kv $v ($val ? $val : '(empty)')
}

Hd 'settings.json snapshot'
$set = Join-Path $env:USERPROFILE '.claude\settings.json'
if (Test-Path $set) {
    try {
        $j = Get-Content $set -Raw | ConvertFrom-Json
        $allowCount = ($j.permissions.allow | Measure-Object).Count
        $denyCount  = ($j.permissions.deny  | Measure-Object).Count
        Kv 'permissions.defaultMode' ($j.permissions.defaultMode ?? '(not set)')
        Kv 'permissions.allow count' $allowCount
        Kv 'permissions.deny  count' $denyCount
        $mkts = ($j.extraKnownMarketplaces.PSObject.Properties | Select-Object -ExpandProperty Name) -join ', '
        Kv 'extraKnownMarketplaces' ($mkts ? $mkts : '(none)')
        $hookKeys = ($j.hooks.PSObject.Properties | Select-Object -ExpandProperty Name) -join ', '
        Kv 'hooks' ($hookKeys ? $hookKeys : '(none)')
    } catch {
        Kv 'JSON parse' "INVALID — $($_.Exception.Message)"
    }
} else {
    Kv 'settings.json' '(absent)'
}

Write-Host ""
Write-Host "Diagnosis complete. To apply standard config:" -ForegroundColor Yellow
Write-Host "  pwsh scripts/apply-windows.ps1 -DryRun    # preview" -ForegroundColor Yellow
Write-Host "  pwsh scripts/apply-windows.ps1            # write" -ForegroundColor Yellow
