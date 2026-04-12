---
name: code-review
description: >-
  General-purpose code review: correctness, maintainability, API design, and testing.
  Use when asked to review or give PR feedback—not for "just implement it."
  Run with `security-review` for security-touching or pre-merge changes;
  use `security-review` alone when the user wants adversarial or security-only review.
---

# Code Review

## When this applies
- Asked to **review**, **critique**, or give **PR feedback**.
- Evaluating **quality, correctness, or maintainability** without rewriting the change.
- The user is preparing for merge and wants a sanity check before shipping.

This skill is not the default for "just implement this feature"—that is a task for `core-engineer` or a task-specific skill.

## Precedence
- **`core-engineer`** baseline applies throughout. This skill adds **review structure and focus** on top of it.
- **`security-review`** is the primary lens for adversarial work; this skill still covers correctness when both are loaded (see `security-review → Together with code-review`).
- Repository-level rules and user instructions override this skill.

## Review workflow

### 1. Orient
- Read the PR description and linked issues to understand **intent**: what problem does this solve? What was the previous approach?
- Identify the **core logic** (the actual change) vs **plumbing** (boilerplate, formatting, generated code).
- Map **what's in scope** vs adjacent code you might need to understand but not review.
- If the change has no description and no linked issues, ask for context before doing a detailed review—or do a brief review and note "this lacks a PR description; I've reviewed what I could infer from the diff."

### 2. Read the diff
- **Small diffs (<200 lines):** read top-to-bottom. Build a mental model. Trace the data flow from input to output.
- **Large diffs:** skim for high-signal patterns first (see table below), then deep-dive risky areas. Don't try to read every line linearly—a large diff rewards pattern recognition over linear reading.
- For both sizes: look for where **state lives and mutates**. Stateful changes are higher risk than stateless ones.

**High-signal patterns to skim for:**

| Pattern | Why it matters |
|---------|----------------|
| New public function / API | Check signature, docs, error handling, whether it should exist |
| Changed function signatures | All call sites updated? Breaking change? |
| New dependencies | Security-sensitive? Version conflicts? Maintenance burden? |
| Error handling changes | New error paths introduced? Silent failures? Swallowed exceptions? |
| Concurrency / async changes | Races, blocking calls, missing awaits |
| Database queries | Injection risk, missing pagination, N+1 patterns |
| Authentication / authorization | Authn without authz? New endpoints reachable? |
| Serialization / deserialization | Untrusted input? Custom types? Custom deserializers? |
| Logging changes | PII or secrets logged? Context missing? |
| Config / env changes | New secrets? Unsafe defaults? |
| Migrations | Backward/forward compat? Rollback tested? Large tables handled? |

As you read, continuously ask: does the change do **more** or **less** than described? Are there TODOs or hacks left in?

### 3. Write findings
- Group security-primary issues under **`security-review`** when both skills apply.
- Produce **one combined review** with findings in the right skill's framing.
- State what you **could not verify** (tests not run, runtime behavior unknown, external dependencies).

## What to check

### Correctness
- **Logic bugs**: off-by-one errors, wrong operators, inverted conditions, missing early returns.
- **Concurrency**: races, deadlocks, non-idempotent operations applied more than once.
- **Null/empty cases**: what happens with `null`, `[]`, `{}`, `""`, `0`, negative numbers? Are empty inputs treated as errors or accepted silently?
- **Time handling**: timezones, DST, epoch overflow, truncation, assumption of monotonic time.
- **Edge cases**: boundary values, first/last items, empty collections, overflow.

### Error handling
- Are errors **handled**, not swallowed? (no empty catch, no silent try/catch)
- Are error paths **tested**? (what happens when the DB is down, the file is missing, the API returns 500)
- Are errors **propagated** or **logged at the boundary** where they occur—not in every intermediate layer?
- Is the error **type** appropriate? (Result vs exception vs panic—depends on the language)
- Are there **silent failures**? (operations that return without indicating something went wrong)
- Are there **missing fallbacks**? (what happens when an optional dependency, cache, or secondary store is unavailable)

### API design
- Are method signatures **clean and minimal**? (no boolean parameters that mean two different things)
- Is responsibility **clearly placed**? (not a god function doing too many things)
- Do public APIs have **stable, documented contracts**? (preconditions, postconditions, error conditions documented)
- Is state mutated **explicitly** or passed through hidden globals?
- Is the API **composable**? (can callers use it without knowing internal details)

