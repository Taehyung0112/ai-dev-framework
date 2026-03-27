<!-- version: 1.0 | framework: ai-dev-framework -->
# Coder Self-Review Checklist

> Single source of truth for pre-handoff self-review.
> Referenced by both `agents/coder.md` (Step 4) and `contracts/IMPLEMENTATION_LOG.md`.
> Coder MUST verify ALL items before declaring done.

---

## Code Quality

```
- [ ] Functions < 50 lines
- [ ] Files < 800 lines
- [ ] No deep nesting (> 4 levels)
- [ ] No unused imports / variables / functions (dead code)
- [ ] No defensive over-wrapping of already-validated params
```

## Language Compliance — Python (if applicable)

```
- [ ] Module docstring present
- [ ] from __future__ import annotations at top (before other imports)
- [ ] Type hints on all public methods
- [ ] logger = logging.getLogger(__name__)
- [ ] threading.RLock() used (not Lock) for reentrant paths  ← see red-lines.md §1
- [ ] Double-check locking: assign object LAST in lazy init   ← see red-lines.md §1
```

## Language Compliance — TypeScript (if applicable)

```
- [ ] No `any` type used
- [ ] All async functions have explicit return type annotation
- [ ] createLogger() used (not console.log)
- [ ] Config validated at startup (fail fast)
```

## Language Compliance — C++ (if applicable)

```
- [ ] Header guard in #ifndef FULL_PATH_H_ format
- [ ] Private members use trailing_underscore_
- [ ] Constants use kPrefixCamelCase
- [ ] using namespace not in header files
```

## Safety — All Languages (always check)

```
- [ ] No hardcoded keys, passwords, or absolute file paths  ← red-lines.md §4
- [ ] No financial math without round(..., 10) precision guard  ← red-lines.md §2
- [ ] No threading.Lock() in reentrant callback paths  ← red-lines.md §1
- [ ] Timeout logic has cleanup (no Ghost Order risk)  ← red-lines.md §3
- [ ] Public API has docstring / type annotations
- [ ] Log statements do not output passwords, tokens, or private keys  ← red-lines.md §4
```
