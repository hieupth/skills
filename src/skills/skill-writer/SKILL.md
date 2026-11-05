---
name: skill-writer
description: >-
  Create, review, and fix Agent Skills (SKILL.md), including
  routing, structure, and tests. Use for skill design, audits,
  trigger bugs, or deciding if a Skill is needed; not for
  unrelated code or docs.
---

# Skill Writer

Design the smallest Skill that reliably routes, performs its task, and meets its acceptance criteria. Preserve the user's requested deliverable and permissions.

## Source of truth

Read the relevant reference **before** performing the indicated work:

| Reference | Read when | Owns |
|---|---|---|
| [Description routing](references/description-routing.md) | Creating or changing `description`, reviewing routing, or debugging missed/false activation | Intent boundaries, description construction, routing tests |
| [Minimum skill](references/minimum-skill.md) | Creating, restructuring, or auditing a Skill's structure | Structural template, required semantics, file placement |
| [Karpathy prose](references/karpathy-prose.md) | Drafting or revising Skill instructions or references | Concision without loss of meaning |

Do not copy reference rules into this entrypoint or between references. This file owns orchestration and release gates; each reference owns its subject. Link any new reference directly from `SKILL.md` with a read condition.

## Workflow

1. **Understand.** Identify the intended host, user request, target artifact, inputs, constraints, and existing Skill set. If asked *whether* a Skill is useful, compare simpler alternatives and recommend no Skill when none adds value. If explicitly asked to create a Skill, create it; mention a simpler alternative only if useful, without substituting it for the requested artifact. For existing Skills, read their files before judging them.
2. **Design.** Define positive, nearest-negative, and ambiguous routing cases. Set hard requirements and observable completion criteria before implementation. Distinguish freedoms from invariants (correctness, safety, permissions, and output contract). Use the description-routing reference for `description`; use the minimum-skill reference for structure.
3. **Implement.** Keep essential decisions in `SKILL.md`; put coherent, maintainable supporting knowledge in `references/`. State when to read each file. Add `scripts/` for useful deterministic execution; add `assets/` for files copied or transformed into user outputs. Do not add capabilities, tool permissions, or side effects the user did not authorize.
4. **Verify and simplify.** Check structure, routing, execution, and value separately. Diagnose failures before editing: remove, clarify, or add the smallest instruction that fixes the cause. Re-run affected checks after every change. Report PASS, FAIL, or UNVERIFIED and never claim a test ran when it did not.

## Resource design rule

Choose file boundaries by **cohesion and change ownership**, not line count alone. A separate reference is justified when it makes a rule set easier to locate, review, maintain, reuse, test independently, or load conditionally. Context savings is one benefit, not the only criterion. Keep closely coupled instructions together; avoid duplicate rules, trivial fragments without a responsibility, and nested reference chains. A focused short reference is acceptable.

A template describing **how to author** an artifact belongs in `references/`; a source file intended to be **copied into** the artifact belongs in `assets/`. Do not force files into these locations when their actual use differs. Validate paths and read conditions after restructuring.

## Verification and release

| Gate | Evidence | Outcome if not tested |
|---|---|---|
| Conformance | Parse frontmatter, check naming, paths, host-specific metadata and constraints | UNVERIFIED |
| Routing | In the target host, observe implicit invocation for positive, negative, ambiguous and collision cases; explicit invocation is a separate check | UNVERIFIED |
| Execution | Run representative tasks with the Skill; check output and hard invariants | UNVERIFIED |
| Incremental value | Compare against the same task without the Skill for accuracy, consistency, cost, speed or auditability | UNVERIFIED |

A simulated selection question is diagnostic, **not** proof of actual activation. Passing execution does not establish incremental value; missing a baseline does not invalidate a separately verified execution result. Set acceptance criteria before testing. Hard failures block release; a score cannot override one. Ship only when required gates pass; otherwise state exactly what is unverified or blocked.

Use the target host's current specification rather than assuming optional metadata or invocation behavior is portable. The common Agent Skills format requires a `SKILL.md` with `name`, `description`, and instructions; other directories are optional. Keep the main file concise without sacrificing coordination or safety.
