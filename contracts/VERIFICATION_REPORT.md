# Contract: VERIFICATION_REPORT

**Produced by**: QA Agent
**Consumed by**: Lead Agent, Auditor Agent
**Purpose**: Provide objective evidence that the implementation meets quality thresholds.
A VERIFICATION_REPORT is required before any PR is created.

---

## Template

```markdown
## QA Verification Report: {task title} (#{issue})

**QA**: {date}
**Implementation Log Reference**: #{issue} ({date})
**Verdict**: PASS | FAIL

---

### Test Results

\`\`\`
pytest tests/ -v --tb=short --cov=src --cov-report=term-missing

{paste pytest summary output here}

===== {N} passed, {M} failed, {K} warnings in {t}s =====
\`\`\`

---

### Coverage Report

| Module | Statements | Covered | Coverage | Threshold | Status |
|---|---|---|---|---|---|
| `src/module/file.py` | 120 | 114 | 95% | 80% | ✅ |
| `src/module/critical.py` | 45 | 45 | 100% | 100% | ✅ |
| `src/module/other.py` | 32 | 24 | 75% | 80% | ❌ BELOW |
| **TOTAL** | **197** | **183** | **93%** | **80%** | **✅** |

**Coverage Threshold Rules**:
- L1 tasks: smoke test only, no threshold
- L2 tasks: ≥ 80% overall required
- L3 tasks: ≥ 90% overall + 100% on critical path (concurrency, financial, auth, state machine)

---

### Failures (if any)

| # | Test Name | Failure Type | Root Cause | Action |
|---|---|---|---|---|
| 1 | `test_timeout_cleanup_removes_event` | Implementation Bug | `_submit_events` not cleared on timeout | Return to Coder |
| 2 | `test_concurrent_init_creates_once` | Test Bug | Barrier size mismatch (10 vs 5) | Fixed in test |

**Failure Types**:
- **Implementation Bug**: Source code does not behave as specced. Return to Coder via Lead.
- **Test Bug**: The test itself was wrong. QA fixes the test and re-runs.
- **Spec Gap**: Neither code nor test is wrong; spec was ambiguous. Escalate to Lead → Architect.

---

### Edge Cases Verified

- [x] Happy path — normal inputs, expected outputs
- [x] Boundary values — 0, negative, max, empty string, None
- [x] Error path — timeout, exception, invalid state
- [x] Concurrency — N=10 threads, `threading.Barrier` synchronisation (L3 required)
- [x] Late callback — arrives after timeout cleanup (Ghost Order check)
- [x] Restart recovery — empty in-memory state, `reconcile_from_server()` path
- [ ] {uncovered scenario — reason why not covered — flagged for Auditor}

---

### Test Patterns Used

| Pattern | Test | Rationale |
|---|---|---|
| threading.Barrier concurrency | `test_concurrent_init_creates_once` | Amplify race window to detect L3 init races |
| Late callback / ghost order | `test_late_callback_does_not_create_ghost_order` | Verify timeout cleanup prevents orphan state |
| AAA structure | all tests | Arrange → Act → Assert, no shared mutable state |

---

### Regression Check

- [ ] All previously passing tests still pass
- [ ] No new warnings introduced
- [ ] No existing test modified to accommodate new code (unless spec change)

---

### Recommendation

**If PASS**:
> "QA → Lead: #{issue} passed verification. Coverage: {n}%.
>  {L2: Ready for PR creation.}
>  {L3: Ready for Auditor sign-off.}"

**If FAIL**:
> "QA → Lead: #{issue} failed verification. {N} implementation bugs found.
>  Return to Coder. See failures table above."
```

---

## Concurrency Test Pattern Reference

From project history — use for all L3 tasks involving shared state:

```python
def test_concurrent_init_creates_once(mock_cls):
    """Race condition: N threads simultaneously trigger lazy init."""
    import threading, time
    N = 10
    barrier = threading.Barrier(N)
    created_count = 0

    def slow_factory(**kwargs):
        nonlocal created_count
        created_count += 1
        time.sleep(0.02)  # Amplify race window to expose lock defects
        return MagicMock()

    mock_cls.side_effect = slow_factory
    threads = [Thread(target=lambda: (barrier.wait(), subject.property)) for _ in range(N)]
    [t.start() for t in threads]
    [t.join() for t in threads]
    assert created_count == 1  # Exactly one init despite N racers
```

## Ghost Order Test Pattern Reference

```python
def test_late_callback_does_not_create_ghost_order(tracker, caplog):
    """Critical: late callback after timeout must NOT create orphan order."""
    tracker.register_pending_submit(uid)
    tracker.wait_for_submit(uid, timeout=0.01)  # Force timeout

    with caplog.at_level(logging.WARNING):
        tracker._on_submit({"user_defined_id": uid, "success": True})

    assert tracker.get_order(uid) is None        # No ghost order
    assert "Late submit callback" in caplog.text  # Warning logged
```