### Maintainability
- **Naming**: descriptive, consistent, not misleading. Does the name match what the code actually does?
- **Duplication**: repeated logic that should be extracted? (if you copy-paste more than twice, it should be a function)
- **Coupling**: does this change introduce unwanted dependencies between modules?
- **Comments**: explain **why**, not **what**. Comments that restate the code are noise. Comments that explain non-obvious decisions are gold.

### Testing
- Are **happy paths** covered?
- Are **edge cases and error paths** tested?
- Are **negative cases** present? (invalid input rejected, permissions enforced)
- Are tests **asserting behavior**, not implementation? (tests should not break on refactors that preserve behavior)
- Note untestable code: if logic cannot be exercised in tests, say so and flag it.

### Test quality
- Is **setup / teardown** clear and not duplicated across tests?
- Are tests **isolated** from each other? (no shared mutable state between tests)
- Are test names **descriptive** of the scenario and expected outcome? ("test_user_created" is vague; "test_duplicate_email_returns_409" is precise)
- Are **assertions** precise? (not too broad—accepting wrong behavior—or too narrow—breaking on valid changes)
- Are **mocks** testing the right thing? (mocking too much masks integration failures)

### Performance
- **Obvious O(n²) or worse** in hot paths (nested loops over the same collection)
- **Missing pagination or streaming** where data can grow unboundedly
- **Unbounded memory growth** (collecting all results in memory instead of streaming)
- Not an exhaustive performance audit—flag only the obvious cases.

### Observability
- Are errors logged with **enough context to reproduce the issue**? The test: if you saw this log line in production, could you reproduce the bug? If not, context is missing. Minimum: what failed, what input caused it, who was affected (if applicable).
- Are key operations **instrumented**? (entry/exit spans, duration, outcome)
- Are **metrics and alerts** defined for critical operations? (Are key success/failure rates visible? Do alerts fire when things break?)
- Is **distributed tracing** in place for cross-service calls? (Are spans propagated? Are trace IDs logged?)
- Is sensitive data (PII, secrets) flagged in logs or client-facing errors? Deep leakage analysis belongs in `security-review`.

## Finding severity

| Level | Meaning |
|-------|---------|
| **blocker** | Wrong behavior, data corruption, security risk—do not merge |
| **major** | Likely bug, significant debt, or design flaw |
| **minor** | Cleanup, clarity, or local convention violations |
| **nit** | Style preference that aids readability; skip if the project doesn't care about this style |

**Info**: non-blocking observations for the author's awareness (e.g., "the error handling is clean; consider adding edge case tests here"). Use sparingly. Info findings are not blocking.

**When to skip nits**: if the project's linter or style guide doesn't enforce something, don't raise it. Conversely, if the project has strong conventions (even if unenforced), flag violations as minor rather than nit.

**When to skip minor**: if fixing the issue would expand scope beyond the PR, note it and move on.

## Finding template

For each finding:
1. **What** — specific line, file, or behavior that is a problem
2. **Why** — consequence if unfixed (who is affected, what breaks)
3. **How** — concrete fix or direction (not a full rewrite)

```
[blocker] `authenticate()` returns null on invalid credentials in `src/session.rs:45`—
caller never checks the return value, so unauthenticated users proceed as authenticated.
Fix: return Result<User, AuthError> or throw an exception; callers expect non-null on success.
```

**Bad findings to avoid:**
- "This is bad." — no evidence, no location
- "You should rewrite this." — unsolicited rewrite, not a finding
- "Consider using a different approach." — vague, no specific direction
- "This might cause issues." — ungrounded speculation, not a finding

## Scope discipline
- Review **the requested diff**; do not expand into unrelated modules unless the user asks or coupling forces it.
- Distinguish **must-fix** from **optional**; avoid redesign pitches that would be a separate PR.
- Acknowledge **scope limitations** if you couldn't fully verify something (external system, tests not run, runtime behavior unknown).

## Uncertainty
- If you cannot verify behavior, **say so explicitly**.
- Label unverified points as **assumption** or **question for author**—don't present them as findings.
- If you are unsure whether something is a problem, note it as a **concern** with reasoning rather than asserting it as a finding.

## Before finishing
- Blockers and majors summarized in 2-3 lines if the detailed list is long
- Anything not validated (tests not run, runtime behavior unknown, external dependencies) called out
- Any findings that are speculative or unverified labeled as such
