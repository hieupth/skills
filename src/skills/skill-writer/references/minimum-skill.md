# Minimum Skill Structure

This reference owns the structure and file placement of an authored Skill, not the wording of its `description`. The entrypoint links the [description-routing contract](description-routing.md), which exclusively owns how to generate and test that field. The skeleton below is an authoring aid, **not** a verbatim output file: replace placeholders and omit inapplicable headings.

## Minimal skeleton

````markdown
---
name: <skill-name>
description: <generated-description>
---

# <Skill Name>

## Procedure

1. <Task-specific action or decision that improves default behavior>.

## Verification

- <Observable acceptance condition>.
````

The `description` placeholder stands for the complete YAML value generated using the routing contract. Use a plain or quoted scalar, or folded YAML (`>-`), as required by the actual text. The placeholder is **not** a required wording pattern. `Procedure` and `Verification` are optional headings; a one-step body or an inline success condition is valid when it communicates the full behavior.

## Required semantics

| Element | Requirement | Owner / placement |
|---|---|---|
| Selection | Valid `name` and `description`; actual capability and activation boundaries | Frontmatter; wording and routing tests belong to `description-routing.md` |
| Execution | Non-obvious actions, decisions, constraints, inputs/outputs, and important branches | `SKILL.md` body or directly linked, relevant references |
| Verification | Observable correctness and failure handling proportional to task risk | Body, deterministic checks, or versioned external test suite |

Do not emit placeholders, empty sections, generic filler, or invented test results in a released Skill. Preserve user-specified artifacts and permissions. A separate `Verification` section is not mandatory when correctness is self-evident or checked within the procedure.

## Placement and modularity

- `SKILL.md`: required metadata, entrypoint instructions, invariants, and direct read conditions for supporting resources.
- `references/`: instructions, specifications, authoring templates, schemas, reusable decision rules, or mode-specific guidance that the agent **reads**. Separate files by responsibility, reviewability, maintenance, reuse, independent testing, or conditional loading; length alone does not decide.
- `scripts/`: deterministic operations or checks whose execution improves correctness/reproducibility. State prerequisites and failure behavior.
- `assets/`: source files that are **copied or transformed** into the result, rather than primarily read as guidance.
- Tests: versioned fixtures or checks when regression protection matters; they may be distributed separately when traceable to the Skill version.

For each supporting file, give the entrypoint a direct relative link and a meaningful read condition. Prefer one-hop discovery. Avoid duplicated authoritative rules and cyclic dependencies. When restructuring, update callers and verify every path. A small but independently maintained reference is valid.

## Structural acceptance

- `SKILL.md` exists with valid frontmatter and substantive instructions.
- The output contains no unreplaced placeholders or empty template sections.
- Referenced resources exist, are discoverable from the entrypoint, and have no contradictory owners.
- Layout, optional metadata, and file names comply with the target host's specification.
