# Contract: SPEC_SHEET

**Produced by**: Architect Agent
**Consumed by**: Coder Agent, Auditor Agent
**Purpose**: Define the complete technical blueprint that Coder must follow.
No code is written until a SPEC_SHEET is approved for L2/L3 tasks.

---

## Template

```markdown
## Design Spec: {task title} (#{issue})

**Architect**: {date}
**Risk Level**: CRITICAL | HIGH | MEDIUM | LOW
**Task Level**: L2 | L3

---

### Approach

{1–3 paragraphs describing the solution strategy and why it was chosen over alternatives.
Include: which layers are affected, what the data flow looks like, key invariants to preserve.}

---

### Interface Contract

#### New / Modified Functions

\`\`\`python
# Python example — adapt to C++ or TypeScript as needed
def method_name(
    param_a: TypeA,
    param_b: TypeB = default_value,
) -> ReturnType:
    """
    One-line description.

    Pre-conditions:
      - param_a must be non-empty
      - param_b must be positive

    Post-conditions:
      - Returns X when Y
      - Raises ValueError if Z

    Thread safety: [Safe | Not safe — callers must synchronize]
    """
\`\`\`

#### Data Shapes / Schemas

\`\`\`python
# Dict structure, dataclass, or TypedDict as applicable
class OrderState(TypedDict):
    user_defined_id: str
    status: Literal["pending", "submitted", "filled", "cancelled"]
    filled_qty: int
    price: float
\`\`\`

#### Module Boundaries

```
module_a.py  →  calls  →  module_b.method()   [direct import, OK]
module_a.py  →  calls  →  module_c.method()   [must go through module_b, not direct]
```

---

### Risk Assessment

| # | Severity | Area | Risk | Mitigation |
|---|---|---|---|---|
| R1 | 🔴 CRITICAL | Thread Safety | description of race condition | use RLock, assign object LAST |
| R2 | 🟠 HIGH | Financial | float accumulation drift | round(..., 10) guard on all sums |
| R3 | 🟡 MEDIUM | Logging | sensitive field in log output | filter before logging |
| R4 | 🔵 LOW | Style | inconsistent naming | follow coding-standards.md §4.1 |

---

### Rejected Alternatives

- **Alternative A — {name}**: Rejected because {concrete reason — e.g., "introduces a new
  shared lock that would deadlock with existing callback path in order_tracker.py:L142"}.
- **Alternative B — {name}**: Rejected because {reason}.

---

### Implementation Notes for Coder

> These are hard constraints. Deviating requires Lead Agent approval and a Design Amendment.

- NOTE 1: Use `threading.RLock()` (not `Lock`) — the `_on_submit` callback can re-enter
  this property from a C++ thread while `_init_lock` is held by the main thread.
- NOTE 2: Assign the fully-constructed object to the instance variable LAST, after all
  callbacks are registered (double-check locking pattern — see ADR-002).
- NOTE 3: All financial quantities must pass through `round(value, 10)` before accumulation.
- NOTE N: {specific constraint for this task}

---

### Auditor Focus Areas (L3 only)

> These are the highest-risk sections Auditor must scrutinize independently.

- [ ] {module}:{line_range} — {why it is high-risk}
- [ ] Verify R1 mitigation is implemented correctly (not just present)
- [ ] Verify late-callback handling in `_on_submit` does not create ghost order

---

### Files Expected to Change

| File | Change Type | Reason |
|---|---|---|
| `src/module/file.py` | Modify | Add new method per interface contract |
| `tests/module/test_file.py` | Create | QA will write; listed here for awareness |
| `src/module/other.py` | Read-only | Context dependency, no changes needed |

---

### Definition of Done (for Coder)

- [ ] All interface contracts implemented exactly as specified
- [ ] All Implementation Notes respected
- [ ] Self-Review Checklist in coder.md fully passed
- [ ] No deviation from spec without Lead Agent approval
```

---

## Design Amendment Process

If Coder discovers a spec conflict during implementation:

1. **Stop implementation** of the conflicting section.
2. Report to Lead: `"Coder → Lead: Spec conflict in #N. {specific conflict}. Requesting design amendment."`
3. Lead routes back to Architect for a targeted amendment (not a full re-design).
4. Architect produces an **Amendment Note** appended to the original SPEC_SHEET.
5. Lead re-approves. Coder resumes.

This prevents silent spec drift and keeps the SPEC_SHEET as the true record of design intent.
