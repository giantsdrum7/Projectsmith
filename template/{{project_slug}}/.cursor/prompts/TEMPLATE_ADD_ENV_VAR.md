# Add Environment Variable

## Variable Details
- **Name**: {% raw %}{{FILL: VARIABLE_NAME}}{% endraw %}
- **Description**: {% raw %}{{FILL: What this variable controls}}{% endraw %}
- **Category**: {% raw %}{{FILL: aws, llm, feature_flag, api, database, etc.}}{% endraw %}
- **Sensitive**: {% raw %}{{FILL: yes/no — if yes, must go in Secrets Manager}}{% endraw %}

## Default Values Per Mode
| Mode | Value |
|------|-------|
| offline | {% raw %}{{FILL}}{% endraw %} |
| local-live | {% raw %}{{FILL}}{% endraw %} |
| prod | {% raw %}{{FILL}}{% endraw %} |

## Implementation Steps

### 1. Add to env_spec.py
Add the variable definition to `src/{{ project_slug }}/config/env_spec.py` with:
- Name, description, category
- Default values per mode
- Sensitive flag
- Validation rules (if applicable)

### 2. Regenerate Templates
Run the template generator to update `.env.example` and `mode_defaults.json`:
```
uv run python scripts/env/generate_env_templates.py
```

### 3. Update Documentation
Add the variable to `docs/reference/ENV_VARS.md` with:
- Name, description, default values, sensitivity

### 4. Secrets Manager (if sensitive)
If the variable is sensitive:
- Add to AWS Secrets Manager via the secrets bootstrap script
- Ensure the pointer pattern is used (not direct env var)

### 5. Update CI Workflow (if needed)
If the variable is required in CI:
- Add to GitHub Actions workflow secrets/variables
- Update the CI environment setup

## Verification
- [ ] Variable defined in env_spec.py
- [ ] Templates regenerated
- [ ] docs/reference/ENV_VARS.md updated
- [ ] Contract tests pass: `pytest tests/contract/`
- [ ] All modes work: offline, local-live, prod
