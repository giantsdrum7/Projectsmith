# Contributing to Projectsmith

Projectsmith is a Copier template that generates production-ready AI project scaffolds with full IDE agent support. Contributions that improve the scaffold, fix bugs, or extend capabilities are welcome.

## Project Structure

Projectsmith has two layers of files:

### Root Product Files

Files at the Projectsmith repo root support the **template product itself**:

| Path | Purpose |
|---|---|
| `copier.yaml` | Copier configuration: variables, defaults, exclusion rules |
| `docs/scaffold/PRODUCT_DESIGN.md` | Product design spec, ownership model, CI contract |
| `docs/scaffold/CAPABILITY_MATRIX.md` | IDE parity audit: which capabilities map to which files |
| `scripts/dev/validate-template.ps1` | Local validation script for template contributors |
| `.github/workflows/validate-template.yml` | CI workflow that validates all three presets on push/PR |
| `CONTRIBUTING.md` | This file |
| `README.md` | Repo-level overview |

### Template Files (`template/`)

Everything under `template/` is rendered by Copier into generated projects. The `_subdirectory: template` setting in `copier.yaml` tells Copier to use this directory as the template root.

Generated projects receive resolved copies of these files with Copier variables replaced by user-provided values.

## Copier Variables vs Human Placeholders

Projectsmith uses two distinct placeholder systems:

### Copier Variables — `{{ variable_name }}`

Defined in `copier.yaml`. Copier resolves these at generation time. Examples:

- `{{ project_name }}` — Human-readable project name
- `{{ project_slug }}` — Python package identifier
- `{{ aws_region }}` — AWS region for resources
- `{{ github_org }}` — GitHub organization

After `copier copy`, **no** `{{ variable_name }}` patterns should remain in generated output (except inside `.copier-answers.yml`).

### Human FILL Placeholders — `{{FILL: ...}}`

These are **not** Copier variables. They use `{% raw %}...{% endraw %}` blocks to survive Copier rendering and appear literally in generated output. They mark places where a human must fill in project-specific content that cannot be automated.

Example in template source:

```
{% raw %}{{FILL: project identity summary}}{% endraw %}
```

Appears in generated output as:

```
{{FILL: project identity summary}}
```

When editing template files, always use `{% raw %}...{% endraw %}` around FILL placeholders to prevent Copier from interpreting them as variables.

## Why `_templates_suffix: ""` Matters

In `copier.yaml`, `_templates_suffix: ""` means **every file** in the template tree is treated as a Jinja2 template. This is different from the Copier default (`_templates_suffix: ".jinja"`) where only `.jinja` files are rendered.

Implications:

- Any `{{ }}` in template files is evaluated as Jinja2 — wrap literal braces with `{% raw %}...{% endraw %}`
- GitHub Actions `${{ }}` expressions in template workflow files must be escaped with `{% raw %}...{% endraw %}`
- The answers file template uses `{{ _copier_conf.answers_file }}` as its filename (without `.jinja` suffix)

## Optional Modules

Optional modules are controlled by boolean flags in `copier.yaml`:

| Flag | Module | Directory |
|---|---|---|
| `include_frontend` | Frontend (React/Vite) | `apps/` |
| `include_infra` | Infrastructure as Code | `infra/` |
| `include_observability` | Observability (OTel) | `observability/` |
| `include_security` | Security controls | `security/` |
| `include_evals` | Evaluation harness | `evals/` |

These are implemented via Copier's `_exclude` list in `copier.yaml`. When a flag is `false`, the corresponding directory is excluded from generation.

Cursor rules like `frontend.mdc` are also conditionally excluded via the same mechanism.

## Running Local Validation

Before submitting changes, validate that the template still generates correct projects:

```powershell
# Validate all three presets
pwsh scripts/dev/validate-template.ps1 -Preset all

# Validate a single preset
pwsh scripts/dev/validate-template.ps1 -Preset minimal

# Keep output for debugging
pwsh scripts/dev/validate-template.ps1 -Preset full-stack -KeepOutput
```

The script generates a project for each preset and checks:

- Required governance files exist
- All Copier variables resolved (no leftover `{{ variable }}` patterns)
- `{{FILL: ...}}` placeholders survived literally
- `.copier-answers.yml` generated correctly
- Conditional modules included/excluded correctly
- `uv venv && uv lock && uv sync --dev` succeeds
- `ruff check` and `ruff format --check` pass
- `mypy` passes
- `pytest` passes
- `LICENSE` matches the chosen license
- `.claude/settings.json` has the correct model

## GitHub Actions Validation Workflow

`.github/workflows/validate-template.yml` runs the same checks in CI on every push/PR to `main`. It uses a matrix strategy with three presets:

| Preset | What it proves |
|---|---|
| **minimal** | Base scaffold is truly agnostic — no providers, no optional modules |
| **ai-core** | Typical AI project works (Bedrock, DynamoDB, evals enabled) |
| **full-stack** | Maximum complexity passes (all modules on) |

## Contributing Improvements from Downstream Projects

If you discover a scaffold issue while working on a project generated from Projectsmith:

1. Log it in your project's `Lessons_Learned/` directory with the appropriate category
2. Determine if it's project-specific or a generic scaffold improvement
3. If generic: submit a PR against `giantsdrum7/Projectsmith`
4. Scope the change to the minimal fix needed
5. Run `pwsh scripts/dev/validate-template.ps1 -Preset all` before submitting
6. Downstream projects pull the improvement via `copier update`

See [PRODUCT_DESIGN.md Section 8](docs/scaffold/PRODUCT_DESIGN.md#8-lesson-promotion-workflow) for the full lesson promotion workflow.

## Key Files Reference

| File | Purpose |
|---|---|
| `copier.yaml` | Variable definitions, defaults, exclusion rules, Copier config |
| `docs/scaffold/PRODUCT_DESIGN.md` | Product design: ownership model, CI contract, acceptance criteria |
| `docs/scaffold/CAPABILITY_MATRIX.md` | IDE parity audit for all capabilities |
| `scripts/dev/validate-template.ps1` | Local validation script |
| `.github/workflows/validate-template.yml` | CI validation workflow |
| `template/{{ _copier_conf.answers_file }}` | Copier answers file template |
