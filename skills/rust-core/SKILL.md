---
name: rust-core
description: >-
  Default Rust workflow: idiomatic ownership, Result/Option, fmt/clippy/test,
  minimal safe unsafe, library-vs-app errors. For any Rust work (.rs, Cargo.toml,
  toolchain). Load `rust-guidelines` for detailed review, public API design,
  or strict compliance.
---

# Rust Standards

## When this applies
- Any Rust work: source files, manifests, workspace layout, tooling, and Rust-specific reviews.

## Precedence
- `rust-guidelines` overrides this skill when strict compliance or detailed review is requested.
- `core-engineer` is the general baseline; this skill adds Rust-specific expectations on top.
- Repository-level rules and user instructions override this skill.
- Project conventions (rustfmt.toml, clippy.toml, CI) override generic advice.

## Workflow

### For implementation

**1. Understand context**
- Read `lib.rs` or `main.rs` to understand the crate's public API surface.
- Read the module you're changing and its neighbors.
- Check `Cargo.toml` for features, workspace members, dependencies, edition, and MSRV.
- For large changes: map call sites and dependencies before editing.

**2. Edit**
- Align with this skill. When applicable, consult relevant sections of `rust-guidelines/guidelines.txt`.
- When the borrow checker objects—first ask whether the objection is valid. Usually it is and your design is unsound. If you're sure your design is correct, restructure with less aliasing rather than cloning. Never use `unsafe` to silence the borrow checker.

**3. Verify**
- Run `cargo fmt`, `cargo clippy` (use project/CI flags if present), `cargo test`.
- If you cannot run them, say so and explain what you relied on instead.

**4. Conflicts**
- If tools or guidelines disagree with established project style, follow the project and note the tension briefly.

### For reviews

**1. Orient**
- Read the PR description and relevant issue context. Identify scope: what crate(s), module(s), file(s) changed?
- For detailed Rust review, load `rust-guidelines` alongside this skill.

**2. Read the diff**
- Check ownership (no unnecessary clones), Result/Option usage, unsafe boundaries, error handling, and docs.
- Use the Rust review checklist below for structured coverage.
- When the borrow checker is mentioned: use the same guidance as implementation.

**3. Write findings**
- Distinguish blocker/major/minor/nit (same scale as `code-review`).
- For Rust-specific violations, reference the relevant rule in this skill or `guidelines.txt`.
- Produce one combined review with `code-review` / `security-review` when loaded.

### Rust review checklist

- **Ownership**: no unnecessary clones; borrowing vs ownership chosen appropriately. For ownership review, check: is `clone()` used only where ownership is genuinely transferred or shared? Are `Arc` / `Rc` used only when shared ownership is necessary? Are `Copy` / `Clone` derived only for types where it makes semantic sense (not just to silence the borrow checker)?
- **Error handling**: Result/Option used correctly; no silent unwrap() on fallible paths in library or production code
- **`unsafe`**: minimal; soundness-commented; encapsulated behind safe API
- **Docs**: public items documented with `///`; complex behavior expanded
- **Tests**: new behavior covered; existing tests pass
- **MSRV**: no new MSRV introduced without noting; dependencies MSRV-compatible
- **Formatting and warnings**: `cargo fmt` clean; `cargo clippy` clean (or suppressed with documented reason)

## Rules
- Prefer idiomatic ownership, borrowing, and lifetimes. Avoid fighting the borrow checker with unnecessary clones unless justified.
- Use `Result` / `Option` appropriately. Prefer `?` and structured errors over `panic!` / `unwrap` / `expect` on fallible paths in library code or production paths in applications.
- For library errors exposed to callers, prefer structured types (`thiserror` or hand-rolled) with stable semantics.
- Respect `rustfmt` and `clippy`. Document `#[allow(...)]` with a short reason next to the suppression.
- Avoid `unsafe`; when required, keep it minimal, soundness-commented, and encapsulated behind a safe API.
- Match `edition` and MSRV declared in `Cargo.toml` / workspace metadata. Do not assume a newer language or std API than the crate allows.

## unwrap / panic

