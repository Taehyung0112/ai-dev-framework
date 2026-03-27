# Team Status Wall
<!-- Auto-updated by Lead Agent after every handoff. Do not edit manually. -->

**Project**: incubator / ai-dev-framework
**Last Updated**: 2026-03-23
**Framework**: incubator/ai-dev-framework/

---

## Current Sprint

**Sprint Name**: `sprint/agentic-workflow-bootstrap`
**Sprint Goal**: 建立並驗證 Agentic Workflow 2.0 基礎建設，部署至 incubator 主倉庫
**Sprint Start**: 2026-03-23
**Sprint End**: TBD

---

## Active Task

| Field | Value |
|---|---|
| Issue | — |
| Title | — |
| Complexity | — |
| Priority | — |
| Active Agent | **Lead** |
| Status | Idle — Ready for dispatch |

---

## Backlog

| Issue | Level | Priority | Title | Assigned Agent |
|---|---|---|---|---|
| — | — | — | *No tasks queued. Use `開始新任務：[name]` to create one.* | — |

---

## In Progress

| Issue | Level | Stage | Agent | Started |
|---|---|---|---|---|
| — | — | — | — | — |

---

## Done (This Sprint)

| Issue | Level | Title | Completed | Notes |
|---|---|---|---|---|
| local-1 | L1 | chore(framework): init Agentic Workflow 2.0 (standalone git repo) | 2026-03-23 | Initial 3-commit standalone repo. Superseded by local-2. |
| local-2 | L1 | chore(framework): add .gitattributes for cross-platform line endings | 2026-03-23 | Committed within standalone repo. History preserved conceptually. |
| local-3 | L1 | chore(framework): merge ai-dev-framework into incubator monorepo | 2026-03-23 | Branch: `chore/justin/ai-dev-framework/init-framework`. Pushed to `ssh://192.168.199.39:10022/pt-ii/incubator.git`. MR pending token. |

---

## Decision Log

| Timestamp | Agent | Decision | Rationale |
|---|---|---|---|
| 2026-03-23 | Lead | System initialized | claude-team init completed |
| 2026-03-23 | Lead | Classified local-1 as L1 | Pure config change (.gitattributes), no logic |
| 2026-03-23 | Lead | BLOCKED push to pt-ii/incubator (standalone repo) | Would overwrite incubator history. Redirected to Option A. |
| 2026-03-23 | Lead | Option A selected: merge into incubator monorepo | User confirmed. Safer, consistent with existing project structure (sdk/, order-hub/, etc.) |
| 2026-03-23 | Lead | Pulled develop (65 commits behind) before branch creation | Ensures branch is cut from latest; prevents stale-base merge conflicts |
| 2026-03-23 | Coder | Removed ai-dev-framework/.git after verifying 24 files in working tree | All files confirmed independent of git objects before deletion |
| 2026-03-23 | Lead | local-3 gates passed | 24 files staged explicitly, commit message valid, push succeeded |

---

## Architecture Decisions (ADR)

| # | Decision | Status | Date |
|---|---|---|---|
| ADR-001 | Use threading.RLock for all lazy-init properties | Accepted | 2026-03-10 |
| ADR-002 | Assign initialized objects LAST in double-check-lock pattern | Accepted | 2026-03-10 |
| ADR-003 | Ghost Order: _on_submit must handle late-callback after timeout cleanup | Accepted | 2026-03-10 |
| ADR-004 | reconcile_from_server uses user_defined_id as primary key (restart-safe) | Accepted | 2026-03-10 |
| ADR-005 | ai-dev-framework lives as a subdirectory of incubator monorepo (not standalone) | Accepted | 2026-03-23 |
| ADR-006 | ~/.claude/framework uses Windows directory junction (not symlink) on Win11 | Accepted | 2026-03-23 |
| ADR-007 | claude-team update uses git -C to pull from incubator remote, not standalone repo | Pending | 2026-03-23 |

---

## Known P1 Backlog

| # | Item | Owner | Status |
|---|---|---|---|
| P1-1 | JWT Refresh Token (short-lived AT + long-lived RT) | TBD | Pending |
| P1-2 | JWT Validation LRU Cache (SHA-256 key) | TBD | Pending |
| P1-3 | Evaluate nlohmann/json → RapidJSON in SDK | TBD | Pending |
| P1-4 | Update claude-team update to point at incubator remote path | TBD | Pending (ADR-007) |

---

## MR Tracker

| Branch | Target | Status | Link |
|---|---|---|---|
| `chore/justin/ai-dev-framework/init-framework` | `develop` | **Opened** — `!40` | `https://192.168.199.39:30000/pt-ii/incubator/-/merge_requests/40` |

---

## Agent Roster

| Agent | File | Status |
|---|---|---|
| PM | `ai-dev-framework/agents/pm.md` | Ready |
| Lead | `ai-dev-framework/agents/lead.md` | Active |
| Architect | `ai-dev-framework/agents/architect.md` | Ready |
| Coder | `ai-dev-framework/agents/coder.md` | Ready |
| QA | `ai-dev-framework/agents/qa.md` | Ready |
| Auditor | `ai-dev-framework/agents/auditor.md` | Ready (L3 only) |
