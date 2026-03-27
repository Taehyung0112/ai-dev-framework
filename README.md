# Agentic Workflow 2.2 — AI Dev Framework

A **git-managed, team-synced** engineering infrastructure for Claude Code multi-agent development.
Clone once to a stable location. Every teammate runs from the same source of truth.

> **v2.2** adds: Skills Layer (6 built-in skills + code-review-expert), TruffleHog secrets scanning CI job, AI-powered MR Review CI job (Claude API), v2.2 session banner.
> **v2.1** added: Context Controller Agent, `claude-team status`, monorepo-aware `update`, Working Directory Protocol, `.clauderules` Trigger Map, one-click cross-platform installer.
> 繁體中文版：[README.zh-TW.md](./README.zh-TW.md)

---

## One-click Install

**Windows (PowerShell):**

```powershell
iwr -UseBasicParsing https://raw.githubusercontent.com/Taehyung0112/ai-dev-framework/main/bin/install.ps1 | iex
```

**Linux / macOS (Bash):**

```bash
curl -fsSL https://raw.githubusercontent.com/Taehyung0112/ai-dev-framework/main/bin/install.sh | bash
```

The installer will:
1. Check prerequisites (git, claude, gh, node, python3)
2. Clone the framework to `~/ai-dev-framework`
3. Create `~/.claude/framework` symlink / junction
4. Update `~/.claude/CLAUDE.md` with all framework `@import`s
5. Inject `claude-team` command into your shell profile
6. Run `claude-team init --global` and `doctor` to confirm the setup

> **After install**: restart your terminal, then attach to a project with `claude-team init`.

---

## After Installation — Attach to a Project

Run once inside each project repo where you want the agent workflow active:

```bash
cd ~/your-project
claude-team init
```

