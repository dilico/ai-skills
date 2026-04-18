---
name: commit-helper
description: >-
  Generate commit messages from git diffs following conventional commits.
  Use when asked to create, improve, or validate commit messages.
---

# Commit Helper

## When this applies
- Asked to **generate**, **write**, **suggest**, or **create** a commit message.
- Detected phrases like: "commit message", "write commit", "generate commit", "suggest commit", "create commit".
- Asked to **validate** an existing commit message.

## Precedence
- **`core-engineer`** baseline applies throughout. This skill focuses specifically on commit messages.
- Repository-level commit conventions (if any) override this skill.
- User instructions about commit style take precedence.
- When processing **multiple** change requests, analyze **all** changes in the current session.

## Two Modes

### 1. Generate from Diff

When the user requests a commit message (using phrases like "commit message", "write commit", "generate commit", "suggest commit", "create commit", etc.), you MUST:

1. Analyze all changes made in the current session or git diff or in files that are staged
2. Analyze changes for every new request

**Workflow:**
1. Read the diff to understand what actually changed.
2. Distinguish **core logic** (the meaningful change) from **plumbing** (formatting, boilerplate, generated code).
3. For large diffs, identify the main theme—don't try to summarize everything.
4. Draft a message that accurately describes the meaningful change.

**Guidelines:**
- Write for **human readers**: other developers who need to understand what changed and why.
- Be **specific**: "fix login bug" is useless; "handle expired JWT tokens in session middleware" is useful.
- Reference **issue/ticket numbers** if provided (e.g., "Closes #123").
- If the diff is too large or scattered, note this and summarize the main themes.

### 2. Conventional Commits

Help write commit messages that follow [conventionalcommits.org](https://www.conventionalcommits.org/) spec.

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Required Components

### Type
The type MUST be one of the following:

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc.)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `build`: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
- `ci`: Changes to our CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

### Description
- MUST immediately follow the type/scope and colon + space
- MUST be in lowercase
- MUST be written in imperative mood ("add feature" not "added feature" or "adds feature")
- MUST NOT end with a period
- SHOULD be concise (50-72 characters recommended)

## Optional Components

### Scope
- MAY be provided after the type
- MUST be a noun describing a section of the codebase
- MUST be enclosed in parenthesis
- Examples: `feat(api):`, `fix(payment):`, `docs(readme):`

### Body
- MAY be provided after the description
- MUST be separated from the description by a blank line
- SHOULD include the motivation for the change and contrast it with previous behavior
- MUST be written in imperative mood

### Footer
- MAY be provided after the body
- MUST be separated from the body by a blank line
- MAY contain:
  - `BREAKING CHANGE:` followed by a description of the breaking change
  - Issue references: `Fixes #123`, `Closes #456`

## Breaking Changes

Breaking changes MUST be indicated by:
- Adding `!` after the type/scope: `feat!:` or `feat(api)!:`
- Including `BREAKING CHANGE:` in the footer with a description

## Examples

```
feat: add user authentication
feat(api): add payment processing endpoint
fix(payment): resolve null pointer exception
docs: update README with installation steps
feat(api)!: change authentication method

BREAKING CHANGE: Authentication now requires OAuth2 instead of API keys
```

## Validation

When asked to validate an existing commit message:
1. Check format (conventional if the repo uses it)
2. Check type is valid (from the allowed list)
3. Check description rules (lowercase, imperative, no period)
4. Check length (subject line 50-72 chars recommended)
5. Check scope format if provided (parentheses)
6. Check for template artifacts (e.g., "[ci skip]" that shouldn't be there)
7. Check breaking change indication if applicable

## Output

For generated messages, provide:
- A **recommended message** (the main suggestion)
- If applicable, breaking changes format with `!` and `BREAKING CHANGE:`
- Brief **rationale** for the recommendation

For validation, provide:
- Whether the message is valid
- Specific issues (if any)
- Suggested improvements