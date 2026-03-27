# Contract: IMPLEMENTATION_LOG

**Produced by**: Coder Agent
**Consumed by**: QA Agent, Auditor Agent
**Purpose**: Record every file changed, every design decision made during implementation,
and confirm that all Self-Review Checklist items passed.

---

## Template

```markdown
## Implementation Log: {task title} (#{issue})

**Coder**: {date}
**Spec Reference**: SPEC_SHEET #{issue} ({date of spec})
**Spec Deviations**: None | See §Amendments section

---

### Files Modified

| File | Change Type | Lines Changed | Summary |
|---|---|---|---|
| `src/module/file.py` | Modified | +45 / -12 | Added `wait_for_submit` timeout cleanup |
| `src/module/other.py` | Modified | +8 / -0 | Added RLock import and init pattern |
| `src/module/__init__.py` | Modified | +2 / -0 | Exported new public method |

### Files NOT Modified (context only)

| File | Reason |
|---|---|
| `src/module/related.py` | Read for context; no changes needed per spec |

---

### Implementation Decisions

> Document every non-obvious choice made during coding. QA and Auditor use this to
> understand intent, not guess it.

1. **{Decision name}**: {What was decided and why. Reference spec note if applicable.}
   - Example: "Used `copy.copy()` instead of direct dict access in `get_order()` to
     prevent callers from racing with in-place callback updates (see SPEC_SHEET NOTE 2)."

2. **{Decision name}**: {What was decided and why.}

---

### Spec Amendments (if any)

> If any deviation from SPEC_SHEET was required and approved by Lead:

| # | Original Spec | Amendment | Lead Approval |
|---|---|---|---|
| A1 | Use `X` pattern | Used `Y` instead because {reason} | Lead approved {date} |

---

### Self-Review Checklist

> Full checklist: `playbook/coder-self-review.md` — copy and fill in the checkboxes below.
> Safety items cross-reference: `playbook/red-lines.md`

#### Code Quality
- [ ] Functions < 50 lines
- [ ] Files < 800 lines
- [ ] No deep nesting (> 4 levels)
- [ ] No unused imports / variables / functions
- [ ] No defensive over-wrapping of already-validated params

#### Language Compliance (mark N/A if not applicable)
- [ ] Python: module docstring, type hints, RLock, double-check locking
- [ ] TypeScript: no `any`, return types, createLogger(), config validated at startup
- [ ] C++: header guards, trailing_underscore_, kPrefixCamelCase, no `using namespace` in headers

#### Safety (always check — ALL languages)
- [ ] No hardcoded keys, passwords, or absolute file paths  ← red-lines.md §4
- [ ] No financial math without `round(..., 10)` precision guard  ← red-lines.md §2
- [ ] No `threading.Lock()` in reentrant callback paths  ← red-lines.md §1
- [ ] Timeout logic has cleanup (no Ghost Order risk)  ← red-lines.md §3
- [ ] Public API has docstring / type annotations
- [ ] Log statements do not output passwords, tokens, or private keys  ← red-lines.md §4

---

### Commit Reference

```
commit {sha}
{type(scope): description}

{body with Closes #{issue}}
```

---

### Handoff Statement

"Coder → Lead: Implementation complete for #{issue}.
 Files modified: {count} ({list}).
 Self-review: all {N} items passed.
 Spec deviations: {None | see §Amendments}.
 Ready for QA."
```

---

## Notes for QA

When reading this log:
1. **Check the Files Modified table** — every file listed here should have test coverage.
2. **Read Implementation Decisions** — these often reveal edge cases worth testing.
3. **Check Spec Amendments** — any deviation from spec may introduce unintended behavior.
4. **Verify Self-Review Checklist** — if Coder marked an item as done, write a test that validates it.
