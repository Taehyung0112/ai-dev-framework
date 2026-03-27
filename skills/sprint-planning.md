# Skill: Sprint Planning

> Slash command: `/sprint-plan`
> Invoked by: PM Agent or Lead when starting a new sprint cycle.

---

## When to Use

- Start of every sprint (recommended: 2-week cadence)
- When backlog grows beyond 10 open issues
- When PM Agent has produced multiple TASK_CARDs needing prioritization

---

## Step 1 — Backlog Snapshot

```bash
# List open GitLab issues sorted by creation date
glab issue list --state opened --sort created_asc

# Or GitHub
gh issue list --state open --json number,title,labels,assignees
```

Record: `#id | title | label | assignee` for each open issue.

---

## Step 2 — Complexity Classification

Apply Lead's complexity matrix to every unclassified issue:

| Complexity | Criteria | Typical Effort |
|---|---|---|
| **L1** | Doc, typo, config, dep bump — no new logic | 0.5–2h |
| **L2** | New function/class, API change, refactor | 2–8h |
| **L3** | Concurrency, financial, auth, production stability | 8–40h |

GitLab label: `complexity::L1`, `complexity::L2`, `complexity::L3`

**Rule**: When in doubt, classify higher. Never downgrade L3 → L2 to fit a sprint.

---

## Step 3 — Sprint Capacity Formula

```
Available hours = working_days × 6h × devs × (1 - overhead_rate)

Example (2-week sprint, 3 devs, 20% overhead):
  10 × 6 × 3 × 0.8 = 144h

Allocation:
  L1 buffer:   ≤ 10% (≈ 14h)
  L2 main:     60–70% (≈ 86–100h)
  L3 critical: ≤ 30%, max 1 item (≈ 43h)
```

---

## Step 4 — Priority Pull Order

```
P0 — Production bugs (always pull in first)
P1 — Features blocking other work
P2 — Standard roadmap features
P3 — Tech debt / nice-to-have
```

Pull top-down until capacity reached. Leave 15% buffer for unplanned L1s.

---

## Step 5 — Dependency Check

Before finalizing:
- `#A blocks #B` → A must be in same or earlier sprint
- External team dependency → add `EXTERNAL_DEPENDENCY` label + 2-day buffer
- Circular dependency → resolve immediately with team

---

## Step 6 — GitLab Milestone

```bash
glab milestone create "Sprint {N} ({start} – {end})"
glab issue update {id} --milestone "Sprint {N}"
```

Milestone description:
```
## Sprint {N} Goal
{one sentence: what ships this sprint?}

## Capacity: {X}h available | {Y}h planned
## L3 items (require Auditor sign-off): #{id} — {title}
```

---

## Step 7 — Kickoff Checklist

```
- [ ] All sprint issues have complexity label (L1/L2/L3)
- [ ] All sprint issues have priority label (P0/P1/P2/P3)
- [ ] All assigned to a developer
- [ ] L3 issues: Architect notified at sprint start
- [ ] External dependencies flagged
- [ ] GitLab milestone created with correct dates
- [ ] team_status.md sprint section updated
```

---

## Sprint Review (End of Sprint)

1. Move incomplete issues to next sprint (do not force-close)
2. Record actual vs estimated effort in issue comment
3. If L2 consistently underestimated → reclassify as L3 for future
4. Update `.agents/team_status.md` sprint section

---

## Agent Roles During Sprint

| Agent | Role |
|---|---|
| PM | Produces TASK_CARDs for each sprint issue |
| Lead | Classifies complexity, enforces gates |
| Architect | Pre-reviews all L3 at sprint start |
| Coder | One branch per issue |
| QA | Blocks merge if coverage < threshold |
| Auditor | Required sign-off on all L3 before merge |
