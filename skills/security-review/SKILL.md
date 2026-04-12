---
name: security-review
description: >-
  Adversarial code review: trust boundaries, authorization, injection, deserialization,
  abuse paths, and hidden failure modes (SSRF, JWT/token, GraphQL). Load for hostile
  review, security audit, risk pass, or when changes touch auth, tenancy, sessions,
  payments, PII, secrets, crypto, public APIs, webhooks, uploads, or untrusted
  deserialization. Use with `code-review` for full pre-merge review.
---

# Security Review

## When this applies
- User requests adversarial, hostile, red-team, or security review.
- Change touches authn/authz, tenancy, sessions, payments, PII, secrets, crypto, public HTTP/RPC, webhooks, uploads, untrusted deserialization, or new externally reachable surface.
- Pre-merge risk check on high-privilege or security-sensitive code.

For general correctness without a security lens, use `code-review` instead.

## Mindset

Treat the change as **guilty until evidence supports safety**. Assume an attacker will probe every edge and corner. Actively try to break invariants, bypass checks, and misuse APIs.

**Core questions:**
1. What can an attacker **control**? (input, headers, timing, environment, network)
2. What **should** they not be able to do?
3. What **could** they do if the code is wrong or the assumptions are violated?

**Assumptions to challenge:**
- "This ID is always internal"
- "Only admins call this"
- "The caller validated input"
- "The database is already sanitized"
- "This only runs in trusted environments"

## Precedence
- Repository-level rules and user instructions override this skill.
- `core-engineer` baseline applies throughout.
- `rust-core` / `rust-guidelines` apply for Rust-specific concerns.

## Together with `code-review`

**Default both skills** for full or pre-merge review. Use `security-review` alone only when the user explicitly wants security-only review and not general correctness, maintainability, or API design.

When both are loaded:
- **`security-review` owns** security-shaped findings: class, attack path, preconditions, fix.
- **`code-review` owns** general correctness, API shape, maintainability, and non-security tests.
- **Do not duplicate**—if `code-review` already flagged an obvious secret or log leak, supersede with one richer security finding rather than two bullets.

## Finding format

Label each finding with its severity (blocker/major/minor/nit). For blocker and major, include all of:
1. **Severity and class** — e.g., `[blocker] IDOR`, `[major] SSRF`, `[major] JWT algorithm confusion`
2. **Location**: file and line(s)
3. **Attack path**: how an attacker reaches this
4. **Preconditions**: what must be true (e.g., "authenticated user", "network access")
5. **Fix**: concrete direction (not a full rewrite)

```
[blocker] IDOR: `GET /api/documents/{id}` in `handlers/doc.rs:34` returns any
document if the user guesses the ID—no ownership check. Attacker with valid login
can access any document by iterating IDs. Precondition: authenticated user.
Fix: add WHERE owner_id = $current_user_id.
```

For **minor** and **nit**, a shorter form is acceptable:
`[nit] Hardcoded API key in `handlers/doc.rs:12`—use an environment variable.`

For **info**: a note label, not a severity—use for observations worth noting that don't fit severity levels:
`[info] The auth middleware is clean; consider adding rate limiting to the public signup endpoint.`

## Trust boundaries

### Classify data sources

| Source | Classification |
|--------|----------------|
| User input (body, params, URL) | Untrusted |
| HTTP headers (incl. cookies) | Untrusted |
| JWT/OAuth claims | Partially trusted (always verify the signature) |
| Database reads | Partially trusted |
| Environment variables | Partially trusted (can be injected in some environments) |
| Config files | Partially trusted |
| Webhooks | Untrusted (attacker can send them) |
| Job queue messages | Untrusted |
| File uploads | Untrusted |
| Internal function calls | Usually trusted, but validate callers |

### Authorization checklist

