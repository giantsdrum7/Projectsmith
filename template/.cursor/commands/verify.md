---
description: Run verification gate (lint + typecheck + tests)
---

# Verification

Running staged verification pattern...

## Instructions

1. Always run fast verification first:
   `pwsh scripts/verify-fast.ps1`

2. If fast verification passes, also run full verification:
   `pwsh scripts/verify.ps1`

   Skip full verification only if `$ARGUMENTS` contains `--fast-only`.

3. Report results as:
   - `VERIFY: PASS` — all checks green
   - `VERIFY: FAIL` — with details

4. On failure: read `.cursor/last-verify-failure.txt` and suggest fixes based on the error messages.
