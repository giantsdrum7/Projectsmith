---
description: Run the verification gate — verify-fast (lint + typecheck) then optionally full verify (+ tests)
allowed-tools: Bash, Read
---

Run the staged verification pattern.

## Instructions

1. First run the fast verification:
   `pwsh scripts/verify-fast.ps1`

2. If $ARGUMENTS contains `--fast-only`, stop here and report results.

3. Otherwise (no arguments = full verification), also run:
   `pwsh scripts/verify.ps1`

4. Report results as:
   - VERIFY: PASS (all checks green)
   - VERIFY: FAIL (with details from .cursor/last-verify-failure.txt)

5. If there are failures, suggest fixes based on the error messages.
