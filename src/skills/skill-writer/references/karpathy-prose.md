# Karpathy-style prose

This is a project writing convention inspired by Andrej Karpathy's concise engineering explanations and minimal codebases.

Optimize for **clear, decision-useful information per token**, not the fewest tokens. Removing words is useful only when meaning survives.

## Rules

1. **Lead with the point.** State the decision, action, or constraint before its background.
2. **Keep conditions attached.** Say when a rule applies, what it requires, and what happens when it fails. Do not compress away exceptions or permissions.
3. **Use plain, stable terms.** One concept gets one name. Explain unfamiliar terms when they affect action.
4. **Give reasons selectively.** Explain a rule when the reason changes how the reader applies it. Otherwise state the rule and move on.
5. **Prefer a useful default over a slogan.** Allow alternatives when the result permits them; require a method when reliability demands it.
6. **Separate fact, inference, and uncertainty.** State what was observed, what was inferred, and what would verify the rest. Never invent measurements or tests.
7. **Use examples only to resolve ambiguity.** One concrete example is enough when it covers the decision; not every abstract rule needs one.
8. **Cut ceremony and repetition.** Remove decorative labels, motivational language, filler, duplicate instructions, and examples that add no new distinction. Keep a focused separate file when it improves ownership, reuse, maintenance, or independent review; file count is not a proxy for quality.

Short fragments are fine in tables and checklists when the meaning is complete. Use a full sentence when a fragment would hide a condition, actor, or exception. Clarity outranks brevity.

## Examples

| Too compressed or misleading | Better |
|---|---|
| “Handles errors.” | “Skip lines that fail to parse and log them; stop after ten failures.” |
| “Many methods work.” | “Allow any method that meets the constraints; set one default when consistency matters.” |
| “No live test → FAIL.” | “Without a live test, report UNVERIFIED. FAIL only for a test that ran and failed.” |
| “No hedging.” | “State the uncertainty and the evidence that would resolve it.” |

## Revision check

Read the text once as an agent that has not seen the design discussion.

- Can it identify the action and its trigger without guessing?
- Do all hard constraints, exceptions, permissions, and failure conditions survive the edit?
- Does each sentence change a decision, provide needed evidence, or remove ambiguity?
- Would removing a word, example, heading, or file preserve behavior **and** clarity, locality, maintenance, reviewability, and reuse? Remove it only if those qualities survive.
- Are untested claims described as untested, not as verified outcomes?

Stop editing when further compression would make the instructions harder to apply or easier to misread.
