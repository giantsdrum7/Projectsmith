# LLM Routing Debug Report

## Issue
{% raw %}{{FILL: wrong model selected, timeout, rate limit, authentication error, unexpected response, etc.}}{% endraw %}

## Environment
- **Mode**: {% raw %}{{FILL: offline / local-live / prod}}{% endraw %}
- **Model ARN / Inference Profile**: {% raw %}{{FILL}}{% endraw %}
- **Region**: {% raw %}{{FILL}}{% endraw %}
- **Timestamp**: {% raw %}{{FILL}}{% endraw %}

## Expected Behavior
{% raw %}{{FILL: What should have happened — which model, what response format, latency target}}{% endraw %}

## Actual Behavior
{% raw %}{{FILL: What actually happened — wrong model, error, timeout, unexpected output}}{% endraw %}

## Logs / Error Messages
```
{% raw %}{{FILL: Relevant log entries, error messages, request IDs}}{% endraw %}
```

## Investigation
1. {% raw %}{{FILL: Checked env_spec.py mode configuration}}{% endraw %}
2. {% raw %}{{FILL: Verified model ARN / inference profile exists and is accessible}}{% endraw %}
3. {% raw %}{{FILL: Checked IAM permissions}}{% endraw %}
4. {% raw %}{{FILL: Reviewed retry/fallback logic}}{% endraw %}
5. {% raw %}{{FILL: Checked rate limit quotas}}{% endraw %}

## Root Cause
{% raw %}{{FILL: Why the routing failed}}{% endraw %}

## Resolution
{% raw %}{{FILL: What was changed to fix the issue}}{% endraw %}
- [ ] env_spec.py updated
- [ ] Fallback logic corrected
- [ ] IAM permissions fixed
- [ ] Rate limit quotas adjusted
- [ ] Test added to prevent recurrence
