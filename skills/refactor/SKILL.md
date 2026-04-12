---
name: refactor
description: >-
  Improve internal structure and readability without changing observable behavior.
  Use when the user asks to refactor, simplify, deduplicate, or reorganize—not
  for new features or bug fixes unless explicitly combined. Verify with existing
  tests or stated behavior.
---

# Refactor

## When this applies
- User asks to refactor, clean up, simplify, deduplicate, or restructure without changing what the system does externally.

## Precedence
- `core-engineer` baseline applies. Repository-level rules and user instructions override this skill.
- Use `rust-core` (or other stack skills) for idiomatic patterns in that language. This skill stays behavior-neutral.

## Principles

**Behavior is sacred**—preserve observable behavior. Never smuggle feature changes or bug fixes into a refactor. If the user explicitly asked for both, call it out.

**Prefer refactoring code you must change anyway** over preemptive cleanup. "I'm already in this file fixing a bug" is a good time to tidy nearby mess in passing. Don't seek out refactors—do them when you're already in the code.

**Avoid refactoring toward a future you don't know is coming.** Refactor for today's proven needs, not anticipated ones. "This might be useful someday" is not a refactor reason.

**Small, reviewable steps beat wholesale rewrites.** Each step is easier to verify and easier to roll back.

## Preserved behavior

"Observable behavior" means:
- Same inputs → same outputs for public APIs
- Same error types and messages callers depend on
- Same side effects (writes, network calls, logs) in the same order
- Same performance characteristics (unless the user asked for optimization)

Does **not** include:
- Internal naming and structure
- Private API shape
- Error handling paths that only matter to developers
- Comments and documentation (unless they encode a contract)

When in doubt, ask the user what must not change.

## Should I refactor this?

Use these questions and the risk table together—they answer the same question from different angles.

| Gate question | If yes | If no |
|----------|--------|-------|
| Is this code causing problems now (bugs, slow, hard to change)? | Likely worth it | Defer |
| Is this supporting active development? | Higher priority | Can wait |
| Is the code likely to change in the near term? | Refactoring enables that | Not worth the risk |
| Does the refactor touch many call sites? | Higher risk—consider incremental | Lower risk |

**Risk by type:**

| Type | Risk | Notes |
|------|------|-------|
| Rename locals, reorder functions | Low | No call sites affected |
| Extract pure functions | Low to medium | Abstraction must fit all uses |
| Rename public methods | Medium | Must update all call sites |
| Remove obvious accidental complexity | Low | |
| Extract shared logic | Medium | |
| Improve module boundaries | Medium to high | Ripple effects; test thoroughly |
| Split a system or extract a library | High | Needs incremental delivery |
| "Clean up" for future needs | High | Don't do this |

**Mechanical moves** (renaming locals, reordering, extracting pure functions) are low-risk and need no formal plan. **Structural changes** need more care and often incremental delivery.

## Workflow

### 1. Understand
- Read callers, tests, and docs that encode intended behavior.
- Identify invariants the code must keep (e.g., "this function never returns null").
- Map the blast radius: what depends on this code? What depends on those things?

### 2. Plan (proportionate to complexity)

**Small refactor** (rename, extract function, inline): skip formal planning.

**Medium refactor** (restructure module, split class): one-line summary + ordered step list. Something like: "Extract the validation logic into a separate module, update callers."

**Large refactor** (split a system, extract a library): write the plan explicitly:
1. Add new structure (dead code coexisting with old)
2. Wire up one call site to new structure
3. Verify, repeat for remaining call sites
4. Remove old structure
5. Rollback plan: revert steps 1-4

### 3. Change

Make changes in this order:
1. **Mechanical moves first** (low-risk): rename locals, reorder functions within a file, extract pure functions, rename private methods.
2. **Structural changes** (need more care): move code between modules, change function signatures, extract shared logic.

**One change at a time**: make one structural change, verify it (run tests, check the diff), then move to the next. Do not batch multiple structural changes together—each step should be independently verifiable.

**Avoid wholesale rewrites** unless scope demands it. Small, reviewable steps catch errors early and make rollback easier.

### 4. Verify
- Run existing tests first. If they pass, you're in good shape.
- If tests are absent or thin: build the project, spot-check key call sites manually.
- Compare the git diff: confirm only the intended structural changes landed, not accidental behavior changes, stray formatting, or unrelated edits.
- State residual risk explicitly if verification is weak: "this refactor is based on reasoning; the test coverage is thin."

## Incremental delivery

For large refactors that can't land in one PR:
- Use a feature flag or migration step to land intermediate states safely.
- Dual-write / dual-read: run old and new in parallel, compare outputs, switch over when stable.
- Flag the risk to the user: "this refactor needs 2 PRs to land safely."

## Scope discipline

- Do not rename public APIs without explicit approval. If approved, provide a deprecation path.
- Do not change serialization formats without explicit approval.
- Do not "cleanup" unrelated files touched only incidentally unless the user asked for a broader pass.
- Stop when the ask is done—don't refactor adjacent code "while you're here" unless it's causing the task.

## Spotting coupling

**Signs of coupling worth reducing:**
- **Import cycles**: A imports B imports C imports A
- **Shotgun surgery**: changing one feature requires editing many files across the codebase
- **Feature envy**: a function in class A is more interested in class B's data than its own
- **Shared mutable state**: global or passed through many layers without clear ownership

**Signs of harmless similarity (don't refactor):**
- Two functions happen to do similar things for different reasons
- Patterns that look duplicated but serve different domains

## Refactoring tests

Tests also rot. Consider cleaning them up when:
- The refactored code makes the test setup obsolete or misleading
- Test names no longer match what the test actually asserts
- Significant duplication in test setup is trivial to extract

Do not expand scope for test cleanup unless it directly enables or clarifies the refactor. If tests are in bad shape but not part of the refactor, note it rather than silently fixing it.

## Flagging adjacent issues

A refactor often surfaces problems in neighboring code. Use this rule:
- **Note briefly** (one line): "X is related and may need Y—happy to address separately."
- **Fix silently**: only if it's trivial and directly caused by the refactor (e.g., a broken import).
- **Leave alone**: a real problem but unrelated to the refactor; fixing it would expand scope.

When in doubt, note it and let the user decide.

## Before finishing
- What changed structurally and how behavior was verified (or why it couldn't be)
- Real follow-ups noted (e.g., "dead code left in module X pending separate migration")
- Adjacent issues noted per the flagging rule above