**Avoid** `unwrap` / `expect` in library code on fallible paths exposed to callers.

**Acceptable uses:**
- Tests and example code
- Values that are statically known to be valid (e.g., `u32::MAX.to_string()`)
- Internal invariants that should never be violated (prefer `unwrap_err()` or explicit panic with context)

**Prefer over unwrap:**
- `unwrap_or` / `unwrap_or_else` / `unwrap_or_default` when a fallback makes sense
- `?` when the error should propagate
- `expect()` with a descriptive message (better than unwrap for debugging)

## panic vs Result

| Situation | Prefer |
|-----------|--------|
| Programmer error (contract violation) | `panic!` or `unwrap` |
| Invalid input from caller | `Result` |
| Invalid config at startup | `Result` or `panic!` with context |
| Internal invariant that should never break | `panic!` with message |
| Unrecoverable state | `panic!` |

Rule of thumb: panic when the code has reached a state that **should not exist**; return `Result` when the caller might need to handle the failure.

## Error crate selection

| Situation | Prefer |
|-----------|--------|
| Library with a few error types | `thiserror` (derive macro, zero-cost) |
| Application with many error sources | `anyhow` or `eyre` |
| Both library and app in one crate | `anyhow` / `eyre` for app layer, `thiserror` for library layer |

Do not mix multiple error strategies in one binary.

## Trait bounds and generics

| Pattern | When to use |
|---------|------------|
| `impl Trait` in return position (RPIT) | Concrete return type hidden; limited to inherent impls |
| `impl Trait` as argument | Generic bound inline; callers may need turbofish |
| `dyn Trait` / `Box<dyn Trait>` | Type erasure; dynamic dispatch; storage in collections |
| `T: Clone` bound | When you need to clone within the function |
| `T: Default` bound | When you need a default value |

Avoid over-general bounds. Add bounds as you need them, not speculatively. For public API generics, prefer explicit bounds (`fn foo<T: Trait>()`) over `impl Trait` unless the function signature is simple and the bound is obvious to callers.

## Lifetimes and variance

- Omit lifetimes where elision rules apply (Rust infers them). Add explicit lifetimes when the elision rules don't resolve to the intended lifetime—usually when a function has multiple input lifetimes and the output lifetime relationship isn't clear.
- Prefer lifetime elision or a single explicit lifetime over multiple explicit lifetimes when possible.
- `'static` means the value must live for the entire program—don't use it as a convenience bound unless the data genuinely must live forever. `T: 'static` (the bound, not the lifetime) means `T` contains no non-`'static` references.
- Variance: `&T` and `&mut T` are covariant in `T` (read-only references accept more specific types). `Cell<T>` is invariant in `T`. If you're unsure about variance, prefer being more restrictive—incorrect variance can cause unsoundness.

## Proc macros and derive

## Proc macros and derive

Use `#[derive(Trait)]` for standard derives (Clone, Debug, Default, Serialize, etc.). Keep custom derive and proc macro usage conservative in public APIs—they add cognitive load for callers. Document non-obvious macro behavior.

## Const and inline

