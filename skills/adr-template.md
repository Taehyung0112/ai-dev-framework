# Skill: Architecture Decision Record (ADR)

> Slash command: `/adr`
> Invoked by: Architect Agent when a significant technical decision is made.

---

## When to Write an ADR

Write when a decision:
- Affects multiple services or teams
- Is hard to reverse once made
- Involves a significant trade-off or rejected alternative
- Would confuse a new engineer reading the code 6 months later

**Historical examples in incubator:**
- ADR-005: ai-dev-framework lives as monorepo subdirectory (not standalone)
- ADR-006: `~/.claude/framework` uses Directory Junction on Windows
- ADR-007: `claude-team update` uses `git rev-parse --show-toplevel`

---

## Numbering + Location

Sequential: `ADR-001`, `ADR-002`, ...

Store at: `docs/adr/ADR-{NNN}-{kebab-title}.md`

```bash
# Find next number
ls docs/adr/ | sort | tail -1
```

---

## ADR Template

```markdown
# ADR-{NNN}: {Title}

**Status**: {Proposed | Accepted | Deprecated | Superseded by ADR-XXX}
**Date**: {YYYY-MM-DD}
**Deciders**: {names or roles}
**Technical area**: {Infrastructure | SDK | CI/CD | Auth | Protocol}

---

## Context

{2–4 sentences. The problem or situation requiring a decision.
No solution yet — just the forces at play and constraints.}

## Decision

We will {one clear sentence}.

- {Why this over alternatives — 2–5 bullet points}
- {What makes this right for incubator specifically}

## Consequences

### Positive
- {benefit}

### Negative / Trade-offs
- {honest cost — no free lunches}

### Neutral
- {side effects}

## Rejected Alternatives

| Alternative | Why Rejected |
|---|---|
| {option A} | {reason} |
| {option B} | {reason} |

## Related

- ADR-{NNN}: {related}
- Issue #{N}: {related issue}
- `{file}`: {code implementing this decision}
```

---

## Status Lifecycle

```
Proposed → Accepted → Deprecated
                   ↘ Superseded by ADR-XXX
```

When superseding, update old ADR:
```
**Status**: Superseded by ADR-{NNN}
```

---

## ADR Index

Maintain `docs/adr/README.md`:
```markdown
| ADR | Title | Status | Date |
|-----|-------|--------|------|
| ADR-001 | ... | Accepted | YYYY-MM-DD |
```

---

## Commit Format

```
DOCS: adr — add ADR-{NNN}: {title}
DOCS: adr — supersede ADR-{NNN} with ADR-{MMM}
```

---

## Pre-Acceptance Checklist

```
- [ ] Context section states problem without hinting at solution
- [ ] Decision starts with "We will..."
- [ ] At least 2 rejected alternatives documented
- [ ] At least 1 negative consequence (trade-off)
- [ ] Related ADRs and issues linked
- [ ] docs/adr/README.md index updated
```
