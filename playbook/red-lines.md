<!-- version: 1.0 | framework: ai-dev-framework -->
# Red Lines — Non-Negotiable Safety Constraints

> This file is the single source of truth for hard safety constraints.
> Architect, Coder, and Auditor all reference this file instead of maintaining their own copies.
> Any violation must be flagged as CRITICAL and blocks PR creation.

---

## 1. Concurrency Red Lines

```
- NEVER use threading.Lock() in a reentrant call path — use RLock() instead
  (Same thread re-acquiring a Lock() causes a silent deadlock)
- All shared mutable state MUST be protected by a lock
- Double-check locking: assign the fully-constructed object LAST
  (Prevents other threads from seeing a partially constructed object)
- Callback registration MUST happen before the object is visible to other threads
- NEVER mutate shared collections in-place — use atomic replacement
```

## 2. Financial Precision Red Lines

```
- ALL floating-point accumulations MUST use round(..., 10) guard
  (300x 0.1 = 29.999... without guard — confirmed bug in order_tracker.py)
- Tick size calculations MUST use math.floor / math.ceil, NOT Python round()
  (Python round(200.5) = 200 due to banker's rounding — confirmed QA trap)
- NEVER compare floats with == — use tolerance or Decimal
- Order fill amounts MUST be validated against tick size before acceptance
```

## 3. Production Stability Red Lines

```
- Timeout paths MUST have cleanup logic — no orphan state after timeout
  (Ghost Order pattern: wait_for_submit times out → event removed →
   _on_submit fires late → order exists on exchange but NOT in memory)
- All _on_* callbacks MUST handle the "late arrival" case (after timeout cleanup)
- reconcile_from_server() MUST work after process restart
  (Cannot rely solely on in-memory maps that are empty after restart)
- std::future::get() MUST have a timeout — never block infinitely on non-response
```

## 4. Security Red Lines

```
- NEVER hardcode credentials, API keys, certificate paths, or secrets
- JWT secret MUST be loaded from file (--jwtSecretFile pattern), NOT from env var
- Token JTI MUST be unique per token — static/dummy JTI is a CRITICAL bug
- Rate limiting MUST be applied to all externally-facing API endpoints
- Log statements MUST NOT output: passwords, tokens, certificate private keys
- All user input MUST be validated at transport layer before reaching service layer
```

## 5. I/O Red Lines

```
Network:
- Every outbound network call MUST have an explicit timeout
- gRPC / HTTP stubs MUST have deadline context or timeout parameter
- Retry logic MUST have exponential backoff + maximum retry limit

File:
- NEVER hardcode absolute file paths — use config or env var
- File handles MUST be closed in finally block or context manager

Log:
- Log format: use lazy formatting logger.info("%s", var) NOT logger.info(f"{var}")
  (Avoids string build cost when log level is filtered out)
- No log line exceeds 2KB

Database:
- ALL queries MUST use parameterized inputs — no f-string SQL (SQL injection)
- Transactions MUST be committed or rolled back — no hanging uncommitted transactions
```

---

## Usage by Agent

| Agent | When to Reference |
|---|---|
| **Architect** | Step 2 (Threat Modeling) — use as checklist for CRITICAL risk identification |
| **Coder** | Step 4 (Self-Review) — check Safety section before handoff |
| **Auditor** | Step 3 (Independent Scan) — all 5 sections are mandatory audit checks |
