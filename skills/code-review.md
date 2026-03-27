# Skill: Code Review (incubator)

> Slash command: `/code-review`
> Primary tool: `/code-review-expert` (sanyuan0704, installed at `~/.claude/skills/code-review-expert/`)
> This file extends code-review-expert with incubator-specific rules.

---

## How to Invoke

```
/code-review-expert
```

The above runs the full SOLID + security + quality review on current git diff.

After getting the report, apply the **incubator overlay** below.

---

## incubator-Specific Review Overlay

After running `/code-review-expert`, additionally check the following items that are specific to this codebase.

### 1. Commit Message Format (UPPERCASE)

Every commit in this diff must follow:
```
TYPE: scope — subject
```
- TYPE is ALL CAPS: `FEATURE`, `FIX`, `MINOR`, `CI`, `REFACTOR`, `CHORE`, `DOCS`, `TEST`
- Separator is em dash `—` (U+2014), NOT hyphen `-`
- Subject is lowercase, verb-first, ≤ 72 chars

Flag any commit that uses `feat(scope):`, `fix:`, or `scope - subject`.

### 2. C++ Conventions

| Item | Rule |
|---|---|
| Private members | Must have trailing underscore: `running_`, `ticker_client_` |
| Constants | `k` prefix + CamelCase: `kGaugeLiveness` |
| Method names | PascalCase: `Init()`, `Start()`, `GetSymbol()` |
| Namespace | All lowercase: `namespace api`, `namespace metrics` |
| `using namespace` | Forbidden in `.h` files |
| Header guards | Full path style: `#ifndef ORDER_HUB_SRC_API_FILE_H_` |

### 3. Python Conventions

| Item | Rule |
|---|---|
| Functions/methods | `snake_case` |
| Private members | Single underscore prefix: `_config`, `_ticker` |
| Type hints | Required on all public API functions |
| Logger | `logging.getLogger(__name__)` — not hardcoded name |
| `from __future__ import annotations` | Must be first import when using forward refs |
| `python3` / `pip3` | Always use `python3`, never bare `python` |

### 4. Thread Safety (C++ + Python)

For any class that touches shared state:
- C++: check that all mutations are under `std::mutex` or `std::recursive_mutex`
- Python: check for double-check locking pattern on lazy-initialized properties
- Both: class docstring must declare thread safety guarantees

### 5. Security Red Lines (incubator-specific)

```
- [ ] No hardcoded API keys, JWT secrets, passwords anywhere
- [ ] JWT secret loaded from --jwtSecretFile (not env var)
- [ ] Password transmitted only as hashed value (cert-client-rest pattern)
- [ ] Rate limiting applied to all cert-server-rest endpoints
- [ ] Log statements: grep for "password|token|secret|key" — must be 0 hits in new code
- [ ] All gRPC operations validate req.uid against requested resource
```

### 6. Financial / Order Logic

For any change touching order placement, execution, cancellation:
```
- [ ] No float arithmetic on quantities or prices (use decimal / integer ticks)
- [ ] Ghost Order prevention: timeout cleanup must not race with late callback
- [ ] Order state transitions are logged with user_id + timestamp
- [ ] Idempotency: duplicate order submission must be safely rejected
```

### 7. MR Checklist (Pre-Merge)

```
- [ ] MR title: TYPE: scope — subject (UPPERCASE, em dash)
- [ ] No planning docs / SPEC / reports in diff
- [ ] Copy-first commits split from adapt commits (if file is based on existing module)
- [ ] New module has CLAUDE.md only if it adds build/test commands not in root CLAUDE.md
- [ ] Local tests pass
- [ ] No hardcoded keys/creds
```

---

## Integration with Lead Agent

When Lead dispatches code review after Coder:

```
Lead → /code-review-expert: Review #{issue} changes.
[After report received]
Lead → Apply incubator overlay from skills/code-review.md
[If P0 or P1 found] → Return to Coder for fix
[If clean or P2/P3 only] → Proceed to QA
```