Then open Claude Code in that directory — the Lead Agent greets you automatically.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Agent Role Handbook](#2-agent-role-handbook)
3. [Communication Contracts (I/O)](#3-communication-contracts-io)
4. [Manual Setup (no installer)](#4-manual-setup-no-installer)
5. [Skills Layer](#5-skills-layer)
6. [claude-team CLI Reference](#6-claude-team-cli-reference)
7. [Team Sync — Updating the Playbook](#7-team-sync--updating-the-playbook)
8. [Directory Structure](#8-directory-structure)
9. [Configuration Layers](#9-configuration-layers)

---

## 5. Skills Layer

Skills are actionable reference documents for specific development tasks. They live in `skills/` and are globally available via `~/.claude/framework/skills/`.

### Built-in Skills (v2.2)

| Skill File | Slash Command | Purpose |
|---|---|---|
| `skills/code-review.md` | `/code-review` | incubator overlay for code review (C++/Python commit rules, security red lines) |
| `skills/security-audit.md` | `/security-audit` | STRIDE threat modeling + OWASP Top 10 + incubator red lines |
| `skills/sprint-planning.md` | `/sprint-plan` | Sprint breakdown, L1/L2/L3 estimation, GitLab milestone setup |
| `skills/adr-template.md` | `/adr` | Architecture Decision Record format (ADR-NNN) |
| `skills/rollback-procedure.md` | `/rollback #N` | Emergency rollback SOP (production, git revert, database) |
| `skills/tech-debt-refactor.md` | `/tech-debt` | Tech debt triage matrix + safe refactoring protocol |

### External Skills (local install, not in repo)

| Command | Source | Purpose |
|---|---|---|
| `/code-review-expert` | sanyuan0704/sanyuan-skills (MIT, 2.9k⭐) | SOLID + security + quality deep review, P0–P3 severity model |
| `/elite-powerpoint-designer` | willem4130/claude-code-skills | Elite slide design (Minto Pyramid, Insight Headline, animation guide) |

Install via gh CLI (cross-platform):
```bash
# code-review-expert (Linux/macOS)
npx skills add sanyuan0704/sanyuan-skills --path skills/code-review-expert

# elite-powerpoint-designer (any platform)
gh api repos/willem4130/claude-code-skills/contents/skills/elite-powerpoint-designer/SKILL.md --jq '.content' | base64 -d > ~/.claude/skills/elite-powerpoint-designer/SKILL.md
```

### Skill Integration in Lead Agent

For L2/L3 tasks, Lead automatically invokes `/code-review-expert` after Coder, before QA:
```
Architect → Coder → /code-review-expert → QA → (Auditor for L3)
```
P0/P1 findings return to Coder for fixes. Only P2/P3 proceed to QA.

### CI/CD Automation (v2.2)

Two new jobs added to `static_analysis` stage (MR pipelines only):

**`secrets_scan`** — TruffleHog OSS secrets detection
- Scans the MR diff for 800+ secret types
- `allow_failure: false` — blocks merge on secret detection
- Requires no additional configuration

**`ai_code_review`** — Claude API MR review
- Posts structured P0/P1/P2/P3 review as a GitLab MR comment
- `allow_failure: true` — advisory only (non-blocking)
- Requires GitLab CI/CD variables:
  - `ANTHROPIC_API_KEY` (Protected + Masked)
  - `GITLAB_TOKEN` (api scope, Protected)

### Awesome-Skills Library (Future Expansion)

`github.com/sickn33/antigravity-awesome-skills` (26.9k ⭐, 1304+ skills) is designated as the **Expansion Library**. Browse it when a specific domain need arises (e.g., Docker optimization, Kubernetes patterns). Do not bulk-import.

---

## 1. Architecture Overview

The framework uses **three configuration layers** that compose at runtime:

```
Layer 1 — GLOBAL (~/.claude/)
  Loaded by every Claude Code session, on every project.
  Contains: CLAUDE.md (imports lead.md + playbook), framework/ symlink
  Owner: This repo (ai-dev-framework) via symlink → ~/.claude/framework
  Created by: claude-team init --global  (or the one-click installer)
  Update: git pull → changes apply immediately on next session

Layer 2 — REPO ({your-project}/.clauderules + .agents/)
  Loaded by Claude Code when CWD is inside the project directory.
  Contains: session init protocol (v2.1), trigger map, registry.json, team_status.md
  Owner: each project repo
  Created by: claude-team init (run inside the project directory)
  Update: edit .clauderules or .agents/team_status.md, commit to project repo

Layer 3 — PROJECT ({your-project}/CLAUDE.md)
  Loaded when CWD is inside a specific project.
  Contains: build commands, test commands, architecture notes unique to that project.
  Owner: each project team
  Created by: manually, as needed
  Update: edit the project-level CLAUDE.md
```

### Composition Flow (v2.1)

```
Session Start
     │
     ▼
 Layer 1: ~/.claude/CLAUDE.md
  → imports agents/lead.md         ← activates Lead Agent
  → imports playbook/*.md          ← loads engineering standards
     │
     ▼
 Layer 2: {project}/.clauderules   (v2.1: trigger map + context gate)
  → Lead reads .agents/team_status.md for sprint context
  → reports: [LEAD] Session restored. Sprint: X | Active Task: #Y
     │
     ▼
 Layer 3: {project}/CLAUDE.md  (optional, project-specific)
  → project-specific build commands, architecture notes
     │
     ▼
Task arrives
     │
     ▼  L2 or L3 only
ContextController gate
  → produces CONTEXT_ADVISORY.md in .agents/working/#{issue}/
  → GREEN: proceed │ ORANGE: recommend /compact │ RED: hard stop
     │
     ▼
Specialist chain dispatch (Architect → Coder → QA → Auditor)
All deliverables written to .agents/working/#{issue}/
```

> **Why two steps?**
> Layer 1 makes Lead Agent globally available. Layer 2 gives it the sprint context
> for *this specific project*. Without Layer 2, Lead activates but has no task history.
> Without Layer 1, Lead never activates at all.

---

## 2. Agent Role Handbook

### Overview Table

| Agent | Activated By | Task Levels | Input | Output |
|---|---|---|---|---|
| **PM** | User trigger (`開始新任務：`) | All | Natural language request | Task Card + GitHub Issue |
| **Lead** | Auto (session start) | All | Task Card from PM | Routing decisions, gate checks |
| **ContextController** | Lead (pre L2/L3) | L2, L3 | Task + context state | CONTEXT_ADVISORY.md |
| **Architect** | Lead (L2/L3) | L2, L3 | Task Card + codebase context | SPEC_SHEET.md |
| **Coder** | Lead | All | SPEC_SHEET.md (L2/L3) or task (L1) | IMPLEMENTATION_LOG.md |
| **QA** | Lead (after Coder) | L2, L3 | IMPLEMENTATION_LOG + modified files | VERIFICATION_REPORT.md |
| **Auditor** | Lead (L3 only) | L3 only | All prior docs + modified files | PASS or BLOCK verdict |

---

### PM Agent — Product Manager

**File**: `agents/pm.md`

**Responsibilities**:
- Parse vague business requests into Epic → Story → Task hierarchies
- Create GitHub issues (`gh issue create`) with structured acceptance criteria
- Assign Priority (P0/P1/P2) and Complexity (L1/L2/L3)
- Update `.agents/team_status.md` Backlog section

**I/O Contract**:

```
INPUT:  Free-form user request ("開始新任務：實作 JWT Refresh Token")
OUTPUT: Task Card (see contracts/TASK_CARD.md)
        GitHub Issue URL
        team_status.md Backlog entry
        Handoff: "PM → Lead: Task #N ready. Complexity: L3, Priority: P1."
```

**Trigger**: User says `開始新任務：[name]` or `新增 Epic：[desc]`

---

### Lead Agent — Orchestrator

**File**: `agents/lead.md`

**Responsibilities**:
- Default active agent for every session
- Classify every task: L1 (trivial) / L2 (feature) / L3 (safety-critical)
- Activate ContextController before every L2/L3 dispatch
- Route work to correct specialist chain
- Enforce quality gates before PR creation

**Complexity Matrix**:

| Level | Criteria | Route | Coverage Gate |
|---|---|---|---|
| L1 | Docs, typo, config, dep bump | Coder only | Smoke test |
| L2 | New logic, refactor, API change | **CC** → Arch → Coder → QA | ≥ 80% |
| L3 | Concurrency, financial, auth, stability | **CC** → Arch → Coder → QA → Auditor | ≥ 90%, 100% critical path |

*CC = ContextController pre-flight gate*

---

### ContextController Agent — Token Budget Enforcer *(new in v2.1)*

**File**: `agents/context_controller.md`

**Responsibilities**:
- Mandatory pre-flight gate before every L2/L3 dispatch
- Estimate current context window usage (%)
- Define per-task read scope: MUST / SHOULD / MUST NOT read
- Produce `CONTEXT_ADVISORY.md` in `.agents/working/#{issue}/`
- Hard stop L3 when context > 80%

**Traffic Light**:

| Status | Context | Action |
|---|---|---|
| GREEN | < 50% | Proceed. No restrictions. |
| YELLOW | 50–70% | Warn. Selective reads. User consent to proceed. |
| ORANGE | 70–80% | Strongly recommend `/compact` first. |
| RED | > 80% | **HARD STOP** on L3. L2 requires explicit override. |

**I/O Contract**:

```
INPUT:  Task details + current session state (files read, agents loaded)
OUTPUT: .agents/working/#{issue}/CONTEXT_ADVISORY.md
        - Token budget breakdown (estimated)
        - Read scope: MUST / SHOULD / MUST NOT per file
        - Per-agent read guidance (Architect reads X, Coder reads Y only)
        - Compaction recommendation
        Handoff: "ContextController → Lead: GREEN (~21%). PROCEED."
```

---

### Architect Agent

**File**: `agents/architect.md`

**Responsibilities**:
- Context scan of affected modules (scope defined by ContextController)
- Threat modeling for L3 (race conditions, data loss, auth bypass)
- Produce SPEC_SHEET.md with interface contracts and risk table
- Flag Red Lines as CRITICAL

**Red Lines** (auto-CRITICAL):
- `threading.Lock()` in reentrant path (must be `RLock`)
- Shared mutable state without lock
- Financial math without `round(..., 10)` guard
- Timeout without cleanup (Ghost Order risk)
- Hardcoded credentials or JWT secret

---

### Coder Agent — Senior Engineer

**File**: `agents/coder.md`

**Responsibilities**:
- Implement per Architect's SPEC_SHEET (L2/L3) or task description (L1)
- Run 25-item Self-Review Checklist before handoff
- Write deliverables to `.agents/working/#{issue}/IMPLEMENTATION_LOG.md`
- Commit with `type(scope): description` format, staging explicitly by file

**Constraints**: No `git add -A`. No TODO placeholders. No features not in spec.

---

### QA Agent — Quality Gate

**File**: `agents/qa.md`

**Responsibilities**:
- Design tests: happy path, boundary, error, concurrency (L3)
- Run `pytest ... --cov` verification loop
- Write `VERIFICATION_REPORT.md` to `.agents/working/#{issue}/`
- Block if coverage below threshold; return to Coder if implementation bugs found

**Thresholds**: L1=smoke, L2=80%, L3=90% overall + 100% critical path.

---

### Auditor Agent — Reliability Gate

**File**: `agents/auditor.md`

**Responsibilities (L3 only)**:
- Thread safety audit (races, deadlocks, lock misuse)
- Financial precision audit (float guards, tick size, rounding)
- Production stability audit (ghost orders, restart recovery, websocket reconnect)
- Security audit (auth paths, token handling, credential storage)
- **I/O Compliance audit** (log safety, network timeouts, resource cleanup)
- Issue PASS or BLOCK verdict

**Hard Rule**: CRITICAL or HIGH finding = automatic BLOCK. Non-negotiable.

---

## 3. Communication Contracts (I/O)

Five standard documents drive all agent handoffs. All are written to `.agents/working/#{issue}/`.

| Contract | Created By | Consumed By | Template |
|---|---|---|---|
| CONTEXT_ADVISORY | ContextController | Lead, all agents | *(inline in context_controller.md)* |
| TASK_CARD | PM | Lead, Architect, Coder | `contracts/TASK_CARD.md` |
| SPEC_SHEET | Architect | Coder, Auditor | `contracts/SPEC_SHEET.md` |
| IMPLEMENTATION_LOG | Coder | QA, Auditor | `contracts/IMPLEMENTATION_LOG.md` |
| VERIFICATION_REPORT | QA | Lead, Auditor | `contracts/VERIFICATION_REPORT.md` |

Each template contains required and optional sections. Agents must not skip required sections.
Working documents live in `.agents/working/#{issue}/` and are gitignored (ephemeral to the task).

---

## 4. Manual Setup (no installer)

Use this if you prefer not to run the one-click installer.

### Step 1 — Clone the repo

```bash
git clone https://github.com/Taehyung0112/ai-dev-framework.git ~/ai-dev-framework
```

### Step 2 — Global machine setup

```bash
bash ~/ai-dev-framework/bin/claude-team init --global
```

**What gets created:**

```
~/.claude/
├── CLAUDE.md          ← imports lead.md + context_controller.md + all playbook files
└── framework/         ← symlink → ~/ai-dev-framework  (junction on Windows)
```

> **Windows**: Run in Git Bash as Administrator, or use the PowerShell installer above.
> Manual junction: `cmd /c mklink /J %USERPROFILE%\.claude\framework <path>`

### Step 3 — Verify

```bash
bash ~/ai-dev-framework/bin/claude-team doctor
```

### Step 4 — Project setup

```bash
cd ~/your-project
bash ~/ai-dev-framework/bin/claude-team init
```

**What gets created:**

```
your-project/
├── .clauderules            ← v2.1: session init + trigger map + context gate
└── .agents/
    ├── registry.json       ← points to shared framework
    ├── team_status.md      ← sprint context, task log, agent roster
    └── working/            ← gitignored: task working documents
        └── #{issue}/
            ├── CONTEXT_ADVISORY.md
            ├── SPEC_SHEET.md
            ├── IMPLEMENTATION_LOG.md
            ├── VERIFICATION_REPORT.md
            └── AUDIT_REPORT.md  (L3 only)
```

> **Commit** `.clauderules`, `registry.json`, `team_status.md` to your project repo.
> `.agents/working/` is gitignored.

### Step 5 — Daily use

Open Claude Code inside the project directory. Lead greets you:

```
╔═══════════════════════════════════════════════════════════════╗
║   Agentic Workflow 2.2  |  Lead is active                     ║
╠═══════════════════════════════════════════════════════════════╣
║    開始新任務: <描述>          → PM (Task Card + issue)        ║
║    /code-review-expert        → Deep review (SOLID + security)║
║    /security-audit            → STRIDE threat modeling        ║
║    /sprint-plan               → Sprint planning SOP           ║
║    /adr                       → Architecture Decision Record  ║
║    /tech-debt                 → Tech-debt triage              ║
║    /rollback #N               → Emergency rollback SOP        ║
║    /elite-powerpoint-designer → Elite slide design            ║
╚═══════════════════════════════════════════════════════════════╝
```

**Trigger words (v2.2)**:

| Say | Effect |
|---|---|
| `開始新任務：[description]` | PM → Task Card → Lead dispatch |
| `/review` | Coder Self-Review Checklist on current code |
| `/test` | QA generates tests for current context |
| `/refactor` | Coder refactors per Clean Code principles |
| `rollback #N` | Lead + Auditor emergency impact review |

---

## 5. claude-team CLI Reference

```
claude-team <command> [options]

Commands:
  init [--global]   Initialise agent workflow in current directory.
                    Always creates: .clauderules (v2.1), .agents/registry.json,
                                    .agents/team_status.md
                    --global: also creates ~/.claude/framework symlink/junction
                              and creates/updates ~/.claude/CLAUDE.md (v2.1 block).
                              Auto-runs doctor on completion.

  status            Display sprint dashboard from .agents/team_status.md.
                    Shows: project, sprint name/goal, active task + agent,
                           backlog / in-progress / done counts.

  update            Pull latest framework changes from git remote.
                    Monorepo-aware (ADR-007): walks up to git root automatically.
                    Supports both standalone and subdirectory layouts.

  doctor            Diagnose local environment. Checks:
                      gh, python3, pip3, pytest, node, vcpkg, git,
                      ~/.claude/framework symlink/junction,
                      .agents/team_status.md in current directory.
                    Reports: PASS / WARN / FAIL per dependency.

  help              Show this help text.
```

**Windows note**: use `.\bin\claude-team.ps1` or the injected `claude-team` PS function.

---

## 6. Team Sync — Updating the Playbook

### When to run `claude-team update`

Run after a teammate pushes changes to this repo:
- Playbook files updated (`playbook/*.md`)
- Agent definitions updated (`agents/*.md`)
- CLI script updated (`bin/claude-team`)

```bash
claude-team update
# restart Claude Code to pick up changes
```

### Pushing playbook changes

```bash
# 1. Edit the relevant file
edit ~/ai-dev-framework/playbook/coding-standards.md

# 2. Commit and push
cd ~/ai-dev-framework   # or cd monorepo root
git add playbook/coding-standards.md
git commit -m "chore(playbook): update Python logging standard"
git push

# 3. Notify teammates: claude-team update
```

### What syncs automatically (after `claude-team update` + restart)

| Changed In | Takes Effect |
|---|---|
| `playbook/*.md` | Next Claude Code session |
| `agents/*.md` | Next Claude Code session |
| `contracts/*.md` | When agent reads the template at task start |
| `bin/claude-team` | After `claude-team update` |

### What requires manual action

| Changed In | Action Required |
|---|---|
| `{project}/.clauderules` | Commit + push to project repo; teammates get it on `git pull` |
| `{project}/CLAUDE.md` | Commit + push to project repo |
| `{project}/.agents/team_status.md` | Updated automatically by Lead Agent; commit periodically |

---

## 7. Directory Structure

```
ai-dev-framework/
├── README.md                        ← This file (English)
├── README.zh-TW.md                  ← 繁體中文版
├── CLAUDE.md                        ← Claude Code project guidance + Session Start banner
├── .gitignore
│
├── agents/                          ← Agent definition files
│   ├── lead.md                      ← Lead Orchestrator (default agent)
│   ├── pm.md                        ← Product Manager
│   ├── context_controller.md        ← Token Budget Enforcer (v2.1)
│   ├── architect.md                 ← Architect
│   ├── coder.md                     ← Senior Coder
│   ├── qa.md                        ← QA Specialist
│   └── auditor.md                   ← Reliability Auditor (L3 only)
│
├── contracts/                       ← Agent I/O document templates
│   ├── TASK_CARD.md
│   ├── SPEC_SHEET.md
│   ├── IMPLEMENTATION_LOG.md
│   └── VERIFICATION_REPORT.md
│
├── playbook/                        ← Engineering standards (version: 2.1)
│   ├── claude-base.md
│   ├── coding-standards.md
│   ├── git-workflow.md
│   ├── architecture-guide.md
│   ├── testing-guide.md
│   ├── team-standards.md
│   ├── ai-workflow.md
│   └── pr-template.md
│
└── bin/
    ├── claude-team                  ← Management CLI (bash)
    ├── claude-team.ps1              ← Management CLI (PowerShell wrapper)
    ├── install.sh                   ← One-click installer (Linux / macOS)
    └── install.ps1                  ← One-click installer (Windows)
```

---

## 8. Configuration Layers

| Layer | File | Scope | Who Creates |
|---|---|---|---|
| Global | `~/.claude/CLAUDE.md` | Every session, every project | `claude-team init --global` |
| Global | `~/.claude/framework/` | Every session, every project | Installer / `init --global` |
| Repo | `.clauderules` | All sub-projects in this repo | `claude-team init` |
| Repo | `.agents/team_status.md` | Sprint context for this repo | `claude-team init`, Lead Agent |
| Project | `{project}/CLAUDE.md` | Only this project | Manually / `/init` |

**Priority order** (highest wins): Project > Repo > Global
