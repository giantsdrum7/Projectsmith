---
description: >
  USE WHEN identifying refactoring opportunities, analyzing code complexity,
  finding duplication, assessing module structure, or planning safe refactors.
  Activates on: refactor, complexity, duplication, tech debt, module structure, code organization, Mikado.
allowed-tools: [Read, Grep, Glob, Bash]
---

# Refactor Radar Skill

## Purpose
Identify refactoring opportunities by analyzing code complexity, duplication, structural concerns, and module boundaries. Produces actionable recommendations using safe, incremental refactoring principles.

## When to Use
- Before starting a refactoring task to assess scope
- When code feels difficult to modify or understand
- During architecture reviews to identify structural debt
- Periodically to track complexity trends across the codebase

## Workflow
1. Determine scope: specific module, directory, or full codebase scan
2. Analyze complexity indicators:
   - File size (flag files > 300 lines)
   - Function length (flag functions > 50 lines)
   - Nesting depth (flag > 3 levels of indentation)
   - Parameter count (flag functions with > 5 parameters)
3. Detect duplication:
   - Near-identical code blocks across files
   - Repeated patterns that could be extracted to shared utilities
   - Copy-pasted logic with minor variations
4. Assess module structure:
   - Import graph density (modules importing > 10 local modules)
   - Circular or near-circular dependency chains
   - God modules that handle too many responsibilities
   - Thin modules that could be consolidated
5. Evaluate against refactoring conventions:
   - Check `.cursor/rules/refactoring.mdc` for project-specific patterns
   - Verify that refactoring is not mixed with feature work
   - Ensure incremental commit discipline is feasible
6. Produce a prioritized refactoring report

## Safe Refactoring Guidance
- **Mikado method**: Map the dependency graph of the change before starting. Commit leaf changes first, working inward to the root change.
- **Incremental commits**: Each commit should leave the codebase in a passing state. Run `scripts/verify-fast.ps1` after each step.
- **Refactoring-first**: When a feature requires structural changes, do the refactoring in a separate commit (or PR) before the feature work.
- **Scope discipline**: If a refactoring grows beyond the original scope, return to the Planner-Critic cycle for re-approval.

## Output Format
```
=== Refactor Radar ===
Scope:       <directory or "full repo">
Complexity:  <N files flagged, top 3 with metrics>
Duplication: <N instances, top 3 with locations>
Structure:   <coupling/cohesion concerns>
Priority:    <top 3 recommended refactorings with effort estimate>
```

## References
- Refactoring conventions: `.cursor/rules/refactoring.mdc`
- Mikado method docs: `docs/refactoring/README.md`
- Collaboration contract: `AGENTS.md` — Planner-Critic-Executor
