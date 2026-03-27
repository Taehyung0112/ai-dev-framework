# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Engineering Standards

This project follows the shared engineering playbook at `~/.claude/framework/playbook/`.
Behavior rules, commit format, architecture principles, and testing standards are defined there.

---

## Session Start Protocol

**When a new Claude Code session begins in this directory, output the following banner immediately — before responding to any user input:**

```
╔══════════════════════════════════════════════════════════╗
║         Agentic Workflow 2.2  |  Lead is active          ║
╠══════════════════════════════════════════════════════════╣
║  Quick commands:                                         ║
║    開始新任務: <描述>   → PM agent (Task Card)            ║
║    /code-review-expert → AI code review (sanyuan0704)    ║
║    /code-review        → incubator overlay review        ║
║    /security-audit     → STRIDE + OWASP audit            ║
║    /sprint-plan        → Sprint planning                 ║
║    /adr                → Architecture Decision Record    ║
║    /tech-debt          → Tech debt triage                ║
║    /rollback #N        → Emergency rollback SOP          ║
║    /elite-powerpoint-designer → Elite slide design       ║
║                                                          ║
║  First time setup?  Run:                                 ║
║    bash bin/claude-team init --global                    ║
║                                                          ║
║  Check status:                                           ║
║    bash bin/claude-team status                           ║
╚══════════════════════════════════════════════════════════╝
```

After displaying the banner, read `.agents/team_status.md` (if it exists) and report the current sprint/active task in one line. If it does not exist, say "No active sprint — type `開始新任務: <描述>` to begin."

---

## What This Repo Is

`ai-dev-framework` is the **shared engineering infrastructure** for the incubator monorepo. It is symlinked (or junction-linked on Windows) to `~/.claude/framework/`, making its playbook and agent definitions globally available to all Claude Code sessions.

It lives as a subdirectory of the incubator monorepo (ADR-005). It is **not** a standalone application — there is no build step, no test suite, and no runtime dependencies.

---

## CLI Commands

The management CLI lives at `bin/claude-team`. Run it from any directory:

```bash
# First-time machine setup — creates ~/.claude/framework junction + updates ~/.claude/CLAUDE.md
bash ~/incubator/ai-dev-framework/bin/claude-team init --global

# Attach agent workflow to a project repo (creates .agents/ in CWD)
cd ~/incubator/order-hub
bash ~/incubator/ai-dev-framework/bin/claude-team init

# Pull latest framework changes from git
bash ~/incubator/ai-dev-framework/bin/claude-team update

# Check environment (gh, python3/pip3, node, vcpkg, git, symlink)
bash ~/incubator/ai-dev-framework/bin/claude-team doctor
```

> **ADR-007 (Resolved v2.1):** `claude-team update` uses `git rev-parse --show-toplevel` to locate the actual monorepo root, so it correctly pulls from `origin` regardless of whether the CWD has its own `.git`.

---

## Architecture

### Three Configuration Layers

```
Layer 1 — GLOBAL (~/.claude/)
  Loaded every session, every project.
  Source: this repo via ~/.claude/framework symlink/junction.
  Update: git pull in ai-dev-framework/ → takes effect next session.

Layer 2 — REPO (incubator/.clauderules + .agents/)
  Loaded when CWD is inside incubator/.
  Contains: session init protocol, registry.json, team_status.md.

Layer 3 — PROJECT ({project}/CLAUDE.md)
  Loaded when CWD is inside a specific sub-project.
  Contains only project-specific commands and architecture notes.
```

### Agent Team

Six agents defined in `agents/`. The **Lead** is auto-activated on every session start; all others are dispatched by Lead.

| Agent | File | Role |
|---|---|---|
| Lead | `agents/lead.md` | Default orchestrator. Classifies tasks, routes to specialists, enforces gates. |
| PM | `agents/pm.md` | Converts vague requests into structured Task Cards + GitHub issues. |
| Architect | `agents/architect.md` | Produces SPEC_SHEET.md with interface contracts and risk table. |
| Coder | `agents/coder.md` | Implements per spec. No `git add -A`. No TODO placeholders. |
| QA | `agents/qa.md` | Runs pytest verification loop. Issues VERIFICATION_REPORT.md. |
| Auditor | `agents/auditor.md` | L3 only. Thread safety, financial precision, production stability sign-off. |

### Complexity Routing

Every task must be classified before work begins:

| Level | Criteria | Route | Coverage Gate |
|---|---|---|---|
| L1 | Docs, typo, config, dep bump — no new logic | Coder only | Smoke test |
| L2 | New logic, refactor, API change | Architect → Coder → QA | ≥ 80% |
| L3 | Concurrency, financial, auth, production stability | Architect → Coder → QA → Auditor | ≥ 90% overall, 100% critical path |

**Never downgrade L3 → L2.** When in doubt, classify higher.

### Agent Handoff Contracts

Four document templates in `contracts/` drive all inter-agent communication. Agents must not skip required sections.

| Template | Created By | Consumed By |
|---|---|---|
| `TASK_CARD.md` | PM | Lead, Architect, Coder |
| `SPEC_SHEET.md` | Architect | Coder, Auditor |
| `IMPLEMENTATION_LOG.md` | Coder | QA, Auditor |
| `VERIFICATION_REPORT.md` | QA | Lead, Auditor |

### Team Status Wall

`.agents/team_status.md` is the shared state file. Lead reads it at session start to restore sprint context and updates it after every agent handoff. **Do not edit manually.**

---

## Updating the Playbook

To propagate a playbook change to all teammates:

```bash
# Edit the relevant file
vim playbook/coding-standards.md

# Commit and push (within incubator monorepo)
git add playbook/coding-standards.md
git commit -m "chore(playbook): ..."
git push

# Teammates sync with:
bash ~/incubator/ai-dev-framework/bin/claude-team update
```

Changes to `playbook/*.md` and `agents/*.md` take effect on the next Claude Code session — no restart of the CLI required.

---

## Windows-Specific Notes

On Windows 11, `~/.claude/framework` is a **directory junction** (not a Unix symlink). `claude-team doctor` detects both. If re-running `init --global`, the script removes the old junction before creating a new one. (ADR-006)

Use `python3` and `pip3` explicitly — the `python` binary is absent in the `incubator-dev` CI image.
