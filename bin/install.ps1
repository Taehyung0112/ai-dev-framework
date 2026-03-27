#Requires -Version 5.1
<#
.SYNOPSIS
    Agentic Workflow 2.1 — One-click Windows installer
.DESCRIPTION
    Installs ai-dev-framework on Windows:
      - Checks prerequisites (git, claude, gh)
      - Clones the repo (or uses existing copy)
      - Creates ~/.claude/framework as a Directory Junction
      - Updates ~/.claude/CLAUDE.md with framework @imports
      - Injects claude-team function into PowerShell $PROFILE
      - Runs claude-team init --global and doctor
.EXAMPLE
    # One-liner (run in PowerShell):
    iwr -UseBasicParsing https://raw.githubusercontent.com/Taehyung0112/ai-dev-framework/main/bin/install.ps1 | iex

    # From a cloned repo:
    .\bin\install.ps1
#>

# Allow this script to run regardless of machine execution policy
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# ─── Colour helpers (ANSI — works in Windows Terminal / PS 7+)
$ESC = [char]27
function Pass($msg) { Write-Host "  ${ESC}[32m[PASS]${ESC}[0m $msg" }
function Warn($msg) { Write-Host "  ${ESC}[33m[WARN]${ESC}[0m $msg" }
function Fail($msg) { Write-Host "  ${ESC}[31m[FAIL]${ESC}[0m $msg" }
function Info($msg) { Write-Host "  ${ESC}[34m[INFO]${ESC}[0m $msg" }

$GITHUB_REPO  = "https://github.com/Taehyung0112/ai-dev-framework.git"
$INSTALL_DIR  = if ($env:AI_DEV_FRAMEWORK_DIR) { $env:AI_DEV_FRAMEWORK_DIR } `
                else { Join-Path $env:USERPROFILE "ai-dev-framework" }

# ─── Find bash.exe (Git for Windows or WSL)
function Find-BashExe {
  # 1. Already in PATH
  $inPath = Get-Command bash -ErrorAction SilentlyContinue
  if ($inPath) { return $inPath.Source }

  # 2. Common Git for Windows locations
  $candidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "$env:ProgramFiles\Git\usr\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe"
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { return $c }
  }

  # 3. WSL bash
  $wslBash = "$env:SystemRoot\System32\bash.exe"
  if (Test-Path $wslBash) { return $wslBash }

  return $null
}

$BASH_EXE = Find-BashExe
if (-not $BASH_EXE) {
  Write-Host ""
  Fail "bash not found. Install Git for Windows: https://git-scm.com"
  Fail "After installing, re-run this script."
  exit 1
}
Pass "bash: $BASH_EXE"

# ─── Detect if running from within a cloned repo
# NOTE: $PSScriptRoot is empty when script is run via iex (one-liner),
#       so this block is safely skipped and $INSTALL_DIR stays as the default.
if ($PSScriptRoot) {
  $resolved = Resolve-Path (Join-Path $PSScriptRoot "..") -ErrorAction SilentlyContinue
  if ($resolved) {
    $candidate = $resolved.Path
    if (Test-Path (Join-Path $candidate "README.md")) {
      $readmeContent = Get-Content (Join-Path $candidate "README.md") -Raw -ErrorAction SilentlyContinue
      if ($readmeContent -match "ai-dev-framework") {
        $INSTALL_DIR = $candidate
        Info "Using existing repo at: $INSTALL_DIR"
      }
    }
  }
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗"
Write-Host "║  Agentic Workflow 2.1 — Windows Installer   ║"
Write-Host "╚══════════════════════════════════════════════╝"
Write-Host ""

# ══════════════════════════════════════════
# 1. Admin check (warn only — junction needs elevation if .claude doesn't exist)
# ══════════════════════════════════════════
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
  Pass "Running as Administrator"
} else {
  Warn "Not running as Administrator"
  Warn "If junction creation fails, restart PowerShell as Administrator and re-run"
}

# ══════════════════════════════════════════
# 2. Prerequisites
# ══════════════════════════════════════════
Info "Checking prerequisites..."
$issues = 0

function Check-Required($bin, $hint) {
  if (Get-Command $bin -ErrorAction SilentlyContinue) {
    $ver = & $bin --version 2>&1 | Select-Object -First 1
    Pass "${bin}: $ver"
  } else {
    Fail "${bin}: not found — $hint"
    $script:issues++
  }
}

function Check-Optional($bin, $hint) {
  if (Get-Command $bin -ErrorAction SilentlyContinue) {
    $ver = & $bin --version 2>&1 | Select-Object -First 1
    Pass "${bin}: $ver"
  } else {
    Warn "${bin}: not found — $hint"
  }
}

Check-Required "git"    "https://git-scm.com"
Check-Optional "claude" "npm install -g @anthropic-ai/claude-code"
Check-Optional "gh"     "https://cli.github.com"
Check-Optional "node"   "https://nodejs.org (required for TypeScript projects)"

# python: accept python3 or python
if (Get-Command python3 -ErrorAction SilentlyContinue) {
  Pass "python3: $(python3 --version 2>&1)"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
  Pass "python: $(python --version 2>&1) (note: use python3 in scripts)"
} else {
  Warn "python3: not found — https://python.org (required for Python projects)"
}

if ($issues -gt 0) {
  Fail "Critical prerequisites missing. Install them and re-run."
  exit 1
}

# ══════════════════════════════════════════
# 3. Clone or use existing repo
# ══════════════════════════════════════════
if (-not (Test-Path (Join-Path $INSTALL_DIR "README.md"))) {
  Info "Cloning ai-dev-framework to $INSTALL_DIR..."
  git clone $GITHUB_REPO $INSTALL_DIR
  if ($LASTEXITCODE -ne 0) { Fail "git clone failed"; exit 1 }
  Pass "Cloned to $INSTALL_DIR"
} else {
  Info "Using existing framework at $INSTALL_DIR"
}

$claudeTeamBin = Join-Path $INSTALL_DIR "bin\claude-team"

# ══════════════════════════════════════════
# 4. Create ~/.claude directory + Junction
# ══════════════════════════════════════════
$claudeDir    = Join-Path $env:USERPROFILE ".claude"
$junctionPath = Join-Path $claudeDir "framework"

if (-not (Test-Path $claudeDir)) {
  New-Item -ItemType Directory -Path $claudeDir | Out-Null
  Pass "Created $claudeDir"
}

# Remove existing junction / symlink / directory
if (Test-Path $junctionPath) {
  Info "Removing existing $junctionPath..."
  # cmd rmdir handles junctions without deleting the target contents
  cmd /c "rmdir `"$junctionPath`"" 2>$null | Out-Null
  if (Test-Path $junctionPath) {
    Remove-Item -Recurse -Force $junctionPath -ErrorAction SilentlyContinue
  }
}

