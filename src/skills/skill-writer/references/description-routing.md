# Description Routing Contract

This reference owns the construction and testing of a Skill's frontmatter `description`. A description is a **selection contract**, not an executive summary. The host may see only `name` and `description` before deciding whether to load the body; an omitted trigger cannot be repaired by text hidden inside the body.

## Design procedure

1. **Define the job**: identify the actual capability, the user's observable intended outcome, distinguishing artifacts/context, and neighboring Skills already installed (if known). Topic mentions alone are not invocation intent.
2. **Draw boundaries before prose**: write positive requests, near-negative requests, and ambiguous/compound requests with expected behavior. Include paraphrases and requests that never say the Skill name.
3. **Write the selection contract**: lead with a specific capability (`verb + object + result`), then when to invoke (`Use when` + user intent/context). Add `Not for` only to distinguish plausible false positives. These are optional prose patterns, **not required phrases** or part of the Skill file format. A natural sentence without them is equally valid if it preserves the boundaries.
4. **Preserve semantic coverage**: use natural user wording, file types or artifact names when diagnostic, and genuinely important indirect requests. Avoid keyword stuffing, generic category claims, and exclusions that block valid compound requests.
5. **Front-load discriminators**: put the strongest intent and task signals early, because some hosts shorten descriptions under context limits. Prefer plain, third-person statements and claim only implemented capabilities. Keep execution steps and permissions out of the description.
6. **Prune with evidence**: remove wording only if routing coverage and disambiguation remain intact. Verify actual host limits, which may be stricter than the common Agent Skills limit of 1,024 characters. Do not optimize for an arbitrary character count.

## Example

Weak: `Helps with agent workflows, programming, and documentation.`

Better:

```yaml
description: >-
  Creates, reviews, and fixes Agent Skills (SKILL.md).
  Use when asked to author a Skill, adjust its triggering,
  or evaluate its instructions. Not for ordinary coding
  or documentation unrelated to Agent Skills.
```

An equally valid description without the phrase `Use when`:

```yaml
description: >-
  Reviews Agent Skills (SKILL.md) for trigger coverage and instruction
  quality during Skill design, debugging, or audits.
```

## Diagnose routing failures

| Symptom | Examine | Corrective action |
|---|---|---|
| False negative | Missing task intent, common paraphrase, or discriminating artifact | Add the smallest missing signal if the request truly belongs |
| False positive | Overly broad verb, object, or context | Narrow the boundary; add a nearby exclusion only if it changes selection |
| Collision | Similar Skills with overlapping capabilities | Differentiate by intended result; allow legitimate co-invocation |
| Ambiguous | Expected result was unspecified | Define desired default for that case before rewriting text |

## Test contract

- **Positive**: natural direct and indirect requests the Skill should match.
- **Negative**: nearby requests it must ignore, including mere topic or filename mentions.
- **Ambiguous / collision**: realistic overlaps with predeclared expected outcomes.
- **Explicit**: separately check manual invocation; explicit selection may bypass implicit routing.

Run cases in fresh contexts with the target host and relevant installed Skills. Record actual invocation traces when available, not a model's hypothetical answer about what it *would* choose. Measure false positives and false negatives; repeat after edits. Without observable activation traces, live routing is UNVERIFIED, even if a simulated classifier chooses correctly.
