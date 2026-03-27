# Skill: Tech Debt & Refactoring

> Slash command: `/tech-debt`
> Invoked by: Architect Agent or Developer before tackling accumulated debt.

---

## Rule Zero

**Refactoring must not change observable behavior.**

Before touching code:
1. Tests must exist and pass
2. Commit the green baseline first
3. Refactor in small steps, run tests after each
4. On unexpected red → revert immediately, investigate separately

---

## Phase 1: Triage Matrix

| Category | Examples | Priority |
|---|---|---|
| **Critical** | Race condition, memory leak, wrong financial calc | Fix now (L3 task) |
| **High** | God class > 800 lines, duplicated business logic, no error handling | This sprint (L2) |
| **Medium** | Magic numbers, unclear naming, missing tests | Next sprint |
| **Low** | Minor style inconsistencies | MINOR commit, opportunistic |

**Scoring**: Impact (1–5) / Effort (1–5) = priority score. Higher = do sooner.

---

## Phase 2: Refactoring Patterns

### Extract Function
```cpp
// BEFORE: fetch + transform in one 80-line function
OrderData GetOrder(std::string id) { /* 80 lines */ }

// AFTER
RawOrderResponse FetchOrder(std::string id);
OrderData MapToOrderData(const RawOrderResponse& raw);
```
Commit: `REFACTOR: {scope} — extract {FunctionName} from {Original}`

### Eliminate Duplication
Test before unifying: "If rule for A changes, must rule for B change identically?"
- YES → safe to unify (same concept)
- NO → keep separate ("wrong abstraction" trap)

### Rename for Clarity
```python
# BEFORE
def proc_ord(o): ...

# AFTER
def process_order_submission(order: OrderSubmission) -> OrderResult: ...
```
Commit: `MINOR: {scope} — rename proc_ord to process_order_submission`

### Break Up God Class (> 800 lines)
Split into TWO commits:
```
Commit 1: CHORE: {scope} — extract {NewClass} skeleton from {GodClass}
Commit 2: REFACTOR: {scope} — migrate {responsibility} to {NewClass}
```

### Replace Magic Numbers
```cpp
// BEFORE
if (retry_count > 3) sleep(200);

// AFTER
constexpr int kMaxRetries = 3;
constexpr int kRetryDelayMs = 200;
if (retry_count > kMaxRetries) sleep(kRetryDelayMs);
```

### Fix Swallowed Errors
```python
# BEFORE
try:
    result = submit_order(order)
except Exception:
    pass  # silent failure

# AFTER
try:
    result = submit_order(order)
except OrderSubmissionError as e:
    logger.error("Order submission failed: uid=%s, reason=%s", order.uid, e)
    raise
```

---

## Phase 3: Safe Refactoring Protocol

```
1. READ  — fully read target code before touching
2. RUN   — all tests pass (baseline)
3. WRITE — add missing tests if coverage < 80% on target
4. COMMIT baseline: "TEST: {scope} — baseline tests before refactor"
5. REFACTOR one unit at a time
6. RUN tests after each unit (rollback if red)
7. COMMIT each unit separately
8. /code-review-expert before merging
```

---

## Phase 4: Commit Format

| Change | Format |
|---|---|
| Rename only | `MINOR: {scope} — rename {old} to {new}` |
| Extract function | `REFACTOR: {scope} — extract {FunctionName}` |
| Break up class | `REFACTOR: {scope} — split {GodClass} into {A} + {B}` |
| Magic numbers | `MINOR: {scope} — replace magic numbers with named constants` |
| Remove dead code | `CHORE: {scope} — remove unused {FunctionName}` |
| Fix error handling | `REFACTOR: {scope} — replace swallowed errors with structured handling` |

---

## Phase 5: Tech Debt Register

Maintain `docs/tech-debt.md`:
```markdown
| ID | Description | File | Impact | Effort | Status |
|----|-------------|------|--------|--------|--------|
| TD-001 | OrderGateway::Process() > 200 lines | order-gateway/src/... | HIGH | MEDIUM | Pending |
```

Update when: debt found in review, debt resolved, debt severity increases.

---

## Anti-Patterns

| Pattern | Why Dangerous |
|---|---|
| Refactor + feature in same commit | Reviewer can't tell what changed behavior |
| Refactor without tests | Silent regression — "looks right" is not a test |
| Big-bang refactor PR | Impossible to review |
| Premature abstraction | Things that seemed similar diverge later |
| Rename everything at once | Breaks `git blame` traceability |
