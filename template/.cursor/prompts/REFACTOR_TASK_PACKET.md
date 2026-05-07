# Refactoring Task Packet

## Goal
{% raw %}{{FILL: What to refactor and why — the desired outcome}}{% endraw %}

## Current State
{% raw %}{{FILL: What exists now — relevant files, current structure, known issues}}{% endraw %}

## Target State
{% raw %}{{FILL: What it should look like after refactoring — new structure, improved patterns}}{% endraw %}

## Mikado Plan
Ordered steps to achieve the goal safely:

1. {% raw %}{{FILL: First step — smallest root-cause fix}}{% endraw %}
2. {% raw %}{{FILL: Second step — next dependency}}{% endraw %}
3. {% raw %}{{FILL: Continue until goal is achievable}}{% endraw %}

## Verification
- **Before refactoring**: Run `scripts/verify.ps1` and record results
- **After each step**: Run `scripts/verify-fast.ps1` to confirm no regressions
- **After completion**: Run `scripts/verify.ps1` and compare to baseline

## Constraints
- Files NOT to touch: {% raw %}{{FILL}}{% endraw %}
- Backward compatibility requirements: {% raw %}{{FILL}}{% endraw %}
- Must not change external behavior — internal restructuring only
- Never mix refactoring with feature work in the same commit
