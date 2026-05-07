# Lessons Learned — notable

> Maintainership notes for Projectsmith itself (the Copier template repo).
> Bugs, surprises, and decisions that took >30 min to diagnose, plus things
> that bit us once and shouldn't bit us twice.
>
> Structure mirrors the emitted-scaffold convention at
> `template/Lessons_Learned/notable.md` (see `template/scripts/dev/add-lesson.ps1`
> for the per-entry format).

---

## Entries

### 2026-05-07 — Local validate-template.ps1 presets break at copier copy

**Symptom:** All five presets in `scripts/dev/validate-template.ps1`
(`minimal`, `ai-core`, `postgres`, `full-stack`, `e2e`) fail their
`copier copy` step locally with prompts/errors about missing required
variables. The GitHub workflow (`.github/workflows/validate-template.yml`)
runs cleanly because each matrix entry there *does* pass them.

**Root cause:** The `client_id` and `environment_tier` Copier variables
were added later and have no defaults in `copier.yaml`. The local
PowerShell harness's preset `Data` arrays were never updated to include
them, so `copier copy` either prompts (in TTY mode) or errors out (in
non-interactive mode). The drift was masked because the GitHub workflow,
which is the authoritative gate, is parameterised correctly.

**Fix:** Not in this commit. v1.0.0 ships the rest of the pre-tag cleanup;
this preset-data-array catch-up is out of scope for the tag and slated for
v1.0.1. When fixed, append `--data client_id=<…>` and
`--data environment_tier=<dev|prod>` to every preset's `Data` array in
`scripts/dev/validate-template.ps1`, mirroring the values used by the
matching matrix entry in `.github/workflows/validate-template.yml`.

**Prevention:**

- When adding a new required (no-default) variable to `copier.yaml`, update
  **both** harnesses in the same commit:
  - `.github/workflows/validate-template.yml` matrix entries
  - `scripts/dev/validate-template.ps1` preset `Data` arrays
- The `Long-slug` preset added in v1.0.0 already mirrors `ai-core` exactly,
  so once `ai-core` is fixed, `long-slug` should be updated by the same
  diff.
- Consider adding a contract test that diffs the variable set used by
  `validate-template.ps1` against the variable set declared in
  `copier.yaml` and fails if any required-no-default var is missing from
  any preset.

**Links:** `scripts/dev/validate-template.ps1`,
`.github/workflows/validate-template.yml`, `copier.yaml`,
`CHANGELOG.md` (v1.0.0 → Deferred)