$mklink = cmd /c "mklink /J `"$junctionPath`" `"$INSTALL_DIR`"" 2>&1
if (Test-Path $junctionPath) {
  Pass "Junction: $junctionPath → $INSTALL_DIR"
} else {
  Fail "Failed to create junction: $mklink"
  Fail "Try running this script from an elevated (Administrator) PowerShell."
  exit 1
}

# ══════════════════════════════════════════
# 5. Update ~/.claude/CLAUDE.md
# ══════════════════════════════════════════
$claudeMdPath  = Join-Path $claudeDir "CLAUDE.md"
$importMarker  = "<!-- managed-by: claude-team v2.1 -->"

$importBlock = @"

## Agentic Workflow 2.1 Framework
$importMarker
@~/.claude/framework/agents/lead.md
@~/.claude/framework/agents/context_controller.md
@~/.claude/framework/playbook/claude-base.md
@~/.claude/framework/playbook/team-standards.md
@~/.claude/framework/playbook/architecture-guide.md
@~/.claude/framework/playbook/testing-guide.md
@~/.claude/framework/playbook/git-workflow.md
@~/.claude/framework/playbook/coding-standards.md
@~/.claude/framework/playbook/ai-workflow.md
@~/.claude/framework/playbook/pr-template.md
"@

if ((Test-Path $claudeMdPath) -and ((Get-Content $claudeMdPath -Raw) -match [regex]::Escape($importMarker))) {
  Info "CLAUDE.md already up to date — skipping"
} else {
  if (Test-Path $claudeMdPath) {
    # Backup and strip old v2.0 block if present
    Copy-Item $claudeMdPath "${claudeMdPath}.bak" -Force
    $content = Get-Content $claudeMdPath -Raw
    $content = $content -replace '(?s)\r?\n## Agentic Workflow 2\.0 Framework.*?@~/\.claude/framework/playbook/pr-template\.md\r?\n', ''
    Set-Content $claudeMdPath $content -NoNewline
  } else {
    # Create minimal CLAUDE.md
    Set-Content $claudeMdPath "# Global Claude Configuration`n" -NoNewline
  }
  Add-Content $claudeMdPath $importBlock
  Pass "Updated $claudeMdPath"
}

# ══════════════════════════════════════════
# 6. Inject claude-team into PowerShell $PROFILE
# ══════════════════════════════════════════
# Use plain ASCII marker to avoid encoding issues with em-dash on Windows
$profileMarker = "# claude-team managed by ai-dev-framework"

# Normalise script path for bash (Windows path → /c/Users/... form)
# PS 5.1 compatible — ScriptBlock in -replace requires PS 7+
$claudeTeamBashPath = $claudeTeamBin -replace '\\', '/'
if ($claudeTeamBashPath -match '^([A-Za-z]):(.*)') {
  $claudeTeamBashPath = '/' + $Matches[1].ToLower() + $Matches[2]
}

# Use Windows path for $BASH_EXE in the profile function
$functionBlock = @"

$profileMarker
function claude-team {
    & "$BASH_EXE" "$claudeTeamBashPath" @args
}
"@

# Ensure profile directory exists
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
  New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$profileNeedsUpdate = $true
if (Test-Path $PROFILE) {
  $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
  # Match both old em-dash marker and new ASCII marker
  if ($profileContent -match "claude-team managed by ai-dev-framework" -or
      $profileContent -match "claude-team.*managed by ai-dev-framework installer") {
    # Remove old stale entry and re-inject with correct bash path
    $profileContent = $profileContent -replace '(?s)\r?\n# claude-team[^\n]*managed by[^\n]*\r?\nfunction claude-team \{[^\}]*\}', ''
    Set-Content $PROFILE $profileContent -NoNewline
  }
}

Add-Content $PROFILE $functionBlock
Pass "Injected claude-team into $PROFILE (bash: $BASH_EXE)"

# ══════════════════════════════════════════
# 7. Init global + Doctor
# ══════════════════════════════════════════
Write-Host ""
Info "Running claude-team init --global..."
& $BASH_EXE $claudeTeamBashPath init --global

Write-Host ""
Write-Host "== Installation Summary =="
& $BASH_EXE $claudeTeamBashPath doctor

Write-Host ""
Write-Host "${ESC}[32mInstallation complete!${ESC}[0m"
Write-Host "  Restart PowerShell to activate the claude-team command."
Write-Host "  Then verify with: claude-team status"
Write-Host ""