For every mutating or sensitive read path, answer:
- **Who** may invoke it? (role, tenant, authentication mechanism)
- **On whose behalf**? (does the action affect only the caller's own resources?)
- **What scope** is enforced? (which resources, what operations)

Watch for:
- **IDOR**: accessing other users' resources by guessing or manipulating IDs
- **Missing tenant isolation**: cross-tenant data leakage
- **Authn without authz**: logged in does not mean permitted
- **Client-controlled policy**: roles, flags, `isAdmin` sent from the client

## Attack surface

### Injection

| Type | What to look for |
|------|-----------------|
| SQL | User input in query strings, interpolated strings passed to a DB driver |
| Command / OS | `exec`, `system`, `shell`, user input in any command |
| Template/HTML | Unescaped output in HTML, JavaScript, or template strings |
| Path traversal | `../` or URL-encoded paths in file operations |
| Code execution | `eval`, `Function()`, `exec`, any dynamic code evaluation |
| Deserialization | Untrusted pickle, YAML, JSON with custom types, `eval` on deserialized data |
| LDAP | User input in LDAP queries (if applicable) |

### SSRF (Server-Side Request Forgery)

User-supplied URLs fetched by the server. The server can be tricked into accessing internal resources.

**Check:**
- Is the URL validated against an allowlist? (scheme, host, port—not just a regex on the hostname)
- Are redirects followed blindly?
- Can dangerous schemes be accessed? (`file://`, `gopher://`, `dict://`, `sftp://`) or internal hosts? (`http://localhost`, `http://127.0.0.1`, `http://169.254.169.254` — the AWS/cloud metadata endpoint containing credentials and instance info, and GCP/Azure equivalents)

**Attack targets:** cloud metadata services (169.254.169.254 on AWS, 100.100.100.200 on GCP/Azure), internal databases, admin panels, file systems.

### JWT / Token security

- **Algorithm confusion**: `none` algorithm accepted, or algorithm switching (RS256 key used to verify HS256-signed tokens)
- **Weak secrets**: short or guessable signing keys; hardcoded secrets
- **Missing validation**: signature not checked, expiry (`exp`) not checked, issuer (`iss`) not validated
- **Sensitive claims in plaintext**: user roles or IDs trusted directly from unvalidated claims

### GraphQL-specific

- **Introspection abuse**: introspection enabled in production (disclose schema to attackers)
- **Batch query DoS**: many queries in one request; test depth and complexity limits
- **N+1 amplification**: inefficient nested queries used to amplify DoS
- **Field exposure**: sensitive fields returned without authorization checks at the field level

### Input validation

Validate, canonicalize, and bound:
- **Size**: string length, array length, file size
- **Depth**: nesting level in JSON, YAML, XML
- **Cardinality**: number of items in a list
- **Type**: what type is expected and what is received
- **Encoding**: UTF-8 normalization, double-encoding, null bytes, BOM

Watch for **parser differentials**: two parsers of "the same" format disagreeing (e.g., one parser accepts a null byte, another doesn't).

### Sensitive data

- No **secrets** in code (API keys, tokens, passwords, private keys)
- No **PII or secrets** in logs, metrics, traces, or error messages
- No **debug error details** returned to clients (stack traces, file paths, internal state)
- No **tokens or IDs in URLs** that get logged by proxies or CDN (use POST bodies or headers)

## Concurrency and time

### Race conditions

| Pattern | What it looks like |
|---------|-------------------|
| TOCTOU | Check permission or resource existence, then use the resource |
| Lost updates | Read-modify-write without locking or optimistic concurrency control |
| Double application | Non-idempotent operation triggered twice (retry, double-click) |
| Double spending | Monetary operations without idempotency keys |

### Distributed systems

- **Clock reliance**: expiry, TTL, and ordering decisions based on system time (can be manipulated)
- **Cache coherence**: stale data used for security decisions
- **Non-idempotent retries**: replay of a request causes double effect (payment, email, state change)
- **Circuit breakers**: when a downstream service fails repeatedly, does the circuit open? What is the default behavior when open—fail open (allow traffic through) or fail closed (block traffic)? Fail-open is the riskier default.

## Resource abuse

### DoS vectors

| Vector | Trigger |
|--------|---------|
| CPU exhaustion | ReDoS (catastrophic backtracking in regex), unbounded computation |
| Memory exhaustion | Large inputs, deeply nested structures, unbounded collections |
| Disk exhaustion | Large uploads, unbounded log growth, temp files not cleaned up |
| Connection exhaustion | Holding connections, missing timeouts |
| Amplification | Small request → huge computation or large response |

### Rate limiting

- Is there rate limiting on expensive operations?
- Are limits per-user, per-IP, or global?
- Can limits be bypassed via multiple accounts, proxies, or rotating IPs?
- Are the limits documented and the error messages clear?

## Dependencies and supply chain

Flag new or upgraded dependencies with security-sensitive roles: auth libraries, parsers for untrusted input, crypto, sandboxing, native extensions.

**When to flag a dependency:**
- New transitive dependency introduced by an upgrade (read the upgrade's diff)
- Native extensions or `build.rs` scripts (arbitrary code runs at build time)
- Known CVEs in the current version (run `cargo audit` or equivalent)
- Postinstall / postbuild scripts (arbitrary code at install time)
- Dependencies requesting unusual permissions (network access, filesystem write at build time)

**Avoid** flagging known-good, widely-used crates without evidence of a problem.

**License concerns** are a separate concern—note them as **info** if relevant, but do not conflate with security.

## Quick checklist

| Category | Check |
|----------|-------|
| Untrusted input | Used directly in queries, commands, execution, or file paths? |
| Authn / authz | Authenticated but unauthorized on sensitive paths? |
| New surface | New endpoint, flag, IPC, file format reachable by an attacker? |
| Defaults | Default-deny or default-allow—is default-allow correct here? |
| Allowlists | Allowlists used for formats, types, schemes, origins—not denylists? |
| Error paths | Leak data, skip cleanup, grant partial access on failure? |
| SSRF | User-supplied URLs fetched? Internal services reachable? |
| JWT / tokens | Algorithm validated? Expiry checked? Signature verified? |
| GraphQL | Introspection disabled? Depth/batch limits set? |
| Tests | Negative cases, permission tests, boundary tests, concurrency cases? |
| Secrets | Hardcoded in code, logged, or returned to clients? |

## Scope discipline
Limit findings to security-relevant issues. Stay on the security-relevant diff; do not expand scope without cause.

## Uncertainty
If you cannot verify an attack works (no test environment, external system), say so explicitly. Label as **hypothesis** or **needs testing** rather than claiming exploitation. If something looks suspicious but you cannot prove it, note it as **concern** with reasoning.

## Before finishing
- Blockers and majors summarized in 2-3 lines
- Residual risk noted (threat model dependent, untested runtime behavior, etc.)
- Anything not verified (tests not run, runtime unknown) called out
