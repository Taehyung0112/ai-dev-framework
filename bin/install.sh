#!/usr/bin/env bash
# install.sh — Agentic Workflow 2.1 one-click installer (Linux / macOS)
# Usage:
#   One-liner:  curl -fsSL https://raw.githubusercontent.com/Taehyung0112/ai-dev-framework/main/bin/install.sh | bash
#   From repo:  bash bin/install.sh
set -euo pipefail

# ─── Colours
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

pass() { echo -e "  ${GREEN}[PASS]${RESET} $*"; }
warn() { echo -e "  ${YELLOW}[WARN]${RESET} $*"; }
fail() { echo -e "  ${RED}[FAIL]${RESET} $*"; }
info() { echo -e "  ${BLUE}[INFO]${RESET} $*"; }

GITHUB_REPO="https://github.com/Taehyung0112/ai-dev-framework.git"
INSTALL_DIR="${AI_DEV_FRAMEWORK_DIR:-${HOME}/ai-dev-framework}"

# ─── Detect if running from within a cloned repo (not piped from curl)
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CANDIDATE="$(cd "${SCRIPT_DIR}/.." && pwd)"
  if [[ -f "${CANDIDATE}/README.md" ]] && grep -q "ai-dev-framework" "${CANDIDATE}/README.md" 2>/dev/null; then
    INSTALL_DIR="${CANDIDATE}"
    info "Using existing repo at: ${INSTALL_DIR}"
  fi
fi

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║  Agentic Workflow 2.1 — Linux Installer  ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ══════════════════════════════════════════
# 1. Prerequisites
# ══════════════════════════════════════════
info "Checking prerequisites..."
ISSUES=0

check_required() {
  local bin="$1" install_hint="$2"
  if command -v "${bin}" &>/dev/null; then
    pass "${bin}: $(${bin} --version 2>&1 | head -1)"
  else
    fail "${bin}: not found — ${install_hint}"
    ((ISSUES++)) || true
  fi
}

check_optional() {
  local bin="$1" install_hint="$2"
  if command -v "${bin}" &>/dev/null; then
    pass "${bin}: $(${bin} --version 2>&1 | head -1)"
  else
    warn "${bin}: not found — ${install_hint}"
  fi
}

check_required "git"    "https://git-scm.com"
check_optional "claude" "npm install -g @anthropic-ai/claude-code"
check_optional "gh"     "https://cli.github.com"
check_optional "node"   "https://nodejs.org (required for TypeScript projects)"
check_optional "python3" "https://python.org (required for Python projects)"

if [[ "${ISSUES}" -gt 0 ]]; then
  fail "Critical prerequisites missing. Install them and re-run."
  exit 1
fi

# ══════════════════════════════════════════
# 2. Clone or use existing repo
# ══════════════════════════════════════════
if [[ ! -f "${INSTALL_DIR}/README.md" ]]; then
  info "Cloning ai-dev-framework to ${INSTALL_DIR}..."
  git clone "${GITHUB_REPO}" "${INSTALL_DIR}"
  pass "Cloned to ${INSTALL_DIR}"
else
  info "Using existing framework at ${INSTALL_DIR}"
fi

CLAUDE_TEAM_BIN="${INSTALL_DIR}/bin/claude-team"
chmod +x "${CLAUDE_TEAM_BIN}"

# ══════════════════════════════════════════
# 3. Create ~/.claude/framework symlink
# ══════════════════════════════════════════
mkdir -p "${HOME}/.claude"
LINK="${HOME}/.claude/framework"

if [[ -L "${LINK}" ]]; then
  rm "${LINK}"
  info "Removed old symlink at ${LINK}"
elif [[ -d "${LINK}" ]]; then
  warn "${LINK} is a plain directory — removing"
  rm -rf "${LINK}"
fi

ln -s "${INSTALL_DIR}" "${LINK}"
pass "Symlink: ${LINK} → ${INSTALL_DIR}"

# ══════════════════════════════════════════
# 4. Update ~/.claude/CLAUDE.md
# ══════════════════════════════════════════
CLAUDE_MD="${HOME}/.claude/CLAUDE.md"
IMPORT_MARKER="<!-- managed-by: claude-team v2.1 -->"

if [[ -f "${CLAUDE_MD}" ]] && grep -q "${IMPORT_MARKER}" "${CLAUDE_MD}" 2>/dev/null; then
  info "CLAUDE.md already up to date — skipping"
else
  # Strip old v2.0 managed block if present
  if [[ -f "${CLAUDE_MD}" ]]; then
    cp "${CLAUDE_MD}" "${CLAUDE_MD}.bak"
    # Remove lines from "## Agentic Workflow 2." to the last @import line of that block
    perl -i -0pe 's/\n## Agentic Workflow 2\.[^\n]*\n(?:.*\n)*?@~\/\.claude\/framework\/playbook\/pr-template\.md\n//g' \
      "${CLAUDE_MD}" 2>/dev/null || true
  else
    touch "${CLAUDE_MD}"
  fi

  cat >> "${CLAUDE_MD}" << MDEOF

## Agentic Workflow 2.1 Framework
${IMPORT_MARKER}
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
MDEOF
  pass "Updated ${CLAUDE_MD}"
fi

# ══════════════════════════════════════════
# 5. Inject alias into shell profile
# ══════════════════════════════════════════
ALIAS_MARKER="# claude-team — managed by ai-dev-framework installer"
ALIAS_LINE="alias claude-team='bash ${CLAUDE_TEAM_BIN}'"

inject_alias() {
  local profile_file="$1"
  if grep -q "claude-team — managed by" "${profile_file}" 2>/dev/null; then
    info "${profile_file}: alias already present"
  else
    printf '\n%s\n%s\n' "${ALIAS_MARKER}" "${ALIAS_LINE}" >> "${profile_file}"
    pass "Injected alias into ${profile_file}"
  fi
}

INJECTED=0
[[ -f "${HOME}/.zshrc" ]]  && inject_alias "${HOME}/.zshrc"  && INJECTED=1
[[ -f "${HOME}/.bashrc" ]] && inject_alias "${HOME}/.bashrc" && INJECTED=1

if [[ "${INJECTED}" -eq 0 ]]; then
  warn "No .bashrc or .zshrc found — create one and add:"
  warn "  ${ALIAS_LINE}"
fi

# ══════════════════════════════════════════
# 6. Init global + run doctor
# ══════════════════════════════════════════
echo ""
info "Running claude-team init --global..."
bash "${CLAUDE_TEAM_BIN}" init --global

echo ""
echo -e "${BOLD}══ Installation Summary ══${RESET}"
bash "${CLAUDE_TEAM_BIN}" doctor

echo ""
echo -e "${GREEN}${BOLD}Installation complete!${RESET}"
echo -e "  Restart your terminal (or run: source ~/.bashrc / source ~/.zshrc)"
echo -e "  Then verify with: ${BOLD}claude-team status${RESET}"
echo ""
