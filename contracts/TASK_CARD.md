# Contract: TASK_CARD

**Produced by**: PM Agent
**Consumed by**: Lead Agent, Architect Agent, Coder Agent (L1)
**Purpose**: Transform a user request into a structured, actionable work item with a GitHub issue anchor.

---

## Template

```markdown
### Task Card

| Field | Value |
|---|---|
| **Issue** | #{github_issue_number} |
| **Title** | [TYPE] scope: short description |
| **Epic** | {epic_name_or_parent_issue} |
| **Complexity** | L{1 \| 2 \| 3} |
| **Priority** | P{0 \| 1 \| 2} |
| **Project** | {freqtrade_sdk \| order-hub \| order-gateway \| ticker \| pkg \| cpp \| ai-dev-framework} |
| **Estimated Stories** | {n} |
| **Routing** | → Lead Agent |

### Acceptance Criteria

- [ ] {criterion 1 — observable, testable outcome}
- [ ] {criterion 2 — edge case or error path covered}
- [ ] {criterion 3 — performance or security constraint if applicable}

### Context

{1–3 sentences explaining WHY this task exists and what business problem it solves.}

### Out of Scope

- {thing that looks related but is explicitly NOT part of this task}

### Dependencies

- Blocks: #{issue} (if this task must finish before another can start)
- Blocked by: #{issue} (if this task cannot start until another is done)
```

---

## Field Definitions

### Complexity Classification

| Level | Decision Rules |
|---|---|
| **L1** | Documentation, typo fix, dependency version bump, config-only change. No new logic. No concurrency. |
| **L2** | New function/class, API surface change, refactor of existing module. Non-concurrent logic. No safety-critical path. |
| **L3** | Any of: concurrency / threading / locks / callbacks. Financial calculations. JWT / auth. Production stability (Ghost Order risk, restart recovery, WebSocket). Data integrity. |

**When in doubt, classify higher.** It is safe to over-classify L2→L3 (adds Auditor review).
It is DANGEROUS to under-classify L3→L2 (skips Auditor, production risk).

### Priority Classification

| Priority | When to Use | SLA |
|---|---|---|
| **P0** | Production broken, security breach, data loss, CI completely down | Immediate — drop everything |
| **P1** | Feature blocking a release, CI partially failing, P0 risk if deferred | Same day |
| **P2** | Improvement, refactor, documentation, nice-to-have | Next sprint |

### Title Format

```
[FEATURE] sdk: add StockHubClientImpl business logic
[FIX]     order-hub: fix JWT expiry not refreshed on reconnect
[CHORE]   freqtrade-sdk: bump pytest to 8.x
[REFACTOR] order-gateway: extract auth middleware to separate module
```

---

## Example

```markdown
### Task Card

| Field | Value |
|---|---|
| **Issue** | #42 |
| **Title** | [FEATURE] sdk: add JWT Refresh Token (short-lived AT + long-lived RT) |
| **Epic** | Authentication Hardening |
| **Complexity** | L3 |
| **Priority** | P1 |
| **Project** | order-hub |
| **Estimated Stories** | 3 |
| **Routing** | → Lead Agent |

### Acceptance Criteria

- [ ] Access Token lifetime configurable (default: 15 min)
- [ ] Refresh Token lifetime configurable (default: 7 days)
- [ ] Expired AT + valid RT → new AT issued, no re-login required
- [ ] Expired AT + expired RT → 401, client must re-authenticate
- [ ] Refresh Token rotation: old RT invalidated after use
- [ ] All token paths covered by tests (100% critical path)

### Context

Current JWT implementation uses long-lived AT (24h). Legal flagged this as a compliance
issue (ADR from 2026-03-18 architecture review). Needs short-lived AT + long-lived RT.

### Out of Scope

- Token revocation list / blacklist (tracked separately as #43)
- Mobile app changes (separate repo)

### Dependencies

- Blocks: #44 (rate-limiter refactor assumes new auth flow)
- Blocked by: none
```