| Pattern | When to use |
|---------|------------|
| `const fn` | Computations usable at compile time; simple, pure, no heap allocation |
| `const` items | Static data, magic numbers replaced with named constants |
| `#[inline]` | Small, hot-path functions called frequently across module boundaries (compiler heuristics are usually better—don't force it) |
| `#[inline(always)]` | Rare; test that it actually helps before committing |

Avoid `const` for values that depend on `env!` or `std::mem::size_of` unless the crate's MSRV is stable enough. For complex compile-time logic, prefer const generics or associated constants over macros.

## Cargo features

Use features for optional dependencies and capability gates (e.g., `default`, `json`, `tls`). Do not use `cfg(feature = "...")` as a substitute for proper abstraction—if a feature changes behavior significantly, consider splitting crates instead. Feature sets should be additive: enabling a feature should not break baseline functionality.

## Async Rust

Use `.await` on futures (forgetting it is a common bug). Avoid blocking calls in async contexts—use `tokio::task::spawn_blocking`. Be mindful of `Send` bounds on futures when crossing thread boundaries. Prefer `#[tokio::test]` for async tests.

**Practical patterns:**
- `tokio::select!` for racing multiple futures (handle one completion and cancel the rest). Watch for unbounded recursion or held locks inside `select!` branches.
- `tokio::join!` for waiting on multiple independent futures concurrently. Use `try_join!` when you need early-abort on failure.
- `Arc<Mutex<T>>` for shared mutable state accessed from multiple async tasks; `RwLock` when reads dominate writes.
- Avoid holding a lock across an `.await` point—other tasks waiting for the lock will be blocked indefinitely.
- Check that spawned tasks are awaited or explicitly detached (`tokio::spawn` without `.await`). Detached tasks that panic lose the error silently.

## Shared ownership and interior mutability

Prefer borrowing over shared ownership. When you need shared ownership:

| Type | Use when |
|------|----------|
| `Arc<T>` | Shared ownership across threads |
| `Rc<T>` | Shared ownership within a single thread |
| `Arc<Mutex<T>>` / `Arc<RwLock<T>>` | Shared ownership with mutation across threads |
| `Cell<T>` | Mutating a `Copy` type inside `&T` |
| `RefCell<T>` | Mutating a non-`Copy` type inside `&T` (runtime-checked) |
| `Pin<P>` | Self-referential types, `Future`s, types that must not move in memory; needed when you implement `Future` manually or store pointers into the struct's own fields |

Prefer the most restrictive type that fits. Cloning frequently in hot paths is a design smell—restructure with references or indices.

## Unsafe code

When `unsafe` is required:
- Keep the unsafe surface as small as possible—one unsafe function wrapping safe internals is better than a large unsafe block.
- Add a soundness comment above the unsafe block explaining: what invariant is maintained, what the caller must uphold, and why this cannot be done in safe Rust.
- Encapsulate unsafe behind a safe API so callers don't need to reason about it.
- Never use `unsafe` to silence the borrow checker—restructure the design instead.

## Logging and tracing

Use `tracing` for structured observability in async and library code:
- Enter spans at function start with relevant fields (user ID, request ID, operation).
- Instrument at boundaries: incoming requests, database calls, external HTTP calls.
- Log errors at the point they occur, not at every propagation layer.
- Avoid `println!` in library code; use `tracing` or a logging facade.

## Workspace layout conventions

| Directory | Purpose |
|-----------|---------|
| `src/lib.rs` | Library root; public API surface |
| `src/main.rs` | Binary entry point |
| `src/bin/` | Additional binaries |
| `examples/` | Runnable examples of the library API |
| `tests/` | Integration tests (one file per feature) |
| `benches/` | Benchmark code |

Keep the library surface in `lib.rs`; binaries do minimal logic (argument parsing and delegation to the library).

## MSRV and toolchain

Check MSRV before adding dependencies or using std library features. If a dependency raises the MSRV, note the conflict. Options: accept and bump MSRV (if reasonable); find a lighter alternative; fork the dependency (if critical); pin an older version (temporary).

Respect `rust-toolchain.toml` if present. Check `rustc --version` if toolchain assumptions matter. Most Rust projects run `cargo fmt`, `cargo clippy`, and `cargo test` across MSRV targets. Run `cargo audit` if available to catch known CVEs.

## When stuck

1. **Borrow checker**: first ask if your design is sound—usually it's right. If restructured design feels right, try restructuring with references or indices before cloning.
2. **Async confusion**: if a future isn't making progress, check for missing `.await`, blocking calls in async context, or `Send` bound issues.
3. **Error propagation**: if `?` chains are confusing, wrap errors early with `anyhow` / `eyre` or `thiserror`.
4. **Compile times**: check for `#[inline]` abuse, missing `#[cfg(test)]` splits, `use *` glob imports.
5. **Still stuck**: state what you've tried, what you think is happening, and ask for direction.

## Before finishing
- Edits formatted and warning-clean per project norms (or gaps noted)
- For `unsafe`, new public API, or error taxonomy changes: confirmed against this skill and relevant guideline sections
- Anything not verified (tests not run, runtime behavior unknown) called out
