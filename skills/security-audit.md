# Skill: Security Audit & Threat Modeling

> Slash command: `/security-audit`
> Invoked by: Auditor Agent (L3 gate) or Developer before any auth/payment/data-write MR.

---

## When to Invoke

**Mandatory (Auditor-enforced) for:**
- Any change to auth, JWT, session, or token handling
- Any change to order placement, execution, or financial calculation
- Any new external-facing API endpoint
- Any change to CI/CD pipeline that modifies secret access

**Recommended for:**
- New gRPC service or proto definition
- Any code handling user-supplied input
- Database schema changes on financial tables

---

## Phase 1: STRIDE Threat Modeling

Apply STRIDE per component/data-flow boundary:

| Threat | Question | incubator Example |
|---|---|---|
| **S**poofing | Can attacker impersonate a user/service? | Forged JWT, fake client ID in gRPC metadata |
| **T**ampering | Can data be modified in transit or at rest? | Order quantity modified between gateway and hub |
| **R**epudiation | Can actor deny an action? | Missing audit log on order cancellation |
| **I**nformation Disclosure | Can sensitive data leak? | Stack trace in gRPC error response |
| **D**enial of Service | Can service be made unavailable? | No rate limit on order submission endpoint |
| **E**levation of Privilege | Can low-privilege actor gain higher access? | Missing user ID validation in order hub decorator |

### Data Flow to Model

```
Client → [HTTPS] → cert-server-rest → [JWT] → order-gateway → [gRPC] → order-hub → [FIX] → Exchange
                                                                      ↓
                                                                   ticker (gRPC stream)
```

For each `→` crossing: apply all 6 STRIDE questions.

---

## Phase 2: OWASP Top 10 Checklist (2021)

```
A01 — Broken Access Control
  - [ ] User ID from JWT/session, NOT from request body or URL param
  - [ ] Authorization checked on every endpoint (not just at login)
  - [ ] No path traversal possible in file operations

A02 — Cryptographic Failures
  - [ ] No sensitive data (passwords, keys, PII) in logs or error messages
  - [ ] TLS enforced on all external connections
  - [ ] JWT secret from --jwtSecretFile, never env var, never hardcoded
  - [ ] Passwords hashed (not stored plain or reversibly)

A03 — Injection
  - [ ] No string concatenation in SQL queries (parameterized only)
  - [ ] No shell command construction from user input
  - [ ] gRPC proto field types validated — no raw string to shell

A04 — Insecure Design
  - [ ] Business logic limits enforced server-side (max order size, rate limits)
  - [ ] Financial calculations use integer/fixed-point arithmetic (not float)
  - [ ] Order state machine has no impossible transitions

A05 — Security Misconfiguration
  - [ ] No debug endpoints in production build
  - [ ] CI/CD variables marked Protected + Masked in GitLab
  - [ ] Docker images pinned to digest, not mutable tag

A07 — Authentication Failures
  - [ ] JWT expiry enforced (short-lived access + refresh token rotation)
  - [ ] Brute-force protection on login endpoints

A09 — Logging & Monitoring
  - [ ] All auth events logged: login, logout, refresh, failure
  - [ ] All order state transitions logged with user_id + timestamp
  - [ ] Logs contain ZERO passwords, tokens, private keys
  - [ ] Alerting configured for repeated auth failures
```

---

## Phase 3: incubator Red Lines (Hard Blockers)

Any violation = **P0, blocks merge**:

```
- [ ] No hardcoded API keys, secrets, or passwords anywhere in source
- [ ] JWT secret from --jwtSecretFile only
- [ ] Password field transmitted only as hashed value (cert-client pattern)
- [ ] Rate limiting applied to all cert-server-rest endpoints
- [ ] Grep new code for: password|token|secret|apikey — must be 0 matches in log statements
- [ ] All gRPC handlers validate authenticated user's context UID against requested resource
- [ ] TruffleHog CI job passes (no secrets in diff)
```

---

## Phase 4: Race Condition Audit (incubator-specific)

Critical for order processing code:

```
- [ ] OrderTracker: all mutations under _lock
- [ ] Lazy-init properties: double-check locking pattern (check → lock → re-check → assign)
- [ ] Callback registration: callbacks registered BEFORE connection starts
- [ ] Timeout + late callback: cleanup path does not race with in-flight response
- [ ] Ghost Order prevention: audit cleanup logic for TOCTOU on order state
```

---

## Output Format

```markdown
## Security Audit — #{issue}

**Auditor**: {date}
**Scope**: {files reviewed}
**STRIDE threats found**: {N}

### P0 — Critical (BLOCKS MERGE)
- [THREAT] {description} — {file:line} — required mitigation

### P1 — High (fix before merge)
- [OWASP A{NN}] {description} — {mitigation}

### P2 — Medium (follow-up ticket)
- {description} — create #{new_issue}

### P3 — Low / Info
- {observation}

### Verdict
{APPROVED | BLOCKED — reason}
```

---

## Escalation

| Finding | Action |
|---|---|
| Secret exposed in git history | Rotate immediately + BFG cleanup |
| Active exploitation suspected | Take service offline + notify all hands |
| Data breach suspected | Preserve forensic state + notify lead |
| CVE in dependency | File Chore ticket, schedule patch sprint |
