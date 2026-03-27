# Skill: Rollback Procedure

> Slash command: `/rollback #N`
> Invoked by: Lead Agent or Auditor in an emergency.

---

## Decision Tree

```
Problem in production?
  YES → Section A: Production Rollback
  NO  → Merged to develop but not deployed?
           YES → Section B: Git Revert
           NO  → Still on feature branch?
                    YES → Section C: Branch Cleanup
```

---

## Section A: Production Rollback

### A1 — Assess (max 5 min)

1. Symptom: crash? data corruption? wrong behavior? performance?
2. Blast radius: which services? which users? how many?
3. Trigger: which MR last merged? which deploy ran?

```bash
git log --merges --oneline develop | head -5
glab pipeline list --status success | head -5
```

### A2 — Declare Incident

```
[INCIDENT] {service} degraded / down
Trigger: MR !{N} merged at {HH:MM}
Impact: {describe}
Lead: {name}  |  ETA update: 15 min
```

### A3 — Execute Rollback

**Option 1 — Re-deploy previous image (fastest)**
```bash
docker images {service} --format "{{.Tag}}" | head -5
# Update deployment config to previous tag → trigger CI
```

**Option 2 — Git revert bad merge commit**
```bash
git checkout develop && git pull --ff-only origin develop
git log --merges --oneline | head -5
# → a1b2c3d Merge branch 'feature/...' into develop

git revert -m 1 {merge_commit_hash}
# -m 1 = keep mainline (develop) parent

git push origin develop   # triggers CI → new deployment
```

### A4 — Verify

```
- [ ] Service health check passes
- [ ] Critical flow (order placement) works end-to-end
- [ ] No error spike in logs
- [ ] Incident declared resolved in team chat
```

### A5 — Post-Mortem (within 24h)

File issue: `POST-MORTEM: {service} {date}` with label `post-mortem, P0`
Use 5-Whys. Update checklist to prevent recurrence.

---

## Section B: Git Revert on develop

```bash
git checkout develop && git pull --ff-only origin develop
git revert -m 1 {merge_commit_hash}
git commit -m "CHORE: develop — revert MR !{N}: {reason}"
git push origin develop
```

**Do NOT use `git reset --hard` on develop** — rewrites shared history.

---

## Section C: Branch Cleanup

```bash
# Soft reset to last known good commit
git reset --soft {good_commit_hash}
git stash   # or discard

# Or full branch teardown
git checkout develop
glab mr close {mr_id}
git branch -D feature/...
git push origin --delete feature/...
```

---

## Section D: Database Rollback

**STOP — requires human sign-off before proceeding.**

```
- [ ] Check if migration ran (migrations table)
- [ ] Confirm rollback migration (down()) exists
- [ ] Confirm no data written under new schema
- [ ] Get explicit sign-off from technical lead
- [ ] Run rollback in staging first
- [ ] Execute in production with DBA present
```

If data was already written under new schema: **do not roll back migration** — write a forward fix migration instead.

---

## Rollback Checklist

```
- [ ] Incident declared with blast radius
- [ ] Root cause identified (approximate OK)
- [ ] Rollback method chosen
- [ ] Verified in staging first (if time allows)
- [ ] Applied to production
- [ ] Service health confirmed
- [ ] Incident closed in team chat
- [ ] Post-mortem issue filed within 24h
- [ ] team_status.md updated
```
