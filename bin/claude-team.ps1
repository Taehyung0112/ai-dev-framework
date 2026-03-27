#Requires -Version 5.1
<#
.SYNOPSIS
    claude-team.ps1 — Windows PowerShell wrapper for claude-team
.DESCRIPTION
    Forwards all arguments to the bash claude-team script.
    Requires Git for Windows (bash.exe in PATH) or WSL.
.EXAMPLE
    .\claude-team.ps1 init --global
    .\claude-team.ps1 status
    .\claude-team.ps1 doctor
#>

$ScriptDir  = Split-Path $MyInvocation.MyCommand.Path -Parent
$BashScript = Join-Path $ScriptDir "claude-team"

# Normalise to bash-style path (/c/Users/...)
# PS 5.1 compatible — ScriptBlock in -replace requires PS 7+
$BashPath = $BashScript -replace '\\', '/'
if ($BashPath -match '^([A-Za-z]):(.*)') {
  $BashPath = '/' + $Matches[1].ToLower() + $Matches[2]
}

# Find bash.exe (Git for Windows or WSL)
$BASH_EXE = $null
$inPath = Get-Command bash -ErrorAction SilentlyContinue
if ($inPath) {
  $BASH_EXE = $inPath.Source
} else {
  $candidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "$env:ProgramFiles\Git\usr\bin\bash.exe",
    "C:\Program Files\Git\bin\bash.exe",
    "$env:SystemRoot\System32\bash.exe"
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { $BASH_EXE = $c; break }
  }
}

if (-not $BASH_EXE) {
  Write-Error "bash not found. Install Git for Windows: https://git-scm.com"
  exit 1
}

& $BASH_EXE $BashPath @args
exit $LASTEXITCODE
