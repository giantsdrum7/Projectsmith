# Review Checklist

Use this checklist for every code review. All items must be checked before approving.

## Security
- [ ] No secrets, tokens, or credentials in code
- [ ] No API keys or passwords in configuration files
- [ ] Sensitive data is not logged (especially in production)
- [ ] All external input is validated and sanitized
- [ ] Authentication and authorization are handled correctly

## Tests
- [ ] Tests added for all new functionality
- [ ] Tests pass locally (`scripts/verify-fast.ps1`)
- [ ] Coverage targets met (80% minimum, 100% for config/contracts)
- [ ] Both happy path and error cases are tested
- [ ] Contract tests pass in all modes (offline, local-live, prod)

## Code Quality
- [ ] All new public functions have docstrings (Google style)
- [ ] Type hints on all function signatures
- [ ] Error handling follows conventions (no bare except, custom exceptions)
- [ ] Naming follows conventions (snake_case, PascalCase, UPPER_SNAKE_CASE)
- [ ] Imports are ordered correctly (stdlib, third-party, local)
- [ ] No wildcard imports

## Documentation
- [ ] Documentation updated if public API changed
- [ ] Module-level docstrings for non-trivial new modules
- [ ] REPO_MAP.md updated if project structure changed
- [ ] ENV_VARS.md updated if new environment variables added

## Commit Hygiene
- [ ] Commit messages follow conventions (type: description)
- [ ] No TODO/FIXME without linked issue
- [ ] No unnecessary file changes or debug code
- [ ] Commits are atomic (one logical change per commit)

## Architecture
- [ ] Changes are in the correct layer (api, service, domain)
- [ ] No unnecessary coupling between modules
- [ ] Refactoring is not mixed with feature work
- [ ] File size stays under 300 lines where practical
