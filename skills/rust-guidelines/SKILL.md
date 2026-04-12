---
name: rust-guidelines
description: >-
  Applies Microsoft's Pragmatic Rust AI Guidelines to Rust reviews and
  implementation. Load alongside `rust-core` for detailed reviews, public API
  design, or strict compliance. Guidelines live in `guidelines.txt`, synced
  from Microsoft's repository via `update-guidelines.sh`.
---

# Rust Guidelines

## Precedence
- `rust-core` is the workflow baseline; this skill adds detailed guideline compliance on top.
- `core-engineer` applies throughout. Repository-level rules and user instructions override this skill.

## When this applies
- Detailed Rust review, public API design, or when the user requests guideline compliance.
- Designing or changing public APIs, library interfaces, or error types.
- Producing code that will be used by other teams or published.

For routine Rust edits, `rust-core` alone may suffice.

## Source

Guidelines: `guidelines.txt` in this directory, synced from:
`https://microsoft.github.io/rust-guidelines/agents/all.txt`

Sync: `bash update-guidelines.sh` (run from this directory). The file is large (~2400 lines)—**target your reads**, do not read it in full.

`rust-core` links here for the full document; keep paths consistent if relocating skills.

## When to use rust-guidelines vs rust-core

| Situation | Skill |
|-----------|-------|
| Routine edits, local changes | `rust-core` only |
| Detailed code review | Both |
| Public API design | Both (guidelines takes precedence) |
| Error taxonomy design | Both |
| Strict compliance requested | Both |
| New crate / library | Both |
| App-level code only | `rust-core` (guidelines are library-focused) |

## Document structure

Top-level sections (verify via `grep` when syncing): AI Guidelines, Application Guidelines, Documentation, FFI Guidelines, Library Guidelines, Performance Guidelines, Safety Guidelines, Universal Guidelines, Libraries / Building, Libraries / Interoperability, Libraries / Resilience, Libraries / UX. Search for `^# ` headings in `guidelines.txt` after each sync to get the current list.

## Task-to-section mapping

| Task | Relevant sections |
|------|------------------|
| Reviewing library code | Library Guidelines, Documentation, Libraries / UX |
| Reviewing public API | Library Guidelines, Libraries / UX |
| Reviewing error handling | Libraries / Resilience, Application Guidelines |
| Reviewing unsafe code | Safety Guidelines |
| Reviewing FFI / WASM | FFI Guidelines, Libraries / Interoperability |
| Designing public API | Library Guidelines, Libraries / UX, Documentation |
| Writing docs | Documentation, AI Guidelines |
| Performance-sensitive code | Performance Guidelines |
| Implementing errors (library) | Libraries / Resilience, Libraries / UX |
| Implementing errors (app) | Application Guidelines |

## Workflow

### For reviews
1. **Identify the scope**—library, app, or FFI?
2. **Target relevant sections** via the mapping above.
3. **Read selectively**—`grep` for section headings or guideline IDs (e.g., `M-CANONICAL`).
4. **Check compliance**—evaluate whether the code follows each relevant guideline.
5. **Report findings** by guideline ID (e.g., `[M-CANONICAL-DOCS]`) with explanation of the gap.

### For implementation
1. **Identify affected sections** from the mapping.
2. **Read relevant sections** before writing—not all sections apply.
3. **Design to the guidelines** as you implement, not after.
4. **Verify**: `cargo fmt`, `cargo clippy`, `cargo test`; check docs and examples.

## Finding format for reviews

Include: guideline ID, what violates it (file and location), why it matters (consequence), what to do (concrete fix or reference to the guideline).

```
[M-CANONICAL-DOCS] `lib.rs:45` — `pub fn fetch_config` has no doc comment.
Follow the canonical doc template: summary, # Errors, # Panics, # Safety where applicable.
See: Documentation → Documentation Has Canonical Sections.
```

For guideline violations, include a reference to the guideline ID and section. This makes it easy for the author to look up the full rule.

## Ordering with rust-core

- Project conventions override both skills when they conflict.
- When this skill is loaded for detailed review or compliance: `guidelines.txt` is authoritative for topics it covers.
- When only `rust-core` is loaded: use it for defaults; do not assume full guideline compliance.
- If `guidelines.txt` is silent on a point, follow `rust-core`.
- If both disagree and safety or soundness is at stake, prefer the stricter rule; otherwise note the tension to the user.
- If `rust-guidelines` contradicts itself, apply the more conservative interpretation and flag it.

## Syncing

Run `bash update-guidelines.sh`. After syncing, update this skill if the table of contents has changed:

| Change | Action |
|---------|--------|
| New section added | Add to the task-to-section mapping |
| Section removed | Remove from both the mapping and the document structure reference |
| Section renamed | Update mapping references |
| Major content restructure | Rewrite affected workflow or mapping sections |
| Small edits within sections | No update needed |

As a rule: if the table of contents changes or finding conventions change, update this skill. If only content within a section changes, no update needed.

## Before finishing
- Reviews: findings reported by guideline ID
- Implementation: confirmed alignment with relevant sections
- Anything not verified (tests not run, runtime behavior unknown) called out
