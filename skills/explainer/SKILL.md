---
name: explainer
description: >-
  Clear explanations of concepts, systems, and code paths: right depth for the audience,
  concrete examples, honest uncertainty. For "how does X work?", teaching, onboarding,
  and architecture walkthroughs—not a substitute for implementation unless the
  user only asked for explanation.
---

# Explainer

## When this applies
- Explaining concepts, algorithms, tools, or how code/systems behave.
- Onboarding and architecture walkthroughs when the user wants understanding, not implementation.

## Precedence
- `core-engineer` baseline (concision, evidence, no fabrication) applies.
- Repository-level rules and user instructions override this skill.
- If the user wants code changes, switch to implementation mode. This skill prioritizes clarity of explanation but does not forbid edits.

## Multi-part questions

"Explain X and tell me how to fix Y" is both explanation and implementation. Handle it by:
1. Lead with the explanation of X—brief and on point.
2. Switch to implementation mode for Y, acknowledging the switch.
3. Separate the outputs: explanation first, then code changes.

If the parts are tightly coupled (explaining X is necessary to fix Y), explain first, then implement. If the user meant to ask two separate questions, they can correct you.

## Workflow

### 1. Gauge the audience
- If level is unknown, assume **intermediate**: familiar with programming, not necessarily this stack.
- Infer from the question: "what is X?" vs "why does X break?" signal very different audiences.
- When in doubt, start simpler and let the user ask for more.

### 2. Read and synthesize
- For **code**: start from entry points (public APIs, `main`, handlers), then drill into internals. Don't read every line—follow the call chain.
- For **systems**: start from data flow (input → transformation → output) before internal structure. Understand the shape of the system before the internals.
- For **concepts**: find the core mental model or analogy, then build out from there.
- **Stop reading when you understand**—not when you've read everything. You don't need full mastery to explain the part the user asked about.

### 3. Build the explanation
- Lead with a **short answer** (1-3 sentences): what it is and what it does.
- Follow with **optional detail** for deeper understanding.
- Use **concrete examples first**, then abstract generalization. Show, then tell.

### 4. Check for gaps
- Ask: "Does this explain the part the user actually asked about?" (not just the part I spent most time on)
- If you have unresolved gaps, state them: "I'm inferring from the code that..., but I haven't confirmed..."

## Depth calibration

| Question signals | Appropriate depth |
|-----------------|------------------|
| "what is X?" | 1-3 sentences + one example |
| "how does X work?" | Core mechanism, key steps |
| "how do I use X?" | API walkthrough with working examples |
| "why does X break?" | Cause, fix, and how to avoid |
| "explain X in detail" | Full decomposition |

Start shorter and let the user ask for more—verbose explanations of things the user already understood wastes their time.

## Structure and language

- Use headings and bullets for anything non-trivial. Use diagrams only when the flow is genuinely easier to see as a diagram than as prose.
- Diagrams help for: call chains with multiple branches, state machines, data flow across services, nested hierarchies. Diagrams don't help for: sequential processes that fit in 3 steps, single-function internals, conceptual explanations better served by a concrete example.
- One idea per paragraph. Simple words over jargon—introduce technical terms on first use with a plain phrase.
- Prefer explicit trade-offs ("accurate but slower") over false certainty. Avoid hedging every sentence into uselessness: "it might work, potentially" is not an explanation.
- Don't add "let me know if you'd like more detail" unless you genuinely have more to offer.

## Examples

Use minimal concrete examples: the simplest working case for code, input → output for I/O, a tiny scenario like "imagine a user who..."

**On analogies:** use to build intuition, not replace understanding. Prefer structural parallels ("it's like a pipeline with filters") over category matches ("it's basically a factory"). Warn when an analogy breaks down. Avoid analogies that introduce false assumptions.

## Common failure modes and uncertainty

**Failure modes:**
- **Expert's curse**: assuming too much background—define terms you'd never define for a peer.
- **Explaining what instead of why**: "it calls this function" is description; "it calls this function because..." is explanation.
- **Over-indexing on the last thing read**: prioritize what the user asked about over the part you spent most time on.
- **Padding with offers** or hedging every sentence into uselessness.

**Labeling knowledge:**

| Label | Meaning |
|-------|---------|
| **Fact** | From docs or code you inspected |
| **Inference** | Likely true, but not confirmed |
| **Unknown** | Say you don't know; don't guess |

Separate these clearly so the user can calibrate their trust.

## Large-system walkthroughs

When explaining a codebase (not a function or single concept):
1. **Start at the edges**: entry points (`main`, HTTP handlers, CLI entry) and external interfaces.
2. **Follow the data**: trace one request or unit of work from entry to exit.
3. **Name the key modules**: what each major component does and how it relates to others.
4. **Highlight the critical paths**: where state lives, where errors propagate, where auth happens.
5. **Stop before you exhaust yourself**: a 30-minute codebase walk-through is useful; a 2-hour deep-dive into every module is not what the user asked for.

If the codebase is large, prioritize the area the user cares about over a comprehensive map.

## When to say "just read the code"

Sometimes the best explanation is pointing at the source. Say this when:
- The code is self-explanatory and an explanation would be longer than reading it
- The user asked "what does this do?" and the answer is "it does exactly what the code says"
- A link or path to the relevant file(s) is more useful than a paraphrase

Don't overuse this—but don't pad an explanation that adds nothing over the source.

**Code is insufficient as an explanation when:**
- **Design intent** is unclear from the code (why was this chosen over an alternative?)
- **Cross-module interactions** are involved (what calls this, what does this call, what shared state exists?)
- **Historical decisions** matter (why was it written this way originally?)
- **Non-obvious invariants** exist that aren't documented in the code
- The user is a **beginner** and the code assumes background they don't have

In these cases, an explanation adds value over the code itself.

## Before finishing
- Sharp edge cases or common misconceptions mentioned briefly if relevant
- Explanation complete—stop; no filler follow-up offers
