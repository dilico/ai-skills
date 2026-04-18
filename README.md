# AI Skills

This repository contains a collection of skills for AI coding agents. Each skill is a `SKILL.md` with YAML frontmatter (`name`, `description`) and structured guidance for a specific engineering task.

These skills are designed to be loaded by an AI agent working in a codebase—either automatically by the agent or on request by the user.

## Repository-level rules

If the repository being worked on has **`AGENTS.md`**, **`RULES.md`**, a `rules/` directory, or other checked-in team standards, those take precedence over these skills. Individual skills repeat this where precedence matters—**project conventions always win.**

## Skill stacking

**`core-engineer`** is the always-on baseline. Load additional skills on top of it based on the task:

| Task | Skills to load |
|------|---------------|
| General implementation or debugging | `core-engineer` (baseline only) |
| Code review (general) | `core-engineer` + `code-review` |
| Code review (security-sensitive or adversarial) | `core-engineer` + `code-review` + `security-review` |
| Security review only | `core-engineer` + `security-review` |
| Refactor | `core-engineer` + `refactor` |
| Explanation or teaching | `core-engineer` + `explainer` |
| Commit message generation | `core-engineer` + `commit-helper` |
| Rust implementation | `core-engineer` + `rust-core` |
| Rust detailed review or public API design | `core-engineer` + `rust-core` + `rust-guidelines` |

More specific skills narrow the baseline—they do not replace project rules or `core-engineer`.

## Layout

```
ai-skills/
├── README.md
├── skills/
│   ├── code-review/SKILL.md
│   ├── commit-helper/SKILL.md
│   ├── core-engineer/SKILL.md
│   ├── explainer/SKILL.md
│   ├── refactor/SKILL.md
│   ├── rust-core/SKILL.md
│   ├── rust-guidelines/
│   │   ├── SKILL.md
│   │   ├── guidelines.txt       # synced from Microsoft
│   │   └── update-guidelines.sh # pull latest from Microsoft
│   └── security-review/SKILL.md
```

**Rust guidelines** are synced from Microsoft's repository. Run `./update-guidelines.sh` from the `rust-guidelines/` directory to refresh. After syncing, check for new, removed, or renamed sections and update `SKILL.md` accordingly.

## Skills

### commit-helper

Generate commit messages from git diffs following conventional commits. Use when asked to create, improve, or validate commit messages—provides format guidelines, type validation, and output recommendations.

### core-engineer

Baseline engineering habits for implementation, debugging, and technical judgment: minimal complete change, evidence-based reasoning, explicit uncertainty, verification when practical, and project conventions. Always load this skill; defer to narrower skills for specific domains.

### code-review

General-purpose review: correctness, maintainability, API design, and testing. Use for PR/diff feedback—not for "just implement it." Run **with `security-review`** for full pre-merge review or any security-touching change; use **`security-review` alone** when the user wants only adversarial or security-only review.

### security-review

Adversarial (red-team) review: trust boundaries, authorization, injection, deserialization, SSRF, JWT/token handling, GraphQL-specific risks, abuse paths, and hidden failure modes. Load when asked for hostile review, security audit, risk pass, or when changes touch authn/authz, tenancy, sessions, payments, PII, secrets, crypto, public HTTP or RPC, webhooks, uploads, untrusted deserialization, or new externally reachable surface (endpoints, flags, IPC, file formats). Pair with **`code-review`** for full pre-merge or comprehensive review unless the user scopes to security-only.

### explainer

Explanations of concepts, systems, and code paths—depth matched to the audience, concrete examples, honest uncertainty. For "how does X work?", teaching, onboarding, and architecture walkthroughs. Not a substitute for implementation unless explanation alone was requested.

### refactor

Improve internal structure and readability **without** changing observable behavior. For refactor, simplify, deduplicate, or reorganize—not for new features or bug fixes unless explicitly combined. Verify with existing tests or stated behavior.

### rust-core

Default Rust workflow: idiomatic ownership, `Result`/`Option`, `?`, fmt/clippy/test, minimal safe `unsafe`, library vs app error patterns. For any Rust work (`.rs`, `Cargo.toml`, toolchain). Load **`rust-guidelines`** alongside this for detailed review, public API design, or strict compliance.

### rust-guidelines

Microsoft's Pragmatic Rust AI Guidelines applied to Rust code reviews and implementation. Load alongside `rust-core` for detailed reviews, public API design, or when strict guideline compliance is required. The guidelines are maintained locally in `guidelines.txt`, synced from Microsoft's repository via `update-guidelines.sh`. See that skill's `SKILL.md` for the task-to-section mapping and sync procedure.
