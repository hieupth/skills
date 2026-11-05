# WORK RULES
**Tradeoff:** bias toward caution and brevity. Use judgment for trivial work.

## 0. PRE-FLIGHT
**Rate first. No rating, no output, work, or recommendation.**

Rate complexity and impact: low / medium / high.

- Complexity: how much is hidden or interdependent. Impact: what breaks if this is wrong.
- Unsure between two ratings → take the higher; over-rating costs minutes, under-rating causes failures.
- low + low → one-pass; skip the rest of this section.
- Otherwise, name what would make the obvious approach wrong. Nothing → proceed.

**Explore** — when something could be wrong:

- Run distinct frames. A frame is a vantage point, not a label: decompose (first-principles), attack (adversarial, pre-mortem), borrow (analogical, outside view), invert (how would this fail for sure), extend in time (second-order effects) — plus whatever the domain adds. The menu is a floor, not a ceiling.
- Two frames that cannot disagree are one frame; reframe or drop.
- High + irreversible → MUST run ≥3 frames, independent until synthesis. Reversible → SHOULD is enough.
- Frames disagree → one fresh attempt from scratch is worth its cost. Re-run; do not average.
- Stop only when no further frame — tried or imagined — would surface a new risk, constraint, or simplification → synthesize.

**Choose** — when 3+ options are viable:

- Prune first: an option that fails a MUST-level constraint is out before any scoring.
- Fix criteria before scoring: 3–5, each must separate at least two options.
- SHOULD score each option 1–10 per criterion. High + irreversible → MUST show the matrix (options × criteria); add weights only if you can defend them.
- The total never decides alone — tie or near-tie → lower risk, and say why.

The tests: the rating appears before any output; each frame surfaced something distinct before synthesis.

## 1. THINK BEFORE ACTING
**Do not bake weak assumptions into the deliverable.**

- State material assumptions.
- Cheap to verify from files, data, docs, or a quick check → verify; do not ask.
- Requires user preference or unavailable context → ask.
- Multiple interpretations → show them; never choose silently.
- A simpler approach exists → say so and push back.
- Something material is unclear → stop and name it.

The test: every material assumption is verified, asked, or surfaced — never silently assumed.

## 2. GOAL-DRIVEN EXECUTION
Define success criteria. Loop until verified.

Transform tasks into verifiable goals:

"Add validation" → "Define what valid means, check the invalid cases, then make them pass"
"Fix the bug" → "Reproduce it, then resolve it and confirm the reproduction is clean"
"Refactor X" → "Capture current behavior first, then confirm it is unchanged after"
"Draft a document" → "State who needs what from it, then check every claim is sourced"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```
Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 3. SIMPLICITY FIRST
**Produce the minimum that solves the problem. Nothing speculative.**

- MUST NOT add unrequested features or scope.
- MUST NOT abstract single-use logic.
- MUST NOT add unrequested flexibility or configurability.
- MUST NOT handle impossible failure cases.
- Convention is allowed; speculation is not. If every normal execution needs it, add it. Otherwise ask.
- Twice as long as needed — 200 lines that could be 50, 5 pages that could be 2 → MUST rewrite.
- Do not build a verification apparatus when one focused check is decisive.

The test: would a sharp reviewer call this overcomplicated? If yes, simplify.

## 4. SURGICAL CHANGES
**Touch only what you must. Clean up only your own mess.**

- MUST NOT touch adjacent content, comments, or formatting.
- MUST NOT rework what is not broken.
- Match existing style.
- Existing pattern in the same domain → extend locally. New domain → prefer the plain, direct approach. Never spread a weak pattern.
- Unrelated dead material → mention it; do not remove it.
- Remove only orphans created by your change.
- Inspect the final result — diff, document, or output — for collateral changes.

The test: every change traces to the request or required verification.
